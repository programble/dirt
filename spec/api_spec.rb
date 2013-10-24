require 'dirt/api'

describe Dirt::API do
  include Rack::Test::Methods

  before do
    redis = Redis.new
    redis.del(redis.keys('*')) unless redis.keys('*').empty?

    classifier = Dirt::Classifier.new(redis)
    ('A'..'Z').each {|l| classifier.train!(l, %w[foo bar baz]) }
  end

  it 'returns a version JSON hash' do
    get('/api/version')
    last_response.should be_ok
    last_response['content-type'].should start_with('application/json')
    json_body.should be_a(Hash)
    json_body['string'].should be_a(String)
    %w[major minor patch].each {|k| json_body[k].should be_a(Fixnum) }
  end

  def detect(*args)
    post('/api/detect', *args)
  end

  def scores(*args)
    post('/api/scores', *args)
  end

  context 'detect' do
    it 'returns a JSON array of strings' do
      detect(sample: 'foo')
      last_response.should be_ok
      last_response['content-type'].should start_with('application/json')
      json_body.should be_an(Array)
      json_body.each {|s| s.should be_a(String) }
    end
  end

  context 'scores' do
    it 'returns a JSON array of string-float pairs' do
      scores(sample: 'foo')
      last_response.should be_ok
      last_response['content-type'].should start_with('application/json')
      json_body.should be_an(Array)
      json_body.each do |pair|
        pair.should be_an(Array)
        pair.length.should == 2
        pair[0].should be_a(String)
        pair[1].should be_a(Float)
      end
    end
  end

  context 'detect/scores' do
    it 'returns bad request for missing sample' do
      detect
      last_response.status.should == 400
      scores
      last_response.status.should == 400
    end

    it 'returns bad request for invalid limit' do
      detect(sample: 'foo', limit: 'bar')
      last_response.status.should == 400
      scores(sample: 'foo', limit: 'bar')
      last_response.status.should == 400

      detect(sample: 'foo', limit: -1)
      last_response.status.should == 400
      scores(sample: 'foo', limit: -1)
      last_response.status.should == 400
    end

    it 'defaults to limit of 10' do
      detect(sample: 'foo')
      json_body.length.should == 10
      scores(sample: 'foo')
      json_body.length.should == 10
    end

    it 'limits' do
      detect(sample: 'foo', limit: 5)
      json_body.length.should == 5
      scores(sample: 'foo', limit: 5)
      json_body.length.should == 5
    end

    it 'returns all results with limit of 0' do
      detect(sample: 'foo', limit: 0)
      json_body.length.should == 26
      scores(sample: 'foo', limit: 0)
      json_body.length.should == 26
    end
  end
end
