class Location
  include GoogleApi
  include Mongoid::Document

  field :gps, type: Array
  field :address, type: Hash
  field :nearest_gas_station, type: Hash
  field :query_time, type: DateTime, default: DateTime.now

  validates :gps, :query_time, presence: true
  validate :gps_valid?

  # index gps and query_time with 'unique' option
  # pros:
  # can ensure cached query is uniqueness
  # cons:
  # can not log query(will delete stale record)
  index({gps: '2d', query_time: 1}, {min: -180, max: 180, unique: true})

  # Mongodb nearby function uses degree as 'max_distance'
  # One degree is approximately 111.12 kilometers
  # For example, 5 meters is equal to 0.005/111.12 degree
  CACHING_PRECISION = 0.005 / 111.12 # 5 meters
  STALE_TIME = 3.days.ago # expire time

  # main method to fetch result
  def get_result(lat, lng)
    initialize_variables(lat, lng)
    location_result = fetch_address()
    address = location_result[:address]
    nearest_gas_station = location_result[:nearest_gas_station]
    unless nearest_gas_station
      # if nearest_gas_station is nil, it means no cache
      nearest_gas_station = fetch_nearest_gas_station()
    end
    create_location(address, nearest_gas_station)
    location_result = {
      address: address,
      nearest_gas_station: nearest_gas_station
    }
    return location_result
  end

  private

  def gps_valid?
    lat = gps[1]
    lng = gps[0]
    gps_validator = NearestGasValidators::GpsValidator.new(lat, lng)
    # validate latitude and longitude with 6 decimal digits limitation
    unless gps_validator.valid_to_store?
      errors.add(:gps, 'Invalid gps pair')
    end
  end

  def initialize_variables(lat, lng)
    google_api_key = Rails.application.secrets.google_api_key
    @google_map_api_instance = GoogleApi::GoogleMapApi.new(google_api_key)
    # latitude and longitude that are over 6 decimal digits will be 
    # rounded to 6 decimal digits in google map api, so I think that 
    # we should be better to round them to 6 decimal ditgits too, because 
    # it will keep ours records the same as google's.
    @lat = lat.to_f.round(6) # round it to 6 decimal digits
    @lng = lng.to_f.round(6) # round it to 6 decimal digits
    @gps = [@lng, @lat]
    @is_gps_cached = false
  end

  def create_location(address, nearest_gas_station)
    unless @is_gps_cached
      Location.delete_all({gps: @gps})# remove stale record first
      location = Location.new(
        gps: @gps,
        address: address,
        nearest_gas_station: nearest_gas_station
      )
      location.save!
    end
  end

  def fetch_address()
    address = fetch_cache_address()
    if address
      # if address is not nil, it means that there's a cached address
      return address
    end
    results_of_reversing_gps = @google_map_api_instance.geocoding_by_gps(@lat, @lng)
    if results_of_reversing_gps
      results_of_reversing_gps.each { |result|
        parsed_address = @google_map_api_instance.parse_address_result(result)
        # When an address doesn't have streetAddress, it's a general address like a state, a place or a area marker
        next if parsed_address[:streetAddress].nil?
        address = parsed_address
        break
      }
    end
    return {
      address: address
    }
  end

  # method: fetch_cache_address
  # description:
  # If the gps(lat and lng must be exactly the same) was cached,
  # fetch caching from database.
  #
  # Return sample:
  # { 
  #   "_id" : ObjectId("5a25f3b2b26e3caec5b3e6e1"), 
  #   "query_time" : ISODate("2017-12-05T01:17:38.163+0000"), 
  #   "gps" : [
  #     -73.9916335, 
  #     40.7519429
  #   ], 
  #   "address" : {
  #     "streetAddress" : "234 West 35th Street", 
  #     "city" : "New York", 
  #     "state" : "NY", 
  #     "postalCode" : "10123"
  #   }, 
  #   "nearest_gas_station" : {
  #     "streetAddress" : "1 Pennsylvania Plaza", 
  #     "city" : "New York", 
  #     "state" : "NY", 
  #     "postalCode" : "10119"
  #   }
  # }
  def fetch_cache_address()
    caching_result = Location.where(gps: @gps, :query_time.gte => STALE_TIME)
    unless caching_result.empty?
      @is_gps_cached = true
      return caching_result.first
    else
      # no cache
      @is_gps_cached = false
      return nil
    end
  end

  # method: fetch_cache_gas_station
  # description: If there are some gps that are around the query
  # gps within CACHING_PRECISION range, and they are still fresh,
  # then return one as the result.
  #
  # Return sample:
  # { 
  #   "streetAddress" : "1 Pennsylvania Plaza", 
  #   "city" : "New York", 
  #   "state" : "NY", 
  #   "postalCode" : "10119"
  # }
  def fetch_cache_gas_station()
    caching_result = Location.where(:query_time.gte => STALE_TIME)
                      .geo_near(@gps).max_distance(CACHING_PRECISION)
    unless caching_result.empty?
      return caching_result.first[:nearest_gas_station]
    else
      # no cache
      return nil
    end
  end

  def fetch_nearest_gas_station()
    gas_station_address = fetch_cache_gas_station()
    if gas_station_address
      return gas_station_address
    end
    results_of_nearby_gas_station = @google_map_api_instance.nearby(@lat, @lng, 'gas_station', 'distance')
    if results_of_nearby_gas_station.empty?
      return nil
    end
    # vicinity contains a feature name of a nearby location.
    # Often this feature refers to a street or neighborhood within the given results. 
    # The vicinity property is only returned for a Nearby Search.
    gas_station_address = results_of_nearby_gas_station.first['vicinity']
    results_of_geocoding = @google_map_api_instance.geocoding_by_address(gas_station_address)
    return @google_map_api_instance.parse_address_result(results_of_geocoding.first)
  end

end
