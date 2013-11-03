require 'yaml'

describe 'samples YAML file' do
  before do
    @samples = YAML.load_file('samples.yml')
  end

  it 'is alphabetized' do
    expect(@samples.keys).to eq(@samples.keys.sort)
  end

  it 'contains globs for each language' do
    @samples.each do |language, hash|
      expect([String, Array]).to include(hash['glob'].class)
    end
  end

  it 'contains git repositories for each language' do
    @samples.each do |language, hash|
      expect(hash['git']).to be_an(Array)
    end
  end
end
