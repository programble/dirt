require 'dirt/tokenizer'
require 'dirt/classifier'

require 'json'
require 'sinatra/base'

module Dirt
  module API
    class Classify < Sinatra::Base
      def classify(params)
        halt 400, 'No sample' unless params[:sample]

        tokenizer = Tokenizer.new(params[:sample])
        classifier = Classifier.new

        classifier.classify(tokenizer.tokenize)
      end

      post '/api/classify' do
        content_type :json
        classify(params).sort_by {|l, s| -s }.map {|l, s| l }.to_json
      end

      post '/api/classify/raw' do
        content_type :json
        classify(params).to_json
      end
    end
  end
end
