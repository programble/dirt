require 'dirt/api'

require 'json'
require 'sinatra/base'
require 'sinatra/cross_origin'

module Dirt
  module API
    class Meta < Sinatra::Base
      register Sinatra::CrossOrigin
      set :cross_origin, true

      get '/api/meta/version' do
        content_type :json
        API::VERSION.to_json
      end
    end
  end
end
