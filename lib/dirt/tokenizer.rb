# Based on https://github.com/github/linguist/blob/master/lib/linguist/tokenizer.rb
require 'strscan'

module Dirt
  class Tokenizer < StringScanner
    def tokenize
      tokens = Array.new
      until eos?
        if token = scan_token
          tokens << token
        else
          getch
        end
      end
      tokens
    end

    def scan_token
      if shebang = scan_shebang
        return shebang
      end

      # Skip comments
      scan(%r"\s*(//|#).*") # Line
      scan(%r"/\*.*\*/"m)   # Java/C
      scan(/<!--.*-->/m)    # XML/HTML
      scan(/{-.*-}/m)       # Haskell
      scan(/\(\*.*\*\)/m)   # Coq/SML
      scan(/""".*"""/m)     # Python

      # Skip strings
      scan(/".*[^\\]"/)
      scan(/'.*[^\\]'/)

      # Skip numbers
      scan(/0x\h+/)
      scan(/\d+(\.\d*)?/)

      return scan(/[,.:;{}()\[\]]/) || # Punctuation
        scan(/[\w@$][\w!?']*/) ||      # Regular tokens
        scan(/[=<>+*\/%^&|!-]+/)       # Operators
    end

    # Removes /usr/bin/env and trailing number (e.g. python3 -> python)
    def scan_shebang
      if shebang = scan(/^#!.+$/)
        parts = shebang.split(' ')
        script = parts.first.split('/').last
        script = parts[1] if script == 'env' && parts[1]
        '#!' + script[/\D+/]
      end
    end
  end
end

if __FILE__ == $0
  puts Dirt::Tokenizer.new(ARGF.read).tokenize.join(' ')
end
