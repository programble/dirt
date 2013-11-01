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
        redis.hkeys('samples').to_json
      end

      get '/api/stats/samples' do
        redis.hgetall('samples').map do |language, samples|
          {language => samples.to_i}
        end.reduce(&:merge).to_json
      end

      get '/api/stats/tokens' do
        redis.hkeys('samples').map do |language|
          {language => redis.get("tokens:#{language}:total").to_i}
        end.reduce(&:merge).to_json
      end

      get '/api/stats/language' do
        language = params[:language]
        halt 404, 'Unknown language' unless redis.exists("tokens:#{language}")
        {
          samples: redis.hget('samples', language).to_i,
          tokens: redis.get("tokens:#{language}:total").to_i,
          top: redis.zrevrange("tokens:#{language}",
                               0, 49, with_scores: true).map do |token, score|
            [token, score.to_i]
          end
        }.to_json
      end
    end
  end
end
