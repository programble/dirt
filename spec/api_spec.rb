require 'dirt/api'

describe Dirt::API do
  include Rack::Test::Methods

  def app
    described_class
  end

  context 'detect' do
    it 'returns bad request for empty sample' do
      post '/api/detect'
      last_response.status.should == 400

      post '/api/detect', sample: ''
      last_response.status.should == 400
    end

    it 'returns a JSON array' do
      post '/api/detect', sample: 'foo'

      last_response['content-type'].should start_with('application/json')
      JSON.parse(last_response.body).should be_an(Array)
    end
  end
end
