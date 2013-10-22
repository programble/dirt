require 'redis'
require 'sinatra/base'

require 'dirt/api'

module Dirt
  class Web < Sinatra::Base
    use API

    set :public_folder, File.join(File.dirname(__FILE__), 'public')

    def redis
      @redis ||= Redis.new
    end

    get '/' do
      liquid :index
    end

    get '/api' do
      redirect to('/api/documentation')
    end

    get '/api/:endpoint' do |endpoint|
      pass if endpoint == 'documentation'
      redirect to('/api/documentation#' + endpoint)
    end
  end
end
