require 'dirt/classifier'

describe Dirt::Classifier do
  before do
    @redis = Redis.new
    @redis.del(@redis.keys('*')) unless @redis.keys('*').empty?
    @classifier = described_class.new(@redis)
  end

  it 'trains' do
    @classifier.train!('A', %w[foo bar baz])
    @classifier.train!('A', %w[foo foo baz])
    @classifier.train!('B', %w[bar bar baz])

    @redis.get('samples:total').to_i.should == 3
    @redis.hget('samples', 'A').to_i.should == 2
    @redis.hget('samples', 'B').to_i.should == 1
    @redis.get('tokens:total').to_i.should == 9
    @redis.get('tokens:A:total').to_i.should == 6
    @redis.get('tokens:B:total').to_i.should == 3
    @redis.zscore('tokens:A', 'foo').to_i.should == 3
    @redis.zscore('tokens:A', 'bar').to_i.should == 1
    @redis.zscore('tokens:A', 'baz').to_i.should == 2
    @redis.zscore('tokens:B', 'bar').to_i.should == 2
    @redis.zscore('tokens:B', 'baz').to_i.should == 1
  end

  it 'classifies' do
    @classifier.train!('A', %w[foo bar baz])
    @classifier.train!('A', %w[foo foo baz])
    @classifier.train!('B', %w[bar bar baz])

    scores = @classifier.classify(%w[bar baz])
    scores['B'].should be > scores['A']
    scores = @classifier.classify(%w[foo baz])
    scores['A'].should be > scores['B']
    scores = @classifier.classify(%w[quux])
    scores['A'].should be > scores['B']
  end

  it 'classifies only against specific languages' do
    @classifier.train!('A', %w[foo bar baz])
    @classifier.train!('B', %w[foo bar baz])
    @classifier.train!('C', %w[foo bar baz])

    @classifier.classify(%w[foo bar baz], ['A', 'C']).keys.should == ['A', 'C']
  end

  it 'classifies with no tokens' do
    @classifier.classify([]).should == {}
  end
end
