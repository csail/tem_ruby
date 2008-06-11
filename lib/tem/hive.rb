require 'rubygems'
require 'fileutils'

# The TEM's configuation hive
module Tem::Hive
  @@hive_dir = File.join(Gem.user_home, ".tem")
  
  def self.path_to(*hive_entry)
    File.join(@@hive_dir, *hive_entry)
  end
    
  def self.create(*hive_entry)
    path = File.join(@@hive_dir, *hive_entry)
    FileUtils.mkdir_p File.dirname(path)
    File.open(path, "w") { |f| }
    return path
  end
end
