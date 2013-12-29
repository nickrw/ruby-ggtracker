require 'json'
module GGTracker

  class UniqueById

    attr_reader :id
    attr_reader :data

    def self.preinit
      @@cache ||= {}
      @@cache[self] ||= {}
    end

    def self.factory(item)
      return item if item.class == self.class
      preinit
      if item.class == String
        item = JSON.parse(item)
        id = item['id']
      elsif item.class == Fixnum
        id = item
      elsif item.class == Hash
        id = item['id']
      else
        return nil
      end
      if @@cache[self].keys.include?(id)
        return @@cache[self][id]
      end
      if item.class == Hash
        return self.new(item)
      else
        return nil
      end
    end

    def self.cache
      preinit
      @@cache[self]
    end

    def initialize(item_hash)
      self.class.preinit
      @id = item_hash['id'].to_i
      @data = item_hash
      if @@cache[self.class][@id]
        raise ArgumentError,
          "#{self.class}#new called twice with the same ID: #{@id}"
      else
        @@cache[self.class][@id] = self
      end
    end

    def <=>(other)
      id <=> other.id
    end

    def inspect
      "#<#{self.class}:0x%x id:#{@id.to_s} >" % (self.object_id << 1)
    end

  end

end
