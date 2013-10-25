require 'dirt/api/classify'

describe Dirt::API::Classify do
  include Rack::Test::Methods

  before do
    redis = Redis.new
    redis.del(redis.keys('*')) unless redis.keys('*').empty?

    classifier = Dirt::Classifier.new
    ('A'..'Z').each do |language|
      tokens = %w[foo bar baz].sample(rand(3))
      classifier.train!(language, tokens)
    end
  end

  METHODS = {
    classify: '/api/classify',
    scores: '/api/classify/scores',
    raw: '/api/classify/raw'
  }

  def classify(*args)
    post(METHODS[:classify], *args)
  end

  def scores(*args)
    post(METHODS[:scores], *args)
  end

  def raw(*args)
    post(METHODS[:raw], *args)
  end

  METHODS.each do |method, path|
    it "#{method} returns bad request for missing sample" do
      post(path)
      last_response.status.should == 400
    end
  end

  context 'classify' do
    it 'returns a JSON array of strings' do
      classify(sample: 'foo')
      last_response.should be_ok
      last_response['Content-Type'].should start_with('application/json')
      json_body.should be_an(Array)
      json_body.each {|s| s.should be_a(String) }
    end
  end

  context 'scores' do
    it 'returns a JSON array of string-float pairs' do
      scores(sample: 'foo')
      last_response.should be_ok
      last_response['Content-Type'].should start_with('application/json')
      json_body.should be_an(Array)
      json_body.each do |pair|
        pair.should be_an(Array)
        pair.length.should == 2
        pair[0].should be_a(String)
        pair[1].should be_a(Float)
      end
    end

    it 'normalizes scores' do
      scores(sample: 'foo')
      json_body[0][1].should == 1.0
      json_body.each {|_, s| s.should be_between(0.0, 1.0) }
    end
  end

  context 'raw' do
    it 'returns a JSON hash of string to float' do
      raw(sample: 'foo')
      last_response.should be_ok
      last_response['Content-Type'].should start_with('application/json')
      json_body.should be_a(Hash)
      json_body.each do |key, value|
        key.should be_a(String)
        value.should be_a(Float)
      end
    end
  end
end
