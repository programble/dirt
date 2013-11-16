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

require 'redis'

module Dirt
  class Classifier
    def initialize(redis = {})
      @db = redis.is_a?(Redis) ? redis : Redis.new(redis)
    end

    def languages
      @db.hkeys('samples')
    end

    def train!(language, tokens)
      @db.hincrby('samples', language, 1)
      @db.incr('samples:total')

      @db.pipelined do
        tokens.each do |token, count|
          @db.zincrby("tokens:#{language}", count, token)
          @db.incrby("tokens:#{language}:total", count)
          @db.incrby('tokens:total', count)
        end
      end
    end

    def prune!(set = nil)
      set ||= languages

      total_removed = 0
      set.each do |language|
        removed = @db.zremrangebyscore("tokens:#{language}", 0, 1)
        total_removed += removed
        @db.decrby("tokens:#{language}:total", removed)
      end
      @db.decrby('tokens:total', total_removed)
    end

    def classify(tokens, set = nil)
      set ||= languages

      Hash.new.tap do |scores|
        set.each do |language|
          score = Math.log(
            @db.hget('samples', language).to_f / @db.get('samples:total').to_f)

          language_total = @db.get("tokens:#{language}:total").to_f
          total = @db.get('tokens:total').to_f

          tokens.each do |token, count|
            if token_score = @db.zscore("tokens:#{language}", token)
              score += Math.log(token_score.to_f / language_total) * count
            else
              score += Math.log(1 / total) * count
            end
          end

          scores[language] = score
        end
      end
    end
  end
end
