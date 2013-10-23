require 'dirt/api'

# HACK: Make API use /1 for specs
SpecRedis = Redis.new(url: 'redis://localhost:6379/1')
class Dirt::API
  def redis
    SpecRedis
  end
end

describe Dirt::API do
  include Rack::Test::Methods

  before do
    SpecRedis.del(SpecRedis.keys('*')) unless SpecRedis.keys('*').empty?

    classifier = Dirt::Classifier.new(SpecRedis)
    ('A'..'Z').each {|l| classifier.train!(l, %w[foo bar baz]) }
  end

  def app
    described_class
  end

  it 'returns bad request for empty sample' do
    ['detect', 'scores'].each do |endpoint|
      post "/api/#{endpoint}"
      last_response.status.should == 400

      post "/api/#{endpoint}", sample: ''
      last_response.status.should == 400
    end
  end

  it 'returns a JSON array' do
    ['detect', 'scores'].each do |endpoint|
      post "/api/#{endpoint}", sample: 'foo'

      last_response.should be_ok
      last_response['content-type'].should start_with('application/json')
      JSON.parse(last_response.body).should be_an(Array)
    end
  end
end
