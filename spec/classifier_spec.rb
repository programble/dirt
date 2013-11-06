require 'dirt/classifier'

describe Dirt::Classifier do
  before do
    @redis = Redis.new
    @redis.del(@redis.keys('*')) unless @redis.keys('*').empty?
    @classifier = described_class.new(@redis)
  end

  def classify(*args)
    @scores = @classifier.classify(*args)
  end

  context 'with training' do
    before do
      @classifier.train!('A', %w[foo bar baz])
      @classifier.train!('A', %w[foo foo baz])
      @classifier.train!('B', %w[bar bar baz])
      @classifier.train!('C', %w[baz baz baz foo])
    end

    it 'trains' do
      expect(@redis.get('samples:total').to_i).to eq(4)
      expect(@redis.hget('samples', 'A').to_i).to eq(2)
      expect(@redis.hget('samples', 'B').to_i).to eq(1)
      expect(@redis.hget('samples', 'C').to_i).to eq(1)
      expect(@redis.get('tokens:total').to_i).to eq(13)
      expect(@redis.get('tokens:A:total').to_i).to eq(6)
      expect(@redis.get('tokens:B:total').to_i).to eq(3)
      expect(@redis.get('tokens:C:total').to_i).to eq(4)
      expect(@redis.zscore('tokens:A', 'foo').to_i).to eq(3)
      expect(@redis.zscore('tokens:A', 'bar').to_i).to eq(1)
      expect(@redis.zscore('tokens:A', 'baz').to_i).to eq(2)
      expect(@redis.zscore('tokens:B', 'bar').to_i).to eq(2)
      expect(@redis.zscore('tokens:B', 'baz').to_i).to eq(1)
      expect(@redis.zscore('tokens:C', 'baz').to_i).to eq(3)
      expect(@redis.zscore('tokens:C', 'foo').to_i).to eq(1)
    end

    it 'classifies' do
      classify(%w[bar baz])
      expect(@scores['B']).to be > @scores['A']

      classify(%w[foo baz])
      expect(@scores['A']).to be > @scores['B']

      classify(%w[quux])
      expect(@scores['A']).to be > @scores['B']
    end

    it 'classifies against specific languages' do
      classify(%w[foo bar baz], ['A', 'C'])
      expect(@scores.keys).to eq(['A', 'C'])
    end

    it 'prunes' do
      @classifier.prune!
      expect(@redis.get('tokens:total').to_i).to eq(10)
      expect(@redis.get('tokens:A:total').to_i).to eq(5)
      expect(@redis.zcard('tokens:A')).to eq(2)
      expect(@redis.get('tokens:B:total').to_i).to eq(2)
      expect(@redis.zcard('tokens:B')).to eq(1)
      expect(@redis.get('tokens:C:total').to_i).to eq(3)
      expect(@redis.zcard('tokens:C')).to eq(1)
    end

    it 'prunes specific languages' do
      @classifier.prune!(['A', 'B'])
      expect(@redis.get('tokens:total').to_i).to eq(11)
      expect(@redis.get('tokens:C:total').to_i).to eq(4)
    end
  end

  it 'classifies nothing' do
    classify([])
    expect(@scores).to be_empty
  end
end
