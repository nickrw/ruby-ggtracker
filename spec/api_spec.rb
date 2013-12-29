require_relative 'spec_helper'

describe GGTracker::API do

  describe "#identity" do

    before :each do
      @identity = GGTracker::API.identity(1031800)
    end

    it "should return an Identity" do
      @identity.should be_instance_of GGTracker::Identity
    end

    it "should have a matching entity ID" do
      @identity.id.should be == 1031800
    end

    it "should have a matching player name to the mock json" do
      @identity.name.should be == "Gingernut"
    end

  end

  describe "#single_match" do

    before :each do
      @match = GGTracker::API.single_match(4367315)
    end

    it "should return a Match" do
      @match.should be_instance_of GGTracker::Match
    end

    it "should have a matching entity ID" do
      @match.id.should be == 4367315
    end

  end

  describe "#matches" do

    before :each do
      @results = GGTracker::API.matches(1031800)
    end

    it "should count 177" do
      @results.count.should be == 177
    end

    it "should have constructed a Match for the first item" do
      @results[0].should be_instance_of GGTracker::Match
    end

    it "should be able to fetch an item on page 2" do
      @results[10].should be_instance_of GGTracker::Match
    end

    it "should fetch different matches when game_type changes" do
      ffas = GGTracker::API.matches(1031800, false, "FFA")
      ffas.should be_instance_of GGTracker::API::PaginatedResults
      ffas[0].should be_instance_of GGTracker::Match
    end

  end

end
