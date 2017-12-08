module NearestGasValidators
  class GpsValidator
    # regex from 'https://stackoverflow.com/a/31408260'
    # decimal format, with 6 decimal digits
    REGEX_LAT_FOR_STORE = /^(\+|-)?(?:90(?:(?:\.0{1,6})?)|(?:[0-9]|[1-8][0-9])(?:(?:\.[0-9]{1,6})?))$/
    REGEX_LNG_FOR_STORE = /^(\+|-)?(?:180(?:(?:\.0{1,6})?)|(?:[0-9]|[1-9][0-9]|1[0-7][0-9])(?:(?:\.[0-9]{1,6})?))$/
    # decimal format, with unlimited decimal digits
    REGEX_LAT_FOR_PARAMS = /^(\+|-)?(?:90(?:(?:\.0+)?)|(?:[0-9]|[1-8][0-9])(?:(?:\.[0-9]+)?))$/
    REGEX_LNG_FOR_PARAMS = /^(\+|-)?(?:180(?:(?:\.0+)?)|(?:[0-9]|[1-9][0-9]|1[0-7][0-9])(?:(?:\.[0-9]+)?))$/
    
    def initialize(lat, lng)
      @lat = lat.to_s
      @lng = lng.to_s
    end

    def valid_to_store?
      @lat =~ REGEX_LAT_FOR_STORE && @lng =~ REGEX_LNG_FOR_STORE
    end

    def valid_params?
      @lat =~ REGEX_LAT_FOR_PARAMS && @lng =~ REGEX_LNG_FOR_PARAMS
    end
  end
end