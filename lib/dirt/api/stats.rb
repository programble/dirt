require 'json'
require 'redis'
require 'sinatra/base'

module Dirt
  module API
    class Stats < Sinatra::Base
      def redis
        @redis ||= Redis.new
      end

      def error(status, message)
        halt status, {error: message}.to_json
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

      get '/api/stats/tokens' do
        language = params[:language]
        error 404, 'Unknown language' unless redis.exists("tokens:#{language}")

        begin
          limit = Integer(params[:limit] || 20)
          page = Integer(params[:page] || 1)
        rescue ArgumentError
          error 400, 'Invalid limit or page'
        end

        error 400, 'Invalid limit' if limit < 1
        error 400, 'Invalid page' if page < 1

        error 403, 'Limit over maximum' if limit > 1000

        lower = (page - 1) * limit
        upper = lower + limit - 1

        tokens = redis.zrevrange("tokens:#{language}", lower, upper, with_scores: true)
        error 404, 'No more tokens' if tokens.empty?

        tokens.map {|l, t| [l, t.to_i] }.to_json
      end
    end
  end
end
