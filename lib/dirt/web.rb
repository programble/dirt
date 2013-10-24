require 'redis'
require 'sinatra/base'

require 'dirt/api'

module Dirt
  class Web < Sinatra::Base
    use API

    set :public_folder, File.join(File.dirname(__FILE__), 'public')

    def redis
      @redis ||= Redis.new
    end

    get '/' do
      liquid :index
    end

    get '/api' do
      redirect to('/api/doc')
    end

    get '/api/:endpoint' do |endpoint|
      pass if endpoint == 'doc'
      redirect to('/api/doc#' + endpoint)
    end

    get '/demo' do
      liquid :demo, locals: {
        title: 'Demo',
        demo: 'active',
        css: ['demo'],
        js: ['demo']
      }
    end

    get '/api/doc' do
      liquid :api_doc, locals: {
        title: 'API Documentation',
        doc: 'active',
        version: API::VERSION[:string]
      }
    end
  end
end
