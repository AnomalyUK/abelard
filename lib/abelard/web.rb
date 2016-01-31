#!/usr/bin/env ruby
require 'sinatra/base'
require 'yaml'
require 'abelard/dir.rb'
require 'abelard/archive.rb'

CONFIG_FILE="blogfeeds.yaml"



class FeedServer < Sinatra::Base
archive = Archive.new(CONFIG_FILE)
set :bind, "0.0.0.0"

get '/' do
  template = <<ERB
<html><body><h2>Feeds</h2><dl>
<% archive.available.each do |blog| %>
<dt><%= blog %></dt>
<dd><%= archive.dir(blog).info["title"] %></dd>
<dd><a href="/<%= blog %>/posts">posts</a></dd>
<% end %>
</dl></body></html>
ERB
  erb template, :locals => { :archive => archive }
end

get '/*/posts' do |blog|
  headers "Content-Type" => "application/atom+xml"
  archive.dir(blog).posts_feed.to_s
end
  
run!
end

