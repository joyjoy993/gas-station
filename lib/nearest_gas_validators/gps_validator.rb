module NearestGasValidators
  class GpsValidator
    attr_accessor :lat, :lng

    # regex from 'https://stackoverflow.com/a/31408260'
    # decimal format, with 6 decimal digits
    REGEX_LAT = /^(\+|-)?(?:90(?:(?:\.0{1,6})?)|(?:[0-9]|[1-8][0-9])(?:(?:\.[0-9]{1,6})?))$/
    REGEX_LNG = /^(\+|-)?(?:180(?:(?:\.0{1,6})?)|(?:[0-9]|[1-9][0-9]|1[0-7][0-9])(?:(?:\.[0-9]{1,6})?))$/
    
    def initialize(lat, lng)
      @lat = lat
      @lng = lng
    end

    def valid?
      lat =~ REGEX_LAT && lng =~ REGEX_LNG
    end
  end
end