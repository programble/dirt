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
    end

    it 'trains' do
      expect(@redis.get('samples:total').to_i).to eq(3)
      expect(@redis.hget('samples', 'A').to_i).to eq(2)
      expect(@redis.hget('samples', 'B').to_i).to eq(1)
      expect(@redis.get('tokens:total').to_i).to eq(9)
      expect(@redis.get('tokens:A:total').to_i).to eq(6)
      expect(@redis.get('tokens:B:total').to_i).to eq(3)
      expect(@redis.zscore('tokens:A', 'foo').to_i).to eq(3)
      expect(@redis.zscore('tokens:A', 'bar').to_i).to eq(1)
      expect(@redis.zscore('tokens:A', 'baz').to_i).to eq(2)
      expect(@redis.zscore('tokens:B', 'bar').to_i).to eq(2)
      expect(@redis.zscore('tokens:B', 'baz').to_i).to eq(1)
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
  end

  it 'classifies nothing' do
    classify([])
    expect(@scores).to be_empty
  end
end
