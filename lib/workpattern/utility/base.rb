module Workpattern

  # Mixins expected to be used in more than one class
  #
  # @since 0.2.0
  #
  module Utility

    # Returns the supplied <tt>DateTime</tt> at the very start of the day.
    #
    # @param [DateTime] adate is the <tt>DateTime</tt> to be changed
    # @return [DateTime] 
    # 
    # @todo Consider mixin for DateTime class 
    #
    def midnight_before(adate)
      return adate -(HOUR * adate.hour) - (MINUTE * adate.min)
    end
    
    # Returns the supplied <tt>DateTime</tt> at the very start of the next day.
    #
    # @param [DateTime] adate is the <tt>DateTime</tt> to be changed
    # @return [DateTime] 
    # 
    # @todo Consider mixin for DateTime class  
    #
    def midnight_after(adate)
      return midnight_before(adate.next_day)
    end
    
  end
end  
