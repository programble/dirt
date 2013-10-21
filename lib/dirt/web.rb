require 'redis'
require 'sinatra/base'

module Dirt
  class Web < Sinatra::Base
    def redis
      @redis ||= Redis.new
    end

    get '/' do
      liquid :index, locals: {
        tokens: redis.get('tokens:total'),
        samples: redis.get('languages:total'),
        languages: redis.hlen('languages')
      }
    end
  end
end
