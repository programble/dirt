# Based on https://github.com/github/linguist/blob/master/lib/linguist/tokenizer.rb
#
# Copyright (c) 2011-2013 GitHub, Inc.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

require 'strscan'

module Dirt
  class Tokenizer < StringScanner
    def initialize(string)
      super("\n" + string) # HACK: So that line comments on first line match
    end

    def tokenize
      tokens = Hash.new(0)
      until eos?
        if token = scan_token
          tokens[token] += 1
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
      scan(%r"(\s+(/{2,}|#+|;+|-{2,}) [^\n]*)+"m) # Java/C, Ruby/Shell, Lisp, Haskell

      scan_block_comment(%r"/\*", %r"\*/") # Java/C
      scan_block_comment(/<!--/, /-->/)    # XML/HTML
      scan_block_comment(/{-/, /-}/)       # Haskell
      scan_block_comment(/\(\*/, /\*\)/)   # Coq/SML
      scan_block_comment(/"""/, /"""/)     # Python
      scan_block_comment(/--\[\[/, /\]\]/) # Lua
      scan_block_comment(/#\|/, /\|#/)     # Common Lisp

      # Skip strings
      scan(/''|""/) # Empty strings
      skip_until(/[^\\]'/) if scan(/'/)
      skip_until(/[^\\]"/) if scan(/"/)

      # Skip numbers
      scan(/0x\h+/)
      scan(/\d+(\.\d*)?/)

      return scan(/[,.:;{}()\[\]]/) || # Punctuation
        scan(%r"</?\w+>?") ||          # SGML tags
        scan(/[\w@$][\w-]*[!?'=]?/) || # Regular tokens
        scan(/[=<>+*\/%^&|!\\-]+/)     # Operators
    end

    # Removes /usr/bin/env and trailing number (e.g. python3 -> python)
    def scan_shebang
      if shebang = scan(/\n#!.+$/)
        parts = shebang.split(' ')
        script = parts.first.split('/').last
        script = parts[1] if script == 'env' && parts[1]
        '#!' + script[/\D+/]
      end
    end

    def scan_block_comment(open, close)
      skip_until(close) if scan(open)
    end
  end
end
