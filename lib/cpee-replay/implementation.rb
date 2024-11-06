# This file is part of cpee-replay.
#
# cpee-replay is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# cpee-replay is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# cpee-replay (file LICENSE in the main directory).  If not, see
# <http://www.gnu.org/licenses/>.

require 'rubygems'
require 'redis'
require 'json'
require 'yaml'
require 'riddl/server'
require 'time'
require 'msgpack'
require 'mimemagic'
require 'base64'
require 'charlock_holmes'

def detect_encoding(text) #{{{
  if text.is_a? String
    if text.valid_encoding? && text.encoding.name == 'UTF-8'
      'UTF-8'
    else
      res = CharlockHolmes::EncodingDetector.detect(text)
      if res.is_a?(Hash) && res[:type] == :text && res[:ruby_encoding] != "binary"
        res[:encoding]
      elsif res.is_a?(Hash) && res[:type] == :binary
        'BINARY'
      else
        'ISO-8859-1'
      end
    end
  else
    'OTHER'
  end
end #}}}
def convert_to_base64(text) #{{{
  ('data:' + MimeMagic.by_magic(text).type + ';base64,' + Base64::encode64(text)) rescue ('data:application/octet-stream;base64,' + Base64::encode64(text))
end #}}}
def structurize_result(result,name='value') #{{{
  result.map do |r|
    if r.is_a? Riddl::Parameter::Simple
      ttt = r.value
      ttt = ttt.to_f if ttt == ttt.to_f.to_s
      ttt = ttt.to_i if ttt == ttt.to_i.to_s
      { 'name' => r.name, name => ttt }
    elsif r.is_a? Riddl::Parameter::Complex
      res = if r.mimetype == 'application/json'
        ttt = r.value.read
        enc = detect_encoding(ttt)
        enc == 'OTHER' ? ttt.inspect : (ttt.encode('UTF-8',enc) rescue convert_to_base64(ttt))
      elsif r.mimetype == 'text/csv'
        ttt = r.value.read
        enc = detect_encoding(ttt)
        enc == 'OTHER' ? ttt.inspect : (ttt.encode('UTF-8',enc) rescue convert_to_base64(ttt))
      elsif r.mimetype == 'text/plain' || r.mimetype == 'text/html'
        ttt = r.value.read
        ttt = ttt.to_f if ttt == ttt.to_f.to_s
        ttt = ttt.to_i if ttt == ttt.to_i.to_s
        enc = detect_encoding(ttt)
        enc == 'OTHER' ? ttt.inspect : (ttt.encode('UTF-8',enc) rescue convert_to_base64(ttt))
      else
        convert_to_base64(r.value.read)
      end

      tmp = {
        'name' => r.name == '' ? 'result' : r.name,
        'mimetype' => r.mimetype,
        name => res.to_s
      }
      r.value.rewind
      tmp
    end
  end
end #}}}

def get_record(name,where)
  if name.is_a? String
    ffile = File.open(name)
  else
    ffile = name
  end
  ffile.seek(where['s'],IO::SEEK_SET)
  item = YAML::load(ffile.read(where['l']))
  ffile.close if name.is_a? String
  item
end

def send_back(fname, event, callback, start)
  ffile = File.open(fname)
  event.each_with_index do |sendbacks, index|
    item = get_record(ffile,sendbacks[1])
    ts = Time.parse(item.dig('event', 'time:timestamp'))
    dur = ts - start
    Thread.new(item,dur,callback,event,index) do |item, duration, callback, event, index|
      sleep dur
      client = Riddl::Client.new(callback)
      res = item.dig('event','raw')&.map do |i|
        if i['mimetype']
          Riddl::Parameter::Complex.new(i['name'],i['mimetype'],i['data'])
        else
          Riddl::Parameter::Simple.new(i['name'],i['data'])
        end
      end
      unless event.length == index + 1
        res << Riddl::Header.new('CPEE-UPDATE', 'true')
      end
      client.put res
    end
  end
  ffile.close
end

def compare(a,b)
  yes = false
  a.each do |e|
    yes = true if b.find{ |f| f['name'] == e['name'] && e['value'].to_s == f['value'].to_s }
  end
  (a.length == b.length && yes) || (a.empty? && b.empty?)
