Gem::Specification.new do |s|
  s.name        = 'comrad'
  s.version     = '0.1.4'
  s.date        = Date.today.to_s
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = ['README.md', 'LICENSE']
  s.summary     = 'Your rad comrade - Sync changes from git to Chef Server via Jenkins'
  s.description = s.summary
  s.authors     = ['Tim Smith']
  s.email       = 'tim@cozy.co'
  s.homepage    = 'http://www.github.com/tas50/Comrad'
  s.license     = 'Apache-2.0'

  s.required_ruby_version = '>= 1.9.3'
  s.add_dependency 'rest-client', '~> 1.7.0'
  s.add_dependency 'chef', '>= 11.0'
  s.add_dependency 'slack-post', '~> 0.3', '>= 0.3.1'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rubocop', '~> 0.32.0'

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.name
  s.require_paths = ['lib']
  s.extra_rdoc_files = ['README.md']
  s.rdoc_options = ['--line-numbers', '--inline-source', '--title', 'comrad', '--main', 'README.md']
end
