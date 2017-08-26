Gem::Specification.new do |s|
  s.name          = 'abelard'
  s.version       = '0.0.2'
  s.date          = '2017-08-26'
  s.summary       = 'Abelard blog archiver'
  s.description   = %q{Persist blogs and similar web content as sharable git repositories}
  s.authors       = ["Anomaly UK"]
  s.email         = 'anomalyuk@tesco.net'
  s.files         = [ 'lib/abelard/archive.rb', 'lib/abelard/dir.rb', 'lib/abelard/postxml.rb', 'lib/abelard/dump.rb', 'lib/abelard/load.rb', 'lib/abelard/list.rb', 'lib/abelard/web.rb', 'lib/abelard/history.rb' ]
  s.executables   = [ 'abelard' ]
  s.homepage      = 'http://anomalyuk.blogspot.com/'
  s.license       = 'GPL-2.0'

  s.add_runtime_dependency "rugged",
                           ["~>0.23"]
end
