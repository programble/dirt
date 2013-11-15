require 'dirt/classifier'

describe Dirt::Classifier do
  before do
    @mongo = Mongo::MongoClient.new
    @db = @mongo.db
    @mongo.drop_database(@db.name)

    @classifier = described_class.new(@mongo)
  end

  def classify(*args)
    @scores = @classifier.classify(*args)
  end

  context 'with training' do
    before do
      @classifier.train!('A', 'foo' => 1, 'bar' => 1, 'baz' => 1)
      @classifier.train!('A', 'foo' => 2, 'baz' => 1)
      @classifier.train!('B', 'bar' => 2, 'baz' => 1)
      @classifier.train!('C', 'baz' => 3, 'foo' => 1)
    end

    it 'trains' do
      totals = @db['totals'].find_one
      expect(totals['samples']).to eq(4)
      expect(totals['tokens']).to eq(13)

      language_A = @db['languages'].find_one({'name' => 'A'})
      language_B = @db['languages'].find_one({'name' => 'B'})
      language_C = @db['languages'].find_one({'name' => 'C'})

      expect(language_A['samples']).to eq(2)
      expect(language_B['samples']).to eq(1)
      expect(language_C['samples']).to eq(1)

      expect(language_A['tokens']).to eq(6)
      expect(language_B['tokens']).to eq(3)
      expect(language_C['tokens']).to eq(4)

      expect(@db['tokens'].find_one({'language_id' => language_A['_id'],
                                     'token' => 'foo',
                                     'count' => 3})).to be_a(Hash)
      expect(@db['tokens'].find_one({'language_id' => language_A['_id'],
                                     'token' => 'bar',
                                     'count' => 1})).to be_a(Hash)
      expect(@db['tokens'].find_one({'language_id' => language_A['_id'],
                                     'token' => 'baz',
                                     'count' => 2})).to be_a(Hash)

      expect(@db['tokens'].find_one({'language_id' => language_B['_id'],
                                     'token' => 'bar',
                                     'count' => 2})).to be_a(Hash)
      expect(@db['tokens'].find_one({'language_id' => language_B['_id'],
                                     'token' => 'baz',
                                     'count' => 1})).to be_a(Hash)

      expect(@db['tokens'].find_one({'language_id' => language_C['_id'],
                                     'token' => 'baz',
                                     'count' => 3})).to be_a(Hash)
      expect(@db['tokens'].find_one({'language_id' => language_C['_id'],
                                     'token' => 'foo',
                                     'count' => 1})).to be_a(Hash)
    end

    it 'classifies' do
      classify('bar' => 1, 'baz' => 1)
      expect(@scores['B']).to be > @scores['A']

      classify('foo' => 1, 'baz' => 1)
      expect(@scores['A']).to be > @scores['B']

      classify('quux' => 1)
      expect(@scores['A']).to be > @scores['B']
    end

    it 'prunes' do
      @classifier.prune!

      expect(@db['totals'].find_one['tokens']).to eq(10)

      language_A = @db['languages'].find_one({'name' => 'A'})
      language_B = @db['languages'].find_one({'name' => 'B'})
      language_C = @db['languages'].find_one({'name' => 'C'})

      expect(language_A['tokens']).to eq(5)
      expect(language_B['tokens']).to eq(2)
      expect(language_C['tokens']).to eq(3)

      expect(@db['tokens'].find(
        {'language_id' => language_A['_id']}).count).to eq(2)
      expect(@db['tokens'].find(
        {'language_id' => language_B['_id']}).count).to eq(1)
      expect(@db['tokens'].find(
        {'language_id' => language_C['_id']}).count).to eq(1)
    end
  end

  it 'classifies nothing' do
    classify([])
    expect(@scores).to be_empty
  end
end
