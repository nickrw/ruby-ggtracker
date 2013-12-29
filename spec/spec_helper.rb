
# Use webmock to provide stub ggtracker API endpoints
require 'webmock/rspec'

# The directory which we store our mock API response json blobs
$mock_path = File.expand_path(File.join(File.dirname(__FILE__), "mock"))

# Put ../lib on our load path and pull in ggtracker for testing
$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
require 'ggtracker'

module GGTracker
  def self.vardir
    File.expand_path(File.dirname(__FILE__))
  end
  def self.cachettl
    Float::INFINITY
  end
end
GGTracker.ensure_vardir
WebMock.disable_net_connect!
