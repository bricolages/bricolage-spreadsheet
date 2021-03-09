Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'bricolage-spreadsheet'
  s.version = '1.0.0'
  s.summary = 'Google Spreadsheet-related job classes for Bricolage batch framework'
  s.license = 'MIT'

  s.author = ['Shimpei Kodama']
  s.email = 'shimpeko@gmail.com'
  s.homepage = 'https://github.com/bricolages/bricolage-spreadsheet'

  s.files = Dir.glob(['README.md', 'RELEASE.md', 'lib/**/*.rb', 'jobclass/*.rb', 'test/**/*'])
  s.require_path = 'lib'

  s.required_ruby_version = '>= 2.2.0'
  s.add_dependency 'bricolage', '>= 5.26.0'
  s.add_dependency 'google-api-client', '>= 0.53.0'
end
