Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'bricolage-spreadsheet'
  s.version = '1.0.1'
  s.summary = 'Google Spreadsheet-related job classes for Bricolage batch framework'
  s.license = 'MIT'

  s.author = ['Shimpei Kodama']
  s.email = 'shimpeko@gmail.com'
  s.homepage = 'https://github.com/bricolages/bricolage-spreadsheet'

  s.files = Dir.glob(['README.md', 'lib/**/*.rb', 'jobclass/*.rb'])
  s.require_path = 'lib'

  s.required_ruby_version = '~> 2.7.0'
  s.add_dependency 'bricolage', '>= 5.27.0', '~> 6.0.0beta5'
  s.add_dependency 'google-apis-sheets_v4', '~> 0.4.0'
end
