require 'rubygems'
gem 'echoe'
require 'echoe'

Echoe.new('tem_ruby') do |p|
  p.project = 'smartcard' # rubyforge project
  
  p.author = 'Victor Costan'
  p.email = 'victor@costan.us'
  p.summary = 'TEM (Trusted Execution Module) driver, written in and for ruby.'
  p.url = 'http://www.costan.us/smartcard'
  p.dependencies = ['smartcard >=0.2.2']
  
  p.need_tar_gz = false
  p.rdoc_pattern = /^(lib|bin|tasks|ext)|^BUILD|^README|^CHANGELOG|^TODO|^LICENSE|^COPYING$/  
end

if $0 == __FILE__
  Rake.application = Rake::Application.new
  Rake.application.run
end
