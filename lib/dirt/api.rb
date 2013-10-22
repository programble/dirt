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

    post '/api/detect' do
      halt 400, 'Empty sample' if params[:sample].nil? || params[:sample].empty?

      tokenizer = Tokenizer.new(params[:sample])
      classifier = Classifier.new(redis)

      scores = classifier.classify(tokenizer.tokenize)

      content_type :json
      scores.sort_by {|l, s| -s }.map {|l, s| l }.to_json
    end
  end
end
