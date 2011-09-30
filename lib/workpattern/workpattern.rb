module Workpattern
  
  # Represents the 60 minutes of an hour using a <tt>Fixnum</tt> or <tt>Bignum</tt>
  #
  class Workpattern
    
    # holds collection of <tt>Workpattern</tt> objects  
    @@workpatterns = Hash.new()
    
    attr_accessor :name, :base, :span, :from, :to
    
    def initialize(name=DEFAULT_NAME,base_year=DEFAULT_BASE_YEAR,span=DEFAULT_SPAN)

      raise(NameError, "Workpattern '#{name}' already exists and can't be created again") if @@workpatterns.key?(name) 
        
      if span < 0
        offset = span.abs - 1
      else
        offset = 0
      end
      
      @name = name
      @base = base_year
      @span = span
      @from = Time.new(base_year.abs - offset)
      @to = Time.new(@from.year + span.abs - 1,12,31,23,59)
      
      #@weeks = SortedSet.new
      #@weeks << WeekPattern.new(@start,@finish)
      
      @@workpatterns[name]=self
    end
    
    def self.clear
      @@workpatterns.clear
    end
    
    def self.to_a
      @@workpatterns.to_a
    end
    
    def self.get(name)
      return @@workpatterns[name] if @@workpatterns.key?(name) 
      raise(NameError, "Workpattern '#{name}' doesn't exist so can't be retrieved")
    end
    
    def self.delete(name)
      if @@workpatterns.delete(name).nil?
        return false
      else
        return true
      end        
    end
    
  end
end
    