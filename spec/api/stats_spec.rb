require 'dirt/classifier'
require 'dirt/api/stats'

describe Dirt::API::Stats do
  include Rack::Test::Methods

  include RandomTraining
  before { train! }

  context 'stats' do
    it 'returns a JSON stats hash' do
      get('/api/stats')

      expect(last_response).to be_ok
      expect(last_response['Content-Type']).to start_with('application/json')
      expect(json_body).to be_a(Hash)
      %w[languages samples tokens].each do |key|
        expect(json_body[key]).to be_a(Integer)
      end
    end
  end

  context 'stats/languages' do
    it 'returns a JSON hash of stats hashes' do
      get('/api/stats/languages')

      expect(last_response).to be_ok
      expect(last_response['Content-Type']).to start_with('application/json')
      expect(json_body).to be_a(Hash)
      json_body.each do |language, stats|
        expect(language).to be_a(String)
        expect(stats).to be_a(Hash)
        expect(stats['samples']).to be_an(Integer)
        expect(stats['tokens']).to be_an(Integer)
        expect(stats['uniqueTokens']).to be_an(Integer)
      end
    end
  end

  context 'stats/tokens' do
    def tokens(*args)
      get('/api/stats/tokens', *args)
    end

    it 'returns 404 for unknown language' do
      tokens
      expect_json_error(404)
    end

    it 'returns a JSON array of pairs' do
      tokens(language: 'A')

      expect(last_response).to be_ok
      expect(last_response['Content-Type']).to start_with('application/json')
      expect(json_body).to be_an(Array)
      json_body.each do |pair|
        expect(pair).to be_an(Array)
        expect(pair.length).to eq(2)
        expect(pair[0]).to be_a(String)
        expect(pair[1]).to be_an(Integer)
      end
    end

    it 'defaults to limit 20' do
      tokens(language: 'A')
      expect(json_body.length).to eq(20)
    end

    it 'limits' do
      tokens(language: 'A', limit: 10)
      expect(json_body.length).to eq(10)
    end

    it 'returns 403 for limit over maximum' do
      tokens(language: 'A', limit: 1001)
      expect_json_error(403)
    end

    it 'paginates' do
      tokens(language: 'A')
      sixth = json_body[5]
      tokens(language: 'A', limit: 5, page: 2)
      expect(json_body.first).to eq(sixth)
    end

    it 'returns 404 for out of bounds page' do
      tokens(language: 'A', page: 10000)
      expect_json_error(404)
    end

    it 'returns 400 for invalid limit' do
      tokens(language: 'A', limit: 0)
      expect_json_error(400)

      tokens(language: 'A', limit: -1)
      expect_json_error(400)

      tokens(language: 'A', limit: 'a')
      expect_json_error(400)
    end

    it 'returns 400 for invalid page' do
      tokens(language: 'A', page: 0)
      expect_json_error(400)

      tokens(language: 'A', page: -1)
      expect_json_error(400)

      tokens(language: 'A', page: 'a')
      expect_json_error(400)
    end
  end
end
