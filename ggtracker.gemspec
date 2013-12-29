Gem::Specification.new do |s|
  s.name = 'ggtracker'
  s.version = '1.0'
  s.summary = 'Library for accessing GGTracker'
  s.authors = ['Nicholas Robinson-Wall']
  s.email = ['nick@robinson-wall.com']
  s.required_ruby_version = '>= 1.9.2'
  s.files = Dir['{lib,spec}/**/*']
  s.test_files = Dir['spec/**/*']
  s.add_dependency 'json'
  s.add_dependency 'httparty'
  s.add_dependency 'acts_as_elo'
  s.add_dependency 'webmock'
  s.add_dependency 'actionpack'
  s.add_development_dependency 'rspec'
end
