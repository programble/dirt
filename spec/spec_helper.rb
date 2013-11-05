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

ENV['REDIS_URL'] = 'redis://localhost:6379/1'
ENV['RACK_ENV'] = 'test'
