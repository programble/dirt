require 'mongo'

module Dirt
  class Stats
    def initialize(mongo = nil)
      @mongo = mongo || Mongo::MongoClient.new
      @db = @mongo.db

      @db['tokens'].ensure_index({'language_id' => Mongo::ASCENDING})
    end

    def totals
      totals = @db['totals'].find_one
      languages = @db['languages'].find.count
      {
        languages: languages,
        samples:   totals['samples'],
        tokens:    totals['tokens']
      }
    end

    def languages
      @db['languages'].find.map do |language|
        unique = @db['tokens'].find({'language_id' => language['_id']}).count
        {language['name'] => {
          samples:      language['samples'],
          tokens:       language['tokens'],
          uniqueTokens: unique
        }}
      end.reduce(&:merge)
    end

    def tokens(language_name, limit, page)
      language = @db['languages'].find_one({'name' => language_name})
      return unless language
      tokens = @db['tokens']
        .find({'language_id' => language['_id']})
        .sort({'count' => Mongo::DESCENDING})
        .skip((page - 1) * limit)
        .limit(limit)
      tokens.map do |token|
        [token['token'], token['count']]
      end
    end
  end
end
