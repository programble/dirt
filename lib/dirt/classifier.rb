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

require 'dirt/mongo'

module Dirt
  class Classifier
    def train!(language, tokens)
      tokens_total = tokens.values.reduce(:+)

      language_id = Mongo.languages.find_and_modify(
        query:  {'name' => language},
        update: {'$inc' => {'samples' => 1,
                            'tokens'  => tokens_total}},
        fields: {'_id' => true},
        new:    true,
        upsert: true)['_id']

      tokens.each do |token, count|
        Mongo.tokens.update(
          {'language_id' => language_id, 'token' => token},
          {'$inc' => {'count' => count}},
          {upsert: true})
      end

      Mongo.totals.update(
        {},
        {'$inc' => {'samples' => 1, 'tokens'  => tokens_total}},
        {upsert: true})
    end

    def prune!
      tokens_total = 0
      Mongo.languages.find.each do |language|
        query = {'language_id' => language['_id'], 'count' => 1}
        tokens = Mongo.tokens.count(query)
        Mongo.tokens.remove(query)

        Mongo.languages.update(language, {'$inc' => {'tokens' => -tokens}})

        tokens_total += tokens
      end

      Mongo.totals.update( {}, {'$inc' => {'tokens' => -tokens_total}})
    end

    def classify(tokens)
      totals = Mongo.totals.find_one

      Hash.new.tap do |scores|
        Mongo.languages.find.each do |language|
          scores[language['name']] = tokens_probability(tokens, language, totals) +
            Math.log(language['samples'] / totals['samples'].to_f)
        end
      end
    end

    def tokens_probability(tokens, language, totals)
      tokens.map do |token, count|
        score = Mongo.tokens.find_one({'language_id' => language['_id'],
                                       'token'       => token})
        if score
          Math.log(score['count'] / language['tokens'].to_f) * count
        else
          Math.log(1 / totals['tokens'].to_f) * count
        end
      end.reduce(0.0, :+)
    end
  end
end
