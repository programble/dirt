require 'yaml'

describe 'samples YAML file' do
  before do
    @samples = YAML.load_file('samples.yml')
  end

  it 'is alphabetized' do
    @samples.keys.should == @samples.keys.sort
  end

  it 'contains globs for each language' do
    @samples.each do |language, hash|
      [String, Array].should include(hash['glob'].class)
    end
  end

  it 'contains git repositories for each language' do
    @samples.each do |language, hash|
      hash['git'].should be_an(Array)
    end
  end
end
