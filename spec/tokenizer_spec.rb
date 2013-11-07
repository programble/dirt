require 'dirt/tokenizer'

describe Dirt::Tokenizer do
  def scan_shebang(s)
    described_class.new(s).scan_shebang
  end

  def tokenize(s)
    @tokens = Set.new(described_class.new(s).tokenize.keys)
  end

  it 'scans shebangs' do
    expect(scan_shebang('#!/bin/bash')).to eq('#!bash')
    expect(scan_shebang('#!/usr/bin/ruby')).to eq('#!ruby')
    expect(scan_shebang('#!/usr/bin/env ruby')).to eq('#!ruby')
    expect(scan_shebang('#!/usr/bin/python3')).to eq('#!python')
    expect(scan_shebang('#!/usr/bin/env python3')).to eq('#!python')
  end

  it 'tokenizes shebangs' do
    tokenize('#!/usr/bin/env ruby')
    expect(@tokens).to eq(Set['#!ruby'])
  end

  it 'skips whitespace' do
    tokenize(" \t\n ")
    expect(@tokens).to be_empty
  end

  it 'skips line comments' do
    %w[# // /// ; ;; -- ! "].each do |c|
      tokenize("#{c} foo")
      expect(@tokens).to be_empty

      tokenize("foo #{c} bar")
      expect(@tokens).to eq(Set['foo'])

      tokenize("#{c} foo\nbar")
      expect(@tokens).to eq(Set['bar'])

      tokenize("foo #{c} bar\nbaz")
      expect(@tokens).to eq(%w[foo baz].to_set)

      tokenize("#{c} foo\n#{c} bar\nbaz")
      expect(@tokens).to eq(Set['baz'])
    end
  end

  it 'skips block comments' do
    {
      '/*'   => '*/',
      '<!--' => '-->',
      '{-'   => '-}',
      '(*'   => '*)',
      '"""'  => '"""',
      '--[[' => ']]',
      '#|'   => '|#'
    }.each do |o, c|
      tokenize("#{o} foo\nbar #{c}")
      expect(@tokens).to be_empty

      tokenize("#{o} foo #{c} bar #{o} baz #{c}")
      expect(@tokens).to eq(Set['bar'])
    end
  end

  it 'skips strings' do
    tokenize(%q['' a "" b 'foo' c "bar" d '\'' e "\"" f])
    expect(@tokens).to eq('abcdef'.chars.to_set)
  end

  it 'skips numbers' do
    tokenize('0xFF a 1 b 1.0 c 1. d')
    expect(@tokens).to eq('abcd'.chars.to_set)
  end

  it 'tokenizes regular tokens' do
    str = "foo bar baz foo! foo? foo' foo= @foo $foo foo-bar"
    tokenize(str)
    expect(@tokens).to eq(str.split.to_set)
  end

  it 'tokenizes SGML tags' do
    tokenize('<span>foo</span>')
    expect(@tokens).to eq(%w[<span> foo </span>].to_set)

    tokenize('<span class="foo">bar</span>')
    expect(@tokens).to eq(%w[<span class= > bar </span>].to_set)
  end

  it 'tokenizes punctuation' do
    tokenize(',.:;{}()[]')
    expect(@tokens).to eq(%w", . : ; { } ( ) [ ]".to_set)
  end

  it 'tokenizes operators' do
    # HACK: ! with a space following would be a Factor line comment
    str = "= == != /= ++ += -= *= %= > < >= <= + - * / % >> << ^ & | !\e&& || --"
    tokenize(str)
    expect(@tokens).to eq(str.split(/[\s\e]/).to_set)
  end
end
