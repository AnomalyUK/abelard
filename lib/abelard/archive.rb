require 'yaml'

class Archive
  def initialize(file)
    @configfile = file
    @config = YAML.load_file(file)
  end

  def dir(blog)
    Directory.new(@config[blog]["dest"])
  end

  def available
    @config.keys
  end

end
