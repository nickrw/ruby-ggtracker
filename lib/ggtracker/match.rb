require 'json'
require 'ggtracker/uniquebyid'
require 'ggtracker/identity'
require 'set'

module GGTracker

  class Match < UniqueById

    attr_reader :type, :teams, :winning_team, :ladder, :players, :map, :ts

    def self.subscribe(&block)
      @@subscriptions ||= []
      @@subscriptions << block
    end

    def self.unsubscribe(&block)
      @@subscriptions ||= []
      @@subscriptions.delete(block)
    end

    def push
      @@subscriptions ||= []
      @@subscriptions.each do |block|
        block.call(self)
      end
    end

    def initialize(match_hash)
      super
      @type = @data['game_type']
      @length = @data['duration_seconds']
      @winning_team = @data['winning_team']
      @map = @data['map_name']
      @ts = Time.parse(@data['ended_at'])
      @ladder = false
      @ladder = true if @data['category'] == 'Ladder'
      @teams = {}
      @data['entities'].each do |player|
        @teams[player['team']] ||= []
        @teams[player['team']] << Identity.factory(player['identity'])
      end
      @teams.values.flatten.each do |player|
        # register this game with the player object
        player << self
      end
      @players = @teams.values.flatten.sort.uniq.to_set
      push
    end

    def <=>(other)
      @ts <=> other.ts
    end

    def player?(player)
      @teams.values.flatten.include?(player)
    end

    def teams_by_player
      players = {}
      @teams.each do |team, members|
        members.each do |player|
          players[player] = team
        end
      end
      players
    end

    def team?(player)
      teams_by_player[player]
    end

    def winners
      @teams[@winning_team] || []
    end

    def losers
      return [] if winners.empty?
      @teams.values.flatten.delete_if { |x| winners.include?(x) }
    end

    def won?(player_or_team)
      case player_or_team
      when GGTracker::Identity
        return winners.include?(player_or_team)
      when Fixnum
        return @winning_team == player_or_team
      else
        return nil
      end
    end

    def lost?(player_or_team)
      if player_or_team.class == GGTracker::Identity
        return false if not player?(player_or_team)
      end
      return false if won?(player_or_team)
      return false if winners.empty? # draw
      return true
    end

    # Returns true if the players given are on opposing teams
    #         false if the one or more players are on the same team
    #         nil if one or more of the players is not involved
    def opponents?(*players)
      players.uniq!
      return nil if players.count == 0
      return false if @teams.count < players.count
      teams = []
      p2t = teams_by_player
      players.each do |player|
        return nil if not player?(player)
        teams << p2t[player]
      end
      teams.count == teams.uniq.count
    end

    def pretty_team
      team_to_join = []
      @teams.each do |team, members|
        team_to_join << members.map{ |x| x.alias }.join(", ")
      end
      team_to_join.join(" Vs. ")
    end

    def to_s
      "#{pretty_team} on \"#{@map}\""
    end

    def inspect
      "#<#{self.class}:0x%x #{@id} - #{to_s}>" % (self.object_id << 1)
    end

  end

end


