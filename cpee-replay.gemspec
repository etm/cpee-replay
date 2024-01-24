Gem::Specification.new do |s|
  s.name             = "cpee-replay"
  s.version          = "1.0.0"
  s.platform         = Gem::Platform::RUBY
  s.license          = "LGPL-3.0"
  s.summary          = "Replay .xes.yaml for the cloud process execution engine (cpee.org)"

  s.description      = "see http://cpee.org"

  s.files            = Dir['{server/**/*,tools/**/*,lib/**/*}'] + %w(LICENSE Rakefile cpee-replay.gemspec README.md AUTHORS)
  s.require_path     = 'lib'
  s.extra_rdoc_files = ['README.md']
  s.bindir           = 'tools'
  s.executables      = ['cpee-replay']

  s.required_ruby_version = '>=3.2.0'

  s.authors          = ['Juergen eTM Mangler']

  s.email            = 'juergen.mangler@gmail.com'
  s.homepage         = 'http://cpee.org/'

  s.add_runtime_dependency 'riddl', '~> 0.99'
  s.add_runtime_dependency 'json', '~> 2.1'
  s.add_runtime_dependency 'cpee', '~> 2', '>= 2.0.33'
end
