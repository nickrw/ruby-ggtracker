require 'ggtracker/identity'
require 'ggtracker/match'
require 'set'

module GGTracker

  class InternalLadder

    attr_reader :matches, :players

    def initialize(type=:all, *players)
      @type = type
      @player_set = players.sort.uniq.to_set
      @matches = []
      @autoblock = nil
      reset_ranks
    end

    def automatic
      manual if not @autoblock.nil?
      self.matches = GGTracker::Match.cache.values
      @autoblock = lambda { |m| play(m) }
      GGTracker::Match.subscribe(&@autoblock)
    end

    def manual
      if not @autoblock.nil?
        GGTracker::Match.unsubscribe(&@autoblock)
      end
    end

    def add_player(identity)
      @player_set << identity
      recalculate!
    end

    def remove_player(identity)
      @player_set.delete(identity)
      @players.delete(identity)
      revalidate!
    end

    def change_type(new_type)
      @type = new_type
      recalculate!
    end

    def matches=(replacement_matches)
      @matches = []
      replacement_matches.delete_if { |m| not valid_match?(m) }
      @matches = replacement_matches
      recalculate!
      @matches
    end

    def revalidate!
      original_matches = @matches
      replacement_matches = @matches
      @matches = []
      replacement_matches.delete_if { |m| not valid_match?(m) }
      @matches = replacement_matches
      recalculate! if @matches != original_matches
    end

    def play(new_match)
      if new_match.class == Array
        self.matches = @matches + new_match
      elsif new_match.class == GGTracker::Match
        return false if not valid_match?(new_match)
        if valid_to_append?(new_match)
          append(new_match)
        else
          insert(new_match)
        end
      end
    end

    def <<(match)
      play(match)
    end

    def ladder(asc=false)
      ranked = []
      @players.values.each do |player|
        ranked << player[:ranked]
      end
      ranked.sort{ |a,b| (asc ? a : b) <=> (asc ? b : a) }
    end

    private

    def valid_match?(m)
      if m.class != GGTracker::Match
        raise ArgumentError, "expecting a GGTracker::Match object"
      end

      # We already know about this match, so don't want to apply it again
      return false if @matches.include?(m)

      # We are not interested in actual sc2 ladder games,
      # an internal ladder can only be comprised of custom games
      return false if m.ladder

      # We are only interested in games of the specified ladder type
      if @type != :all
        return false if @type != m.type and @type != :all
      end

      # Discount the game if it involves any players not in our player list
      return false if not m.players.subset?(@player_set)

      # LGTM
      return true
    end

    def youngest
      if @matches[-1].class == GGTracker::Match
        @matches[-1].ts
      else
        Time.at(0)
      end
    end

    def reset_ranks
      @players = {}
      @player_set.each do |player_id|
        @players[player_id] = {
          :ranked => RankedIdentity.new(player_id),
          :change => {}
        }
      end
    end

    def recalculate!
      @matches.sort!
      @matches.uniq!
      reset_ranks
      @matches.each do |match|
        apply_match_delta(match)
      end
    end

    def apply_match_delta(match)
      prev_ranks = Hash[match.players.map { |p| [p, @players[p][:ranked].rank] }]
      match.winners.each do |winner|
        @players[winner][:ranked].win_match
        match.losers.each do |loser|
          @players[winner][:ranked].win_vs(@players[loser][:ranked])
        end
      end
      match.losers.each do |loser|
        @players[loser][:ranked].lose_match
      end
      prev_ranks.each do |player, oldrank|
        @players[player][:change][match] = {
          :oldrank  => oldrank,
          :newrank  => @players[player][:ranked].rank,
          :seeded   => (oldrank == 0 && @players[player][:ranked].rank != 0),
          :diffrank => @players[player][:ranked].rank - oldrank
        }
      end
    end

    def valid_to_append?(match)
      if match.ts > youngest
        return true
      else
        return false
      end
    end

    # Append, if this match is younger than our youngest
    def append(match)
      return false if not valid_match?(match)
      return false if not valid_to_append?(match)
      apply_match_delta(match)
      @matches << match
      true
    end

    # Insert, if this match is out of chronological order
    def insert(match)
      return false if not valid_match?(match)
      @matches << match
      recalculate!
      return true
    end

  end

end
