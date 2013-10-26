#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'dirt/tokenizer'
require 'dirt/classifier'

puts ARGV.join(' ')
Dirt::Classifier.new.train!(ARGV.shift, Dirt::Tokenizer.new(ARGF.read).tokenize)
