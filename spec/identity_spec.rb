require_relative 'spec_helper'

describe GGTracker::Identity do

  before :each do
    @identity = GGTracker::API.identity(1031800)
    @match_won = GGTracker::API.single_match(4384439)
    @match_lost = GGTracker::API.single_match(4447486)
  end

  describe "API call" do
    it "returns an Identity" do
      @identity.should be_an_instance_of GGTracker::Identity
    end
  end

  describe "#new" do
    it "should not be called twice with the same ID" do
      expect {
        GGTracker::Identity.new(@identity.data)
      }.to raise_error ArgumentError
    end
  end

  describe "#factory" do

    it "returns the same object we took from the API" do
      GGTracker::Identity.factory(1031800).should equal @identity
    end

    it "can't locate a non-existent ID" do
      GGTracker::Identity.factory(0).should be nil
    end

  end

  describe "#<<" do

    before :each do
      @player_in_match = @identity
      @player_not_in_match = GGTracker::API.identity(1161842)
      @match = GGTracker::API.single_match(4384439)
    end

    it "raises an exception when not passed a Match object" do
      expect {
        @identity << "string"
      }.to raise_error ArgumentError
    end

    it "has tied the Match object to the identity upon creation" do
      @player_in_match.matches.include?(@match).should be true
    end

    it "raises an exception when passed a Match not involving self" do
      expect {
        @player_not_in_match << match
      }.to raise_error ArgumentError
    end

  end

  require 'pp'
  describe "#versus*" do
    before :each do
      @opponent = @match_won.teams[2][0]
    end

    it "selects only matches versus our opponent" do
      @identity.versus(@opponent).should be == [@match_won]
    end

    it "applies a filter block appropriately" do
      @identity.versus(@opponent) { |x| true }.should be == [@match_won]
      @identity.versus(@opponent) { |x| false }.should be == []
    end

    it "is filterable on victory/defeat" do
      @identity.wins_versus(@opponent).should be == [@match_won]
      @identity.losses_versus(@opponent).should be == []
    end

  end

  describe "#wins and #losses" do
    it "correctly identifies the matches" do
      @identity.wins.include?(@match_won).should be true
      @identity.wins.include?(@match_lost).should be false
      @identity.losses.include?(@match_won).should be false
      @identity.losses.include?(@match_lost).should be true
    end
  end

end
