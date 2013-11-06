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
      @redis = redis.is_a?(Redis) ? redis : Redis.new(redis)
    end

    def languages
      @redis.hkeys('samples')
    end

    def train!(language, tokens)
      @redis.hincrby('samples', language, 1)
      @redis.incr('samples:total')

      @redis.pipelined do
        tokens.each do |token|
          @redis.zincrby("tokens:#{language}", 1, token)
          @redis.incr("tokens:#{language}:total")
          @redis.incr('tokens:total')
        end
      end
    end

    def prune!(set = nil)
      set ||= languages

      total_removed = 0
      set.each do |language|
        removed = @redis.zremrangebyscore("tokens:#{language}", 0, 1)
        total_removed += removed
        @redis.decrby("tokens:#{language}:total", removed)
      end
      @redis.decrby('tokens:total', total_removed)
    end

    def classify(tokens, set = nil)
      set ||= languages

      Hash.new.tap do |scores|
        set.each do |language|
          scores[language] = tokens_probability(tokens, language) +
            language_probability(language)
        end
      end
    end

    def tokens_probability(tokens, language)
      language_total = @redis.get("tokens:#{language}:total").to_f
      total = @redis.get('tokens:total').to_f

      @redis.pipelined do
        tokens.each {|t| @redis.zscore("tokens:#{language}", t) }
      end.map do |n|
        Math.log(n ? n.to_f / language_total : 1.0 / total)
      end.reduce(0.0, :+)
    end

    def language_probability(language)
      Math.log(@redis.hget('samples', language).to_f / @redis.get('samples:total').to_f)
    end
  end
end
