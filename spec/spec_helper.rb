require 'bundler/setup'

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

SimpleCov.start do
  add_filter '/spec/'
end

require 'rspec'

module RandomTraining
  def train!
    redis = Redis.new
    redis.del(redis.keys('*')) unless redis.keys('*').empty?

    classifier = Dirt::Classifier.new(redis)
    ('A'..'M').each do |language|
      tokens = Hash.new(0)
      25.times do
        tokens[('a'..'z').to_a.sample(rand(8) + 1).join] += 1
      end
      classifier.train!(language, tokens)
    end
  end
end

require 'rack/test'
require 'json'
module Rack::Test::Methods
  def app
    described_class
  end

  def json_body
    @json_body ||= Hash.new
    @json_body[last_response] ||= JSON.parse(last_response.body)
  end

  def expect_json_error(status)
    expect(last_response.status).to eq(status)
    expect(last_response['Content-Type']).to start_with('application/json')
    expect(json_body).to be_a(Hash)
    expect(json_body).to include('error')
  end
end

ENV['MONGODB_URI'] = 'mongodb://localhost/dirt_test'
ENV['RACK_ENV'] = 'test'
