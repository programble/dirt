require 'dirt/api'

describe Dirt::API do
  include Rack::Test::Methods

  def app
    described_class
  end

  ['detect', 'scores'].each do |endpoint|
    context endpoint do
      it 'returns bad request for empty sample' do
        post "/api/#{endpoint}"
        last_response.status.should == 400

        post "/api/#{endpoint}", sample: ''
        last_response.status.should == 400
      end

      it 'returns a JSON array' do
        post "/api/#{endpoint}", sample: 'foo'

        last_response['content-type'].should start_with('application/json')
        JSON.parse(last_response.body).should be_an(Array)
      end
    end
  end
end
