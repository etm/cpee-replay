Gem::Specification.new do |s|
  s.name             = "cpee-replayer"
  s.version          = "1.0.0"
  s.platform         = Gem::Platform::RUBY
  s.license          = "LGPL-3.0"
  s.summary          = "Replaying for the cloud process execution engine (cpee.org)"

  s.description      = "see http://cpee.org"

  s.files            = Dir['{server/**/*,tools/**/*,lib/**/*}'] + %w(LICENSE Rakefile cpee-replayer.gemspec README.md AUTHORS)
  s.require_path     = 'lib'
  s.extra_rdoc_files = ['README.md']
  s.bindir           = 'tools'
  s.executables      = ['cpee-replayer']

  s.required_ruby_version = '>=2.7.0'

  s.authors          = ['Juergen eTM Mangler']

  s.email            = 'juergen.mangler@gmail.com'
  s.homepage         = 'http://cpee.org/'

  s.add_runtime_dependency 'riddl', '~> 0.99'
  s.add_runtime_dependency 'json', '~> 2.1'
  s.add_runtime_dependency 'cpee', '~> 2', '>= 2.0.33'
end
