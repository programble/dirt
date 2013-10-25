require 'dirt/api/meta'

describe Dirt::API::Meta do
  include Rack::Test::Methods

  context 'version' do
    it 'returns a JSON hash' do
      get('/api/meta/version')
      last_response.should be_ok
      last_response['Content-Type'].should start_with('application/json')
      json_body.should be_a(Hash)
      json_body['string'].should be_a(String)
      %w[major minor patch].each do |key|
        json_body[key].should be_a(Fixnum)
      end
    end
  end
end
