#!/usr/bin/env ruby

require 'abelard/dir.rb'

dir = Directory.new(ARGV[0])
dir.each do |item|
  printf("%s %s\n", item.timestamp.strftime("%Y-%m-%d"), item.title)
end
