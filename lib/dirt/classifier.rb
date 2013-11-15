# Based on https://github.com/github/linguist/blob/master/lib/linguist/classifier.rb
#
# Copyright (c) 2011-2013 GitHub, Inc.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

require 'mongo'

module Dirt
  class Classifier
    def initialize(mongo = nil)
      @mongo = mongo || Mongo::MongoClient.new
      @db = @mongo.db

      @db['languages'].ensure_index({'name' => Mongo::ASCENDING}, unique: true)
      @db['tokens'].ensure_index({'language_id' => Mongo::ASCENDING,
                                  'tokens'      => Mongo::ASCENDING})
    end

    def train!(language, tokens, samples = 1)
      tokens_total = tokens.values.reduce(:+)

      language = @db['languages'].find_and_modify(
        query:  {'name' => language},
        update: {'$inc' => {'samples' => samples, 'tokens' => tokens_total}},
        new:    true,
        upsert: true)

      tokens.each do |token, count|
        @db['tokens'].update(
          {'language_id' => language['_id'], 'token' => token},
          {'$inc' => {'count' => count}},
          upsert: true)
      end

      @db['totals'].update(
        {},
        {'$inc' => {'samples' => samples, 'tokens' => tokens_total}},
        upsert: true)
    end

    def prune!
      tokens_total = 0

      @db['languages'].find.each do |language|
        query = {'language_id' => language['_id'], 'count' => 1}
        tokens = @db['tokens'].count(query)
        @db['tokens'].remove(query) # FIXME: Possible race condition

        @db['languages'].update(
          language['_id'],
          {'$inc' => {'tokens' => -tokens}})

        tokens_total += tokens
      end

      @db['totals'].update({}, {'$inc' => {'tokens' => -tokens_total}})
    end

    def classify(tokens)
      totals = @db['totals'].find_one

      Hash.new.tap do |scores|
        @db['languages'].find.each do |language|
          score = Math.log(language['samples'] / totals['samples'].to_f)

          tokens.each do |token, count|
            db_token = @db['tokens'].find_one(
              {'language_id' => language['_id'],
               'token'       => token})

            if db_token
              score += Math.log(db_token['count'] / language['tokens'].to_f) * count
            else
              score += Math.log(1 / totals['tokens'].to_f) * count
            end
          end

          scores[language['name']] = score
        end
      end
    end
  end
end
