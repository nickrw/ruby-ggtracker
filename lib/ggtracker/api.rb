require 'httparty'
require 'webmock'
require 'ggtracker/identity'

module GGTracker

  module API

    WebMock.disable_net_connect!

    def self.allow_api_calls
      WebMock.allow_net_connect!
    end

    def self.cachedcall(callname, id, url, params=nil)

      cachepath = File.join(GGTracker.vardir, 'api-cache', callname)
      cache_content = nil
      if not Dir.exists?(cachepath)
        Dir.mkdir(cachepath, 0755)
      end
      cachefile = File.join(cachepath, id.to_s + ".json")

      if File.exists?(cachefile)
        mtime = Time.now - File.mtime(cachefile)
        if mtime <= GGTracker.cachettl
          cache_content = IO.read(cachefile)
          sr = WebMock::API.stub_request(:get, url)
          sr.with(:query => params) unless params.nil?
          sr.to_return(
            :status => 200,
            :body => cache_content,
            :headers => {'Content-Type' => 'application/json'}
          )
        end
      end

      apicall = lambda do
        args = [url]
        args << {:query => params} unless params.nil?
        return HTTParty.get(*args)
      end

      if cache_content.nil?
        response = ratelimit(&apicall)
        IO.write(cachefile, response.body)
        return response
      else
        return apicall.call
      end

    end

    def self.ratelimit(&block)
      tn = Time.now
      @@last ||= tn - 3
      if (tn - @@last) < 2
        sleep (tn - @@last)
      end
      @@last = tn
      return block.call
    end

    def self.identity(id)
      raise ArgumentError, "Player ID must be a Fixnum" if id.class != Fixnum
      raise ArgumentError, "Player ID must be > 0" if not id > 0
      r = GGTracker::API.cachedcall(
        'identity',
        id,
        "http://api.ggtracker.com/api/v1/identities/#{id}.json"
      )
      pr = r.parsed_response
      raise RuntimeError, "API returned non-JSON content-type" if not r.headers['content-type'].include?('application/json')
      raise RuntimeError, "Did not retrieve valid JSON from ggtracker API" if pr.class != Hash
      GGTracker::Identity.factory(pr)
    end

    def self.single_match(id)
      raise ArgumentError, "Match ID must be a Fixnum" if id.class != Fixnum
      raise ArgumentError, "Match ID must be > 0" if not id > 0
      r = GGTracker::API.cachedcall(
        'match',
        id,
        "http://api.ggtracker.com/api/v1/matches/#{id}.json"
      )
      pr = r.parsed_response
      raise RuntimeError, "API returned non-JSON content-type" if not r.headers['content-type'].include?('application/json')
      raise RuntimeError, "Did not retrieve valid JSON from ggtracker API" if pr.class != Hash
      GGTracker::Match.factory(pr)
    end

    def self.matches(player_id, ladder=true, type="1v1")
      params = {
        :identity_id => player_id,
        :category => 'Ladder',
        :game_type => type,
        :order => '_played_at',
      }
      params.delete(:category) if not ladder
      PaginatedResults.new("matches", params)
    end

    class PaginatedResults

      include Enumerable

      attr_reader :count

      def initialize(call, params)
        @call = call
        @params = params.merge({:paginate => 'true', :limit => 10})
        fetch_page(1)
      end

      def [](index)
        return nil if @results.nil?
        if @results[index].nil?
          page = which_page_for?(index)
          fetch_page(page)
        end
        if @results[index].class != GGTracker::Match
          @results[index] = GGTracker::Match.factory(@results[index])
        end
        @results[index]
      end

      def each
        (0..@count-1).each do |index|
          yield self.[](index)
        end
      end

      def all
        each { |x| nil }
        @results
      end

      def fetch_page(page)
        params = @params.merge({:page => page})
        r = GGTracker::API.cachedcall(
          'matches',
          Digest::SHA256.hexdigest(params.to_s),
          "http://api.ggtracker.com/api/v1/matches",
          params
        )
        pr = r.parsed_response
        @count ||= pr['params']['total']
        @results ||= Array.new(@count)
        start = page_starts_at?(page)
        @results.slice!(start, @params[:limit])
        @results.insert(start, *pr['collection'])
      end

      def inspect
        "#<#{self.class}:0x%x #{@count} #{self.[](0).class} objects>" % (self.object_id << 1)
      end

      private

      def which_page_for?(index)
        (index / @params[:limit]).floor + 1
      end

      def page_starts_at?(page)
        (page * @params[:limit]) - @params[:limit]
      end

    end

  end

end
