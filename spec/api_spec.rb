require 'dirt/api'

describe Dirt::API do
  include Rack::Test::Methods

  def app
    described_class
  end
end
