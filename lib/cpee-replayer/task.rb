# This file is part of CPEE-REPLAYER.
#
# CPEE-REPLAYER is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# CPEE-REPLAYER is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# CPEE-REPLAYER (file LICENSE in the main directory).  If not, see
# <http://www.gnu.org/licenses/>.

require 'rubygems'
require 'redis'
require 'json'
require 'yaml'
require 'riddl/server'
require 'time'

module CPEE
  module Replayer

    SERVER = File.expand_path(File.join(__dir__,'task.xml'))

    class DoIt < Riddl::Implementation
      def response
        p @p
        nil
      end
    end

    def self::implementation(opts)
      Proc.new do
        on resource do
          run DoIt if post
        end
      end
    end

  end
end
