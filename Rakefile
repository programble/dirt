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

desc 'Tokenize a file or standard input'
task :tokenize, [:file] do |t, args|
  f = args.file ? File.open(args.file) : $stdin
  puts Dirt::Tokenizer.new(f.read).tokenize.join(' ')
end

desc 'Train classifier with files'
task :train, [:language, :files] do |t, args|
  classifier = Dirt::Classifier.new
  files = FileList[args.files, *args.extras]
  files.each_with_index do |file, i|
    puts "#{i + 1}/#{files.length} #{args.language} #{file}"
    begin
      tokens = Dirt::Tokenizer.new(File.read(file)).tokenize
      classifier.train!(args.language, tokens)
    rescue StandardError => e
      puts e
    end
  end
end

desc 'Classify a file or standard input'
task :classify, [:file] do |t, args|
  f = args.file ? File.open(args.file) : $stdin
  scores = Dirt::Classifier.new.classify(Dirt::Tokenizer.new(f.read).tokenize)
  puts scores.sort_by {|l, s| -s }.map {|l, s| l }.take(10)
end
