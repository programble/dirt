require 'json'
require 'redis'
require 'sinatra/base'

require 'dirt/tokenizer'
require 'dirt/classifier'

module Dirt
  class API < Sinatra::Base
    def redis
      @redis ||= Redis.new
    end

    def sample_scores(params)
      halt 400, 'No sample' unless params[:sample]

      tokenizer = Tokenizer.new(params[:sample])
      classifier = Classifier.new(redis)

      classifier.classify(tokenizer.tokenize)
    end

    post '/api/detect' do
      scores = sample_scores(params)

      content_type :json
      scores.sort_by {|l, s| -s }.map {|l, s| l }.to_json
    end

    post '/api/scores' do
      scores = sample_scores(params)
      max = -1 / scores.values.max

      content_type :json
      scores.sort_by {|l, s| -s }.map {|l, s| [l, -1 / s / max] }.to_json
    end
  end
end
