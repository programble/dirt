require 'bundler/setup'
require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
  spec.rspec_opts = ['--color', '--require spec_helper']
end

task :default => :spec

$LOAD_PATH.unshift('lib')
require 'dirt/tokenizer'
require 'dirt/classifier'

def train(language, *globs)
  @classifier ||= Dirt::Classifier.new

  files, i = FileList[*globs], 0
  files.each_slice(100) do |slice|
    i += slice.length
    puts "#{language}\t\t#{i}/#{files.length}"

    tokens = slice.map do |file|
      begin
        Dirt::Tokenizer.new(File.read(file)).tokenize
      rescue StandardError => e
        puts "#{file}: #{e}"
        {}
      end
    end.reduce(Hash.new(0)) do |sum, sample_tokens|
      sample_tokens.each {|t, c| sum[t] += c }
      sum
    end

    @classifier.train!(language, tokens, slice.length)
  end
end

desc 'Tokenize a file or standard input'
task :tokenize, [:file] do |t, args|
  f = args.file ? File.open(args.file) : $stdin
  Dirt::Tokenizer.new(f.read).tokenize.sort_by {|_, c| -c }.each do |token, count|
    puts "#{count} #{token}"
  end
end

desc 'Train classifier with files'
task :train, [:language, :files] do |t, args|
  Dirt::Mongo.connect!
  train(t.language, t.files, *t.extras)
end

desc 'Prune classifier'
task :prune do |t|
  Dirt::Mongo.connect!
  Dirt::Classifier.new.prune!
end

desc 'Classify a file or standard input'
task :classify, [:file] do |t, args|
  Dirt::Mongo.connect!
  f = args.file ? File.open(args.file) : $stdin
  scores = Dirt::Classifier.new.classify(Dirt::Tokenizer.new(f.read).tokenize)
  puts scores.sort_by {|l, s| -s }.map {|l, s| l }.take(10)
end

require 'yaml'

samples = YAML.load_file('samples.yml')

samples.each do |language, struct|
  lang_path = "samples/#{language}"

  glob = struct['glob']
  glob = [glob] unless glob.is_a? Array
  glob.map! {|g| "samples/#{language}/**/#{g}" }

  struct['git'].each do |repo|
    path = "#{lang_path}/#{repo.split('/').last}"

    file path do |t|
      sh "git clone --depth 1 #{repo} '#{path}'"
    end

    task :samples => [path]
    task lang_path => [path]
  end

  task lang_path do |t|
    Dirt::Mongo.connect!
    train(language, *glob)
  end

  multitask 'samples/all' => [lang_path]
end

desc 'Train classifier with all samples'
task :samples => ['samples/all']

desc 'Remove samples'
task :clean do |t|
  rm_rf 'samples'
end
