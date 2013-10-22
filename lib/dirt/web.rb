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
  end
end
