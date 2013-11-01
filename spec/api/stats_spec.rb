require 'dirt/classifier'
require 'dirt/api/stats'

describe Dirt::API::Stats do
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

  it 'stats returns a JSON stats hash' do
    get('/api/stats')
    last_response.should be_ok
    json_body.should be_a(Hash)
    json_body['languages'].should be_a(Integer)
    json_body['samples'].should be_a(Integer)
    json_body['tokens'].should be_a(Integer)
  end

  it 'languages returns a JSON array of strings' do
    get('/api/stats/languages')
    last_response.should be_ok
    json_body.should be_an(Array)
    json_body.each {|l| l.should be_a(String) }
  end

  it 'samples returns a JSON hash of strings to integers' do
    get('/api/stats/samples')
    last_response.should be_ok
    json_body.should be_a(Hash)
    json_body.each do |language, samples|
      language.should be_a(String)
      samples.should be_a(Integer)
    end
  end

  it 'tokens returns a JSON hash of strings to integers' do
    get('/api/stats/tokens')
    last_response.should be_ok
    json_body.should be_a(Hash)
    json_body.each do |language, samples|
      language.should be_a(String)
      samples.should be_a(Integer)
    end
  end

  context 'language' do
    it 'returns 404 for no language' do
      get('/api/stats/language')
      last_response.status.should == 404
    end

    it 'returns 404 for unknown language' do
      get('/api/stats/language', language: 'a')
      last_response.status.should == 404
    end

    it 'returns a language JSON hash' do
      get('/api/stats/language', language: 'A')
      last_response.should be_ok
      json_body.should be_a(Hash)
      json_body['samples'].should be_a(Integer)
      json_body['tokens'].should be_a(Integer)
      json_body['top'].should be_a(Array)
      json_body['top'].each do |pair|
        pair.should be_a(Array)
        pair[0].should be_a(String)
        pair[1].should be_a(Integer)
      end
    end
  end
end
