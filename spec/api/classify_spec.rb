require 'dirt/api/classify'

describe Dirt::API::Classify do
  include Rack::Test::Methods

  before do
    redis = Redis.new
    redis.del(redis.keys('*')) unless redis.keys('*').empty?

    classifier = Dirt::Classifier.new(redis)
    ('A'..'Z').each do |language|
      tokens = %w[foo bar baz].sample(rand(3))
      classifier.train!(language, tokens)
    end
  end

  def classify(*args)
    post('/api/classify', *args)
  end

  def scores(*args)
    post('/api/classify/scores', *args)
  end

  def raw(*args)
    post('/api/classify/raw', *args)
  end

  context 'classify' do
    it 'returns 400 for bad request' do
      classify
      expect(last_response.status).to eq(400)
    end

    it 'returns a JSON array of strings' do
      classify(sample: 'foo')

      expect(last_response).to be_ok
      expect(last_response['Content-Type']).to start_with('application/json')
      expect(json_body).to be_an(Array)
      json_body.each do |language|
        expect(language).to be_a(String)
      end
    end
  end

  context 'classify/scores' do
    it 'returns 400 for bad request' do
      scores
      expect(last_response.status).to eq(400)
    end

    it 'returns a JSON array of string-float pairs' do
      scores(sample: 'foo')

      expect(last_response).to be_ok
      expect(last_response['Content-Type']).to start_with('application/json')
      expect(json_body).to be_an(Array)
      json_body.each do |pair|
        expect(pair).to be_an(Array)
        expect(pair.length).to eq(2)
        expect(pair[0]).to be_a(String)
        expect(pair[1]).to be_a(Float)
      end
    end

    it 'normalizes scores' do
      scores(sample: 'foo')

      expect(json_body[0][1]).to eq(1.0)
      json_body.each do |_, score|
        expect(score).to be_between(0.0, 1.0)
      end
    end
  end

  context 'classify/raw' do
    it 'returns 400 for bad request' do
      raw
      expect(last_response.status).to eq(400)
    end

    it 'returns a JSON hash of string to float' do
      raw(sample: 'foo')

      expect(last_response).to be_ok
      expect(last_response['Content-Type']).to start_with('application/json')
      expect(json_body).to be_a(Hash)
      json_body.each do |language, score|
        expect(language).to be_a(String)
        expect(score).to be_a(Float)
      end
    end
  end
end
