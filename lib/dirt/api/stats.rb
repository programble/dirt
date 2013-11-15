require 'json'
require 'sinatra/base'
require 'sinatra/cross_origin'

require 'dirt/stats'

module Dirt
  module API
    class Stats < Sinatra::Base
      register Sinatra::CrossOrigin
      set :cross_origin, true

      set :stats, Dirt::Stats.new
      def stats
        settings.stats
      end

      def error(status, message)
        halt status, {error: message}.to_json
      end

      before do
        content_type :json
      end

      get '/api/stats' do
        stats.totals.to_json
      end

      get '/api/stats/languages' do
        stats.languages.to_json
      end

      get '/api/stats/tokens' do
        begin
          limit = Integer(params[:limit] || 20)
          page = Integer(params[:page] || 1)
        rescue ArgumentError
          error 400, 'Invalid limit or page'
        end

        error 400, 'Invalid limit' if limit < 1
        error 400, 'Invalid page' if page < 1

        error 403, 'Limit over maximum' if limit > 1000

        tokens = stats.tokens(params[:language], limit, page)
        error 404, 'Unknown language' unless tokens
        error 404, 'No more tokens' if tokens.empty?
        tokens.to_json
      end
    end
  end
end
