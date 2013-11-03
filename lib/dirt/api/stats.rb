require 'json'
require 'redis'
require 'sinatra/base'

module Dirt
  module API
    class Stats < Sinatra::Base
      def redis
        @redis ||= Redis.new
      end

      before do
        content_type :json
      end

      get '/api/stats' do
        {
          languages: redis.hlen('samples').to_i,
          samples: redis.get('samples:total').to_i,
          tokens: redis.get('tokens:total').to_i
        }.to_json
      end

      get '/api/stats/languages' do
        redis.hgetall('samples').map do |language, samples|
          {language => {
            samples: samples.to_i,
            tokens: redis.get("tokens:#{language}:total").to_i
          }}
        end.reduce(&:merge).to_json
      end
    end
  end
end
