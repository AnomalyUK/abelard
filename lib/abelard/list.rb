#!/usr/bin/env ruby

require 'yaml'
require 'abelard/dir.rb'
CONFIG_FILE = "blogfeeds.yaml"

dest=''
if ARGV.length > 0 then
  if (ARGV[0] == '-h') then
    $stderr.puts("abelard list -d <dir>\nabelard list <config-entry>
abelard list\n")
  else  
    if (ARGV[0] == '-d') then
      dest = ARGV[1]
    else
      configs = YAML.load_file(CONFIG_FILE)
      conf = configs[ARGV[0]]
    dest = conf['dest']
    end
    dir = Directory.new(dest)
    dir.each do |item|
      printf("%s %s\n", item.timestamp.strftime("%Y-%m-%d"), item.title)
    end
  end
else
  configs = YAML.load_file(CONFIG_FILE)
  configs.each do |name, conf|
    puts("#{name}: #{conf['urls'].first}")
  end
end

