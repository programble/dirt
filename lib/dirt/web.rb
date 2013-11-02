require 'redis'
require 'sinatra/base'

require 'dirt/api'
require 'dirt/api/meta'
require 'dirt/api/classify'
require 'dirt/api/stats'

module Dirt
  class Web < Sinatra::Base
    use API::Meta
    use API::Classify
    use API::Stats

    set :public_folder, File.join(File.dirname(__FILE__), 'public')

    get '/' do
      liquid :index
    end

    get '/demo' do
      liquid :demo, locals: {
        title: 'Demo',
        demo: 'active',
        js: ['demo']
      }
    end

    get '/stats' do
      liquid :stats, locals: {
        title: 'Statistics',
        stats: 'active'
      }
    end

    get '/api/doc' do
      liquid :api_doc, locals: {
        title: 'API Documentation',
        doc: 'active',
        version: API::VERSION[:string]
      }
    end

    get '/api' do
      redirect to('/api/doc')
    end

    get '/api/:method' do |method|
      redirect to("/api/doc##{method}")
    end

    get '/api/:m1/:m2' do |m1, m2|
      redirect to("/api/doc##{m1}/#{m2}")
    end
  end
end
