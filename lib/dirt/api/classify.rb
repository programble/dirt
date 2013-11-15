require 'dirt/tokenizer'
require 'dirt/classifier'

require 'json'
require 'sinatra/base'
require 'sinatra/cross_origin'

module Dirt
  module API
    class Classify < Sinatra::Base
      register Sinatra::CrossOrigin
      set :cross_origin, true

      set :classifier, Classifier.new
      def classifier
        settings.classifier
      end

      def classify(params)
        halt 400, {error: 'No sample'}.to_json unless params[:sample]
        classifier.classify(Tokenizer.new(params[:sample]).tokenize)
      end

      before do
        content_type :json
      end

      post '/api/classify' do
        classify(params).sort_by {|l, s| -s }.map {|l, s| l }.to_json
      end

      post '/api/classify/scores' do
        raw = classify(params)
        max = -1 / raw.values.max

        raw.sort_by {|l, s| -s }.map {|l, s| [l, -1 / s / max] }.to_json
      end

      post '/api/classify/raw' do
        classify(params).to_json
      end
    end
  end
end
