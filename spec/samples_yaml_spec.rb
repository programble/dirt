require 'yaml'

describe 'samples YAML file' do
  before do
    @samples = YAML.load_file('samples.yml')
  end

  it 'is alphabetized' do
    @samples.keys.should == @samples.keys.sort
  end
end