end

module CPEE
  module Replay

    SERVER = File.expand_path(File.join(__dir__,'implementation.xml'))

    class DoIt < Riddl::Implementation
      def response
        if @h['CPEE_ATTR_SIM_TARGET']
          dd = @a[0]
          indexes = @a[1]
          me = @h['CPEE_INSTANCE_UUID']

          fdigest = Digest::SHA256.hexdigest(@h['CPEE_ATTR_SIM_TARGET'])
          idigest = Digest::SHA256.hexdigest(@h['CPEE_ATTR_SIM_TARGET'] + '.index')
          unless File.exist?(File.join(dd,fdigest)) #{{{
            ffile = File.open(File.join(dd,fdigest),'w+')
            request = Typhoeus::Request.new(@h['CPEE_ATTR_SIM_TARGET'])
            request.on_headers do |response|
              if response.code != 200
                raise "Request failed"
              end
            end
            request.on_body do |chunk|
              ffile.write(chunk)
            end
            request.on_complete do |response|
              ffile.rewind
            end
            request.run
          end #}}}
          unless File.exist?(File.join(dd,idigest)) #{{{
            ifile = File.open(File.join(dd,idigest),'w+')
            request = Typhoeus::Request.new(@h['CPEE_ATTR_SIM_TARGET'] + '.index')
            request.on_headers do |response|
              if response.code != 200
                raise "Request failed"
              end
            end
            request.on_body do |chunk|
              ifile.write(chunk)
            end
            request.on_complete do |response|
              ifile.close
            end
            request.run
          end #}}}
          unless indexes[me]
            io = File.open(File.open(File.join(dd,idigest)))
            indexes[me] = MessagePack.unpack(io)
            io.close
          end

          oep = @p.shift.value
          params = structurize_result @p
          indexes[me].each_with_index do |x,i|
            k,e = x
            if k == oep
              indexes[me].delete(x)
              if call = e.find{|loc| loc[0] == 'c' }
                item = get_record(File.join(dd,fdigest),call[1])
                if compare(item.dig('event', 'data') || [],params)
                  callback = @h['CPEE_CALLBACK']
                  start = Time.parse(item.dig('event', 'time:timestamp'))
                  e.delete(call)
                end
              end
              if instantiate = e.find{|loc| loc[0] == 'i' }
                item = get_record(File.join(dd,fdigest),instantiate[1])
                dname = File.dirname(@h['CPEE_ATTR_SIM_TARGET'])
                sub_id = item.dig('event','raw','CPEE-INSTANCE-UUID')

                @headers << Riddl::Header.new('CPEE-SIM-MODEL', File.join(dname,sub_id) + '.xes.yaml.model')
                @headers << Riddl::Header.new('CPEE-SIM-TARGET', File.join(dname,sub_id) + '.xes.yaml')
                @headers << Riddl::Header.new('CPEE-SIM-TASKTYPE', instantiate[0])
                @headers << Riddl::Header.new('CPEE-SIM-ENGINE', @h['CPEE_ATTR_SIM_ENGINE'])
                @headers << Riddl::Header.new('CPEE-SIM-TRANSLATE', @h['CPEE_ATTR_SIM_TRANSLATE'])
                @status = 561
                return
              else
                send_back File.join(dd,fdigest), e, callback, start
                @headers << Riddl::Header.new('CPEE-CALLBACK', 'true')
                return
              end
            end
          end
        end
        nil
      end
    end

    def self::implementation(opts)
      opts[:indexes] ||= {}
      opts[:data_dir] ||= File.expand_path(File.join(__dir__,'data'))

      Proc.new do
        on resource do
          run DoIt, opts[:data_dir], opts[:indexes] if post
          run DoIt, opts[:data_dir], opts[:indexes] if get
          run DoIt, opts[:data_dir], opts[:indexes] if delete
          run DoIt, opts[:data_dir], opts[:indexes] if put
          run DoIt, opts[:data_dir], opts[:indexes] if patch
        end
      end
    end

  end
end
