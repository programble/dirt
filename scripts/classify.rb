#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'dirt/tokenizer'
require 'dirt/classifier'

puts Dirt::Classifier.new.classify(Dirt::Tokenizer.new(ARGF.read).tokenize).take(5)
