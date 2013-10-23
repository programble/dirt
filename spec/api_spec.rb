require 'dirt/api'

describe Dirt::API do
  include Rack::Test::Methods

  def app
    described_class
  end

  def json_body
    JSON.parse(last_response.body)
  end

  before do
    redis = Redis.new
    redis.del(redis.keys('*')) unless redis.keys('*').empty?

    classifier = Dirt::Classifier.new(redis)
    ('A'..'Z').each {|l| classifier.train!(l, %w[foo bar baz]) }
  end

  context 'detect' do
    def detect(*args)
      post('/api/detect', *args)
    end

    it 'returns bad request for missing sample' do
      detect
      last_response.status.should == 400
    end

    it 'returns a JSON array' do
      detect(sample: 'foo')

      last_response.should be_ok
      last_response['content-type'].should start_with('application/json')
      json_body.should be_an(Array)
    end
  end

  context 'scores' do
    def scores(*args)
      post('/api/scores', *args)
    end

    it 'returns bad request for missing sample' do
      scores
      last_response.status.should == 400
    end

    it 'returns a JSON array of arrays' do
      scores(sample: 'foo')

      last_response.should be_ok
      last_response['content-type'].should start_with('application/json')
      json_body.should be_an(Array)
      json_body.each {|a| a.should be_an(Array) }
    end
  end
end
