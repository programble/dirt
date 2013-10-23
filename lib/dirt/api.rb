require 'json'
require 'redis'
require 'sinatra/base'

require 'dirt/tokenizer'
require 'dirt/classifier'

module Dirt
  class API < Sinatra::Base
    def sample_scores(params)
      halt 400, 'Empty sample' if params[:sample].nil? || params[:sample].empty?

      tokenizer = Tokenizer.new(params[:sample])
      classifier = Classifier.new

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
