require_relative 'spec_helper'

describe GGTracker::Match do

  before :each do
    @match1 = GGTracker::API.single_match(4384439)
    @match2 = GGTracker::API.single_match(4367315)
    @identity = GGTracker::API.identity(1031800)
  end

  describe "#new" do
    it "returns a Match object" do
      @match1.should be_an_instance_of GGTracker::Match
      @match2.should be_an_instance_of GGTracker::Match
    end
  end

  describe "#teams" do

    it "returns a match ID" do
      @match1.id.should be_an_instance_of Fixnum
      @match1.id.should be > 0
      @match2.id.should be_an_instance_of Fixnum
      @match2.id.should be > 0
    end

    it "assembles an array of teams" do
      @match1.teams.count.should be == 2
      @match2.teams.count.should be == 2
    end

    it "has one player in each match1 team" do
      # Teams are not zero indexed, as they are match team numbers
      # as hash keys, not array elements.
      @match1.teams[1].count.should be == 1
      @match1.teams[2].count.should be == 1
    end

    it "has three players in each match2 team" do
      @match2.teams[1].count.should be == 3
      @match2.teams[2].count.should be == 3
    end

    it "has same Identity objects for a player in different matches" do
      @match1.teams[1][0].should equal @match2.teams[1][1]
    end

  end

  describe "#player?" do
    it "correctly determines player membership of a match" do
      player = @match1.teams[1][0]
      @match1.player?(player).should be true
    end
  end

  describe "#opponents?" do

    it "correctly determines if two players are opponents" do
      player1 = @match1.teams[1][0]
      player2 = @match1.teams[2][0]
      @match1.opponents?(player1, player2).should be true
    end

    it "correctly determines when two players are on the same team" do
      player1 = @match2.teams[1][0]
      player2 = @match2.teams[1][1]
      @match2.opponents?(player1, player2).should be false
    end

    it "returns nil when a given player wasn't part of the match" do
      @match2.opponents?(@match1.teams[2][0], @match2.teams[1][0])
    end

    it "understands how FFAs work" do
      ffa = GGTracker::API.single_match(4428085)
      player1 = ffa.teams[1][0]
      player2 = ffa.teams[2][0]
      player3 = ffa.teams[3][0]
      player4 = ffa.teams[4][0]
      ffa.opponents?(player1, player2, player3).should be true
      ffa.opponents?(player1, player2, player3, player4).should be true
      ffa.opponents?(player1, player3).should be true
      ffa.opponents?(@match1.teams[2][0], player2).should be nil
    end

  end

  describe "#winners" do
    it "returns an array of winner(s)" do
      @match1.winners.should be == [@identity]
      @match2.winners.should be == @match2.teams[1]
    end
  end

  describe "#losers" do
    it "should return an array of losers" do
      @match1.losers.should be == @match1.teams[2]
      @match2.losers.should be == @match2.teams[2]
    end
  end

  describe "#won?" do
    it "should return true for a match winner" do
      @match1.won?(@identity).should be true
      @match2.won?(@identity).should be true
    end
    it "should return false for a match loser" do
      @match1.won?(@match1.teams[2][0]).should be false
      @match2.won?(@match2.teams[2][0]).should be false
    end
  end

  describe "#lost?" do
    it "should return false for a match winner" do
      @match1.lost?(@identity).should be false
      @match2.lost?(@identity).should be false
    end
    it "should return true for a match loser" do
      @match1.lost?(@match1.teams[2][0]).should be true
      @match2.lost?(@match2.teams[2][0]).should be true
    end
  end

end
