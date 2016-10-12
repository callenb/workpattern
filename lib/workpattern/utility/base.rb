module Workpattern
  # Mixins expected to be used in more than one class
  #
  # @since 0.2.0
  #
  # @private
  module Base
    # Holds local timezone info
    @@tz = nil

    # Converts a date like object into utc
    #
    def to_utc(date)
      date.to_time.utc
    end

    # Converts a date like object into local time
    #
    def to_local(date)
      date.to_time.getgm
    end

    # Retrieves the local timezone
    def timezone
      @@tz || @@tz = TZInfo::Timezone.get(Time.now.zone)
    end
  end
end
