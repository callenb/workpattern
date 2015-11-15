module Workpattern

  # Mixins expected to be used in more than one class
  #
  # @since 0.2.0
  #
  module Base
    # Holds local timezone info
    @@tz = nil
    
    # Converts a date like object into utc
    #
    def to_utc(date)
      timezone.local_to_utc(date)
    end
    
    # Converts a date like object into local time
    #
    def to_local(date)
      timezone.utc_to_local(date)
    end
    
    # Retrieves the local timezone
    def timezone
      @@tz || @@tz=TZInfo::Timezone.get(Time.now.zone)
    end
    
  end
end  
