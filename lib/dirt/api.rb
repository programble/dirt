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

    def int_param(key, default)
      params[key] ? Integer(params[key]).tap {|i| raise if i < 0 } : default
    rescue
      halt 400, "Invalid #{key}"
    end

    def sample_scores(params)
      halt 400, 'No sample' unless params[:sample]

      tokenizer = Tokenizer.new(params[:sample])
      classifier = Classifier.new(redis)

      classifier.classify(tokenizer.tokenize)
    end

    post '/api/detect' do
      limit = int_param(:limit, 10)

      array = sample_scores(params).sort_by {|l, s| -s }.map {|l, s| l }

      content_type :json
      if limit == 0
        array.to_json
      else
        array.take(limit).to_json
      end
    end

    post '/api/scores' do
      limit = int_param(:limit, 10)

      scores = sample_scores(params)
      max = -1 / scores.values.max
      array = scores.sort_by {|l, s| -s }.map {|l, s| [l, -1 / s / max] }

      content_type :json
      if limit == 0
        array.to_json
      else
        array.take(limit).to_json
      end
    end
  end
end
