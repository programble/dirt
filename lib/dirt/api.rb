require 'redis'
require 'sinatra/base'

module Dirt
  class API < Sinatra::Base
    get '/api' do
      redirect to('/api/documentation')
    end
  end
end
