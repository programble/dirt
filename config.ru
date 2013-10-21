$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'dirt/web'

run Dirt::Web
