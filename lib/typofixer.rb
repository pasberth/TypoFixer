#!/usr/bin/env ruby
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module TypoFixer
  VERSION = "0.0.1"
end

require 'typofixer/typotracker'
