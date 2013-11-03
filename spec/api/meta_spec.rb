require 'dirt/api/meta'

describe Dirt::API::Meta do
  include Rack::Test::Methods

  context '/version' do
    it 'returns a JSON hash' do
      get('/api/meta/version')

      expect(last_response).to be_ok
      expect(last_response['Content-Type']).to start_with('application/json')
      expect(json_body).to be_a(Hash)
      expect(json_body).to include('string', 'major', 'minor', 'patch')
      expect(json_body['string']).to be_a(String)
      %w[major minor patch].each do |key|
        expect(json_body[key]).to be_a(Integer)
      end
    end
  end
end
