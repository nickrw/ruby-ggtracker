require 'json'
require 'httparty'
require 'ggtracker/match'
require 'ggtracker/identity'
require 'ggtracker/api'

module GGTracker

  def self.vardir
    File.join(Dir.home, ".ggtracker")
  end

  def self.cachettl
    43200 # 12 hours
  end

  def self.ensure_vardir
    base = vardir
    expect_dirs = [base, File.join(base, "api-cache")]
    expect_dirs.each do |dir|
      if not Dir.exists?(dir)
        Dir.mkdir(dir, 0755)
      end
    end
  end

end

GGTracker.ensure_vardir
