if ENV['RACK_ENV'] == 'development'
  ENV['MONGODB_URI'] ||= 'mongodb://localhost/dirt_development'
end

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'dirt/web'

run Dirt::Web
