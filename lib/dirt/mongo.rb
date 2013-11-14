require 'uri'
require 'mongo'

module Dirt
  module Mongo
    include ::Mongo

    module_function

    def connect!
      return if @client

      uri = URI(ENV.fetch('MONGO_URI', 'mongodb://localhost/dirt_development'))
      uri.port ||= MongoClient::DEFAULT_PORT

      @client = MongoClient.new(uri.host, uri.port)
      @db = @client.db(uri.path[1..-1])

      @db.collection('languages').ensure_index({'name' => ASCENDING},
                                               unique: true)
      @db.collection('tokens').ensure_index({'language_id' => ASCENDING,
                                             'token' => ASCENDING})
    end

    def client
      @client
    end

    def db
      @db
    end

    def totals
      @db.collection('totals')
    end

    def languages
      @db.collection('languages')
    end

    def tokens
      @db.collection('tokens')
    end
  end
end
