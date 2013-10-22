require 'json'
require 'redis'
require 'sinatra/base'

require 'dirt/tokenizer'
require 'dirt/classifier'

module Dirt
  class API < Sinatra::Base
  end
end
