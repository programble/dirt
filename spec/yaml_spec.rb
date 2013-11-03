require 'yaml'

describe 'samples yaml file' do
  before do
    @samples = YAML.load_file(File.dirname(__FILE__) + '/../samples.yml')
  end

  it 'should be alphabetized' do
    @samples.keys.should == @samples.keys.sort
  end
end
