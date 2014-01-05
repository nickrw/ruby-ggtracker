require 'json'
require 'ggtracker/uniquebyid'
require 'acts_as_elo'

module GGTracker

  class Identity < UniqueById

    attr_reader :name, :matches, :url
    attr_accessor :alias

    def self.factory(item)
      result = super
      return result if not result.nil?
      GGTracker::API.identity(item)
    end

    def initialize(id_hash)
      super
      @name = @data['name']
      @alias = @name
      @url = "http://ggtracker.com/players/#{@id}/#{@name}"
      @matches = []
    end

    def record_match(match)
      if match.class != GGTracker::Match
        raise ArgumentError, "#record_match expects a Match object"
      end
      if match.player?(self)
        if not @matches.include?(match)
          @matches << match
          # if match.won?(self)
          #   match.losers.each do |loser|
          #     elo_win!(loser)
          #   end
          # end
          # if match.lost?(self)
          #   match.winners.each do |winner|
          #     elo_lose!(winner)
          #   end
          # end
          return true
        else
          return false
        end
      else
        raise ArgumentError, "Identity does not appear in this Match"
      end
    end

    def <<(match)
      record_match(match)
    end

    # if a block is passed it will be passed matches which are vs another
    # player. They should return false to exclude it from the returned array
    def versus(opponent, &filter)
      vs = []
      @matches.each do |match|
        next if not match.opponents?(self, opponent)
        if (filter and yield match) or not filter
          vs << match
        end
      end
      vs
    end

    def wins_versus(opponent)
      versus(opponent) { |x| x.won?(self) }
    end

    def losses_versus(opponent)
      versus(opponent) { |x| x.lost?(self) }
    end

    def wins
      w = @matches.dup
      w.delete_if { |x| x.lost?(self) }
      w
    end

    def losses
      l = @matches.dup
      l.delete_if { |x| x.won?(self) }
      l
    end

    def compare_matches(other)
      if other.class != GGTracker::Identity
        raise ArgumentError, "#compare_matches expects an Identity"
      end
      wins = versus(other) { |m| m.won?(self) }.count
      # Count losses as won by the other player, not just games we both
      # played in that I lost. Otherwise FFAs won by a 3rd party show up
      # as a match lost vs this player.
      losses = versus(other) { |m| m.won?(other) }.count
      wins <=> losses
    end

    def inspect
      "#<#{self.class}:0x%x #{@name} (#{@id.to_s})>" % (self.object_id << 1)
    end

  end

  class RankedIdentity

    include ::Acts::Elo
    acts_as_elo

    attr_reader :identity, :wins, :losses

    def initialize(identity)
      if identity.class != GGTracker::Identity
        raise ArgumentError, "#{self.class}.initialize expects a GGTracker::Identity object"
      end
      @identity = identity
      @wins = 0
      @losses = 0
    end

    def win_match
      @wins += 1
    end

    def lose_match
      @losses += 1
    end

    def win_vs(vs)
      elo_win!(vs)
    end

    def loss(vs)
      elo_lose!(vs)
    end

    def count
      @wins + @losses
    end

    def rank
      if @wins > 0 or @losses > 0
        return elo_rank
      else
        return 0
      end
    end

    def <=>(other)
      rank <=> other.rank
    end

    def inspect
      "#<#{self.class}:0x%x #{@identity.name} (#{rank})>" % (self.object_id << 1)
    end

  end

end
