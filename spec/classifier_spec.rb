require 'dirt/classifier'

describe Dirt::Classifier do
  before do
    url = 'redis://localhost:6379/1'
    @redis = Redis.new(url: url)
    @classifier = described_class.new(url: url)
  end

  after do
    @redis.del(@redis.keys('*'))
  end

  it 'trains' do
    @classifier.train!('A', %w[foo bar baz])
    @classifier.train!('A', %w[foo foo baz])
    @classifier.train!('B', %w[bar bar baz])

    @redis.get('languages:total').to_i.should == 3
    @redis.hget('languages', 'A').to_i.should == 2
    @redis.hget('languages', 'B').to_i.should == 1
    @redis.get('tokens:total').to_i.should == 9
    @redis.get('tokens:A:total').to_i.should == 6
    @redis.get('tokens:B:total').to_i.should == 3
    @redis.hget('tokens:A', 'foo').to_i.should == 3
    @redis.hget('tokens:A', 'bar').to_i.should == 1
    @redis.hget('tokens:A', 'baz').to_i.should == 2
    @redis.hget('tokens:B', 'bar').to_i.should == 2
    @redis.hget('tokens:B', 'baz').to_i.should == 1
  end

  it 'classifies' do
    @classifier.train!('A', %w[foo bar baz])
    @classifier.train!('A', %w[foo foo baz])
    @classifier.train!('B', %w[bar bar baz])

    @classifier.classify(%w[bar baz]).should == ['B', 'A']
    @classifier.classify(%w[foo baz]).should == ['A', 'B']
    @classifier.classify(%w[quux]).should == ['A', 'B']
  end
end
