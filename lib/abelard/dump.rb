#!/usr/bin/env ruby

require 'abelard/dir.rb'

dir = Directory.new(ARGV[0])
puts dir.posts_feed.to_s
