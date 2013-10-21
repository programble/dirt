require 'dirt/tokenizer'

describe Dirt::Tokenizer do
  def scan_shebang(s)
    described_class.new(s).scan_shebang
  end

  def tokenize(s)
    described_class.new(s).tokenize
  end

  it 'scans shebangs' do
    scan_shebang('#!/bin/bash').should == '#!bash'
    scan_shebang('#!/usr/bin/ruby').should == '#!ruby'
    scan_shebang('#!/usr/bin/env ruby').should == '#!ruby'
    scan_shebang('#!/usr/bin/python3').should == '#!python'
    scan_shebang('#!/usr/bin/env python3').should == '#!python'
  end

  it 'tokenizes shebangs' do
    tokenize('#!/usr/bin/env ruby').should == ['#!ruby']
  end

  it 'skips whitespace' do
    tokenize(" \t\n ").should == []
  end

  it 'skips line comments' do
    %w[# // ;; --].each do |c|
      tokenize("#{c} foo").should == []
      tokenize("foo #{c} bar").should == ['foo']
      tokenize("#{c} foo\nbar").should == ['bar']
      tokenize("foo #{c} bar\nbaz").should == ['foo', 'baz']
    end
  end

  it 'skips block comments' do
    {'/*' => '*/', '<!--' => '-->', '{-' => '-}', '(*' => '*)',
     '"""' => '"""'}.each do |o, c|
      tokenize("#{o} foo\nbar #{c}").should == []
      tokenize("#{o} foo #{c} bar #{o} baz #{c}").should == ['bar']
    end
  end

  it 'skips strings' do
    tokenize(%q['' a "" b 'foo' c "bar" d '\'' e "\"" f]).should == 'abcdef'.chars
  end

  it 'skips numbers' do
    tokenize('0xFF a 1 b 1.0 c 1. d').should == 'abcd'.chars
  end

  it 'tokenizes regular tokens' do
    tokenize('foo bar baz').should == %w[foo bar baz]
    tokenize("foo! foo? foo'").should == %w[foo! foo? foo']
    tokenize('@foo $foo').should == %w[@foo $foo]
  end

  it 'tokenizes punctuation' do
    tokenize(',.:;{}()[]').should == %w", . : ; { } ( ) [ ]"
  end

  it 'tokenizes operators' do
    tokenize('= == != =/=').should == %w[= == != =/=]
    tokenize('++ 0-- += -= *= /= %= =/=').should == %w[++ -- += -= *= /= %= =/=]
    tokenize('> < >= <=').should == %w[> < >= <=]
    tokenize('+ - * / %').should == %w[+ - * / %]
    tokenize('>> << ^ & |').should == %w[>> << ^ & |]
    tokenize('! && ||').should == %w[! && ||]
  end
end
