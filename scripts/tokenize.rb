#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'dirt/tokenizer'

puts Dirt::Tokenizer.new(ARGF.read).tokenize.join(' ')
