require_relative 'spec_helper'

describe GGTracker::InternalLadder do

  before :all do
    @team = [
      GGTracker::Identity.factory(1031800),
      GGTracker::Identity.factory(1161842),
      GGTracker::Identity.factory(1313010)
    ]
    @blacklist = {
      :p0v1      => 4235830, # player 0 vs player 1
      :p0v2      => 4235828, # player 0 vs player 2
      :p0v2_seed => 4235828, # player 0 vs player 2 (player 2's seed match)
      :p1v2      => 4367027, # player 1 vs player 2
    }
    @orig_ladder = GGTracker::InternalLadder.new('1v1', *@team)
    # any new games after these tests were written will
    # cause the ladder to change to change, so blacklist them.
    @orig_ladder.blacklist_after(Time.parse('2014-01-01'))
    @orig_ladder.automatic
  end

  before :each do
    @ladder = @orig_ladder.dup
  end

  describe "#ladder" do

    it "has correct player scores" do
      @ladder.players[@team[0]][:ranked].rank.should == 1174
      @ladder.players[@team[1]][:ranked].rank.should == 1306
      @ladder.players[@team[2]][:ranked].rank.should == 1120
    end

    it "sorts correctly" do
      @ladder.ladder.should == [
        @ladder.players[@team[1]][:ranked],
        @ladder.players[@team[0]][:ranked],
        @ladder.players[@team[2]][:ranked]
      ]
    end

    it "has correct ladder count" do
      @ladder.matches.count.should == 13
    end

  end

  describe "#blacklist_time_range" do

    before :each do
      @ladder.blacklist_before(Time.parse('2013-10-01'))
    end

    it "has correct player scores" do
      @ladder.players[@team[0]][:ranked].rank.should == 1186
      @ladder.players[@team[1]][:ranked].rank.should == 1295
      @ladder.players[@team[2]][:ranked].rank.should == 1119
    end

    it "sorts correctly" do
      @ladder.ladder.should == [
        @ladder.players[@team[1]][:ranked],
        @ladder.players[@team[0]][:ranked],
        @ladder.players[@team[2]][:ranked]
      ]
    end

    it "has correct ladder count" do
      @ladder.matches.count.should == 10
    end

  end

end
