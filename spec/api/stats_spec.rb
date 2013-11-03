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

  it 'languages returns a JSON hash of stats hashes' do
    get('/api/stats/languages')
    last_response.should be_ok
    json_body.should be_a(Hash)
    json_body.each do |language, stats|
      language.should be_a(String)
      stats.should be_a(Hash)
      stats['samples'].should be_a(Integer)
      stats['tokens'].should be_a(Integer)
    end
  end

  context 'tokens' do
    it 'returns 404 for unknown language' do
      get('/api/stats/tokens')
      last_response.status.should == 404
    end

    it 'returns a JSON array of pairs' do
      get('/api/stats/tokens', language: 'A')
      last_response.should be_ok
      json_body.should be_an(Array)
      json_body.each do |pair|
        pair.length.should == 2
        pair[0].should be_a(String)
        pair[1].should be_a(Integer)
      end
    end

    it 'defaults to limit 20' do
      get('/api/stats/tokens', language: 'A')
      json_body.length.should == 20
    end

    it 'limits' do
      get('/api/stats/tokens', language: 'A', limit: 10)
      json_body.length.should == 10
    end

    it 'returns 403 for limit over maximum' do
      get('/api/stats/tokens', language: 'A', limit: 1001)
      last_response.status.should == 403
    end

    it 'paginates' do
      get('/api/stats/tokens', language: 'A')
      sixth = json_body[5]
      get('/api/stats/tokens', language: 'A', limit: 5, page: 2)
      json_body.first.should == sixth
    end

    it 'returns 404 for out of bounds page' do
      get('/api/stats/tokens', language: 'A', page: 10000)
      last_response.status.should == 404
    end

    it 'returns 400 for invalid limit' do
      get('/api/stats/tokens', language: 'A', limit: 0)
      last_response.status.should == 400
      get('/api/stats/tokens', language: 'A', limit: -1)
      last_response.status.should == 400
      get('/api/stats/tokens', language: 'A', limit: 'a')
      last_response.status.should == 400
    end

    it 'returns 400 for invalid page' do
      get('/api/stats/tokens', language: 'A', page: 0)
      last_response.status.should == 400
      get('/api/stats/tokens', language: 'A', page: -1)
      last_response.status.should == 400
      get('/api/stats/tokens', language: 'A', page: 'a')
      last_response.status.should == 400
    end
  end
end
