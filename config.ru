$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'dirt/mongo'
require 'dirt/web'

Dirt::Mongo.connect!
run Dirt::Web
