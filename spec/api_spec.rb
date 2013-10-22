require 'dirt/api'

describe Dirt::API do
  include Rack::Test::Methods

  def app
    described_class
  end

  it 'redirects /api to documentation' do
    get '/api'
    follow_redirect!

    last_request.path.should == '/api/documentation'
  end
end
