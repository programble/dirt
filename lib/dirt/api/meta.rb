require 'dirt/api'

require 'json'
require 'sinatra/base'

module Dirt
  module API
    class Meta < Sinatra::Base
      get '/api/meta/version' do
        content_type :json
        API::VERSION.to_json
      end
    end
  end
end
