#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'dirt/tokenizer'
require 'dirt/classifier'

classifier = Dirt::Classifier.new

%x[git clone https://github.com/github/linguist.git /tmp/linguist]

Dir.foreach('/tmp/linguist/samples') do |d|
  next if d.start_with? '.'
  lang = d
  d = File.join('/tmp/linguist/samples', d)
  next unless File.directory? d
  Dir.foreach(d) do |f|
    next if f.start_with? '.'
    f = File.join(d, f)
    next unless File.file? f
    puts "#{lang} #{f}"
    begin
      classifier.train!(lang, Dirt::Tokenizer.new(File.read(f)).tokenize)
    rescue StandardError => e
      puts e
    end
  end
end

%x[rm -rf /tmp/linguist]
