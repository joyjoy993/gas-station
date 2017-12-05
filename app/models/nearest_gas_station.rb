class NearestGasStation
  include ModelConcern

  CACHING_PRECISION = 0.005 / 111.12 # 5 meters
  STALE_TIME = 3.days.ago # expire time

  def initialize(lat, lng)
    google_api_key = Rails.application.secrets.google_api_key
    @google_map_api_instance = GoogleMapApi.new(google_api_key)
    @lat = lat.to_f
    @lng = lng.to_f
    @gps = Array[@lng, @lat]
    @is_gps_cached = false
  end

  def get_result()
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

  def create_location(address, nearest_gas_station)
    unless @is_gps_cached
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
      return address
    end
    addresses = []
    response_of_reversing_gps = @google_map_api_instance.reverse_gps(@lat, @lng)
    response_of_reversing_gps['results'].each { |result|
      address = @google_map_api_instance.parse_address_result(result)
      # When an address doesn't have streetAddress, it's a general address like a state, a place or a area marker
      next if address[:streetAddress].nil?
      addresses.push({
        address: address
      })
    }
    address = addresses.empty? ? nil : addresses.first[:address]
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
      return nil
    end
  end

  def fetch_nearest_gas_station()
    gas_station_address = fetch_cache_gas_station()
    if gas_station_address
      return gas_station_address
    end
    response_of_nearby_gas_station = @google_map_api_instance.nearby(@lat, @lng, 'gas_station', 'distance')
    gas_station_address = response_of_nearby_gas_station['results'].first['vicinity']
    response_of_geocoding = @google_map_api_instance.geocoding(gas_station_address)
    return @google_map_api_instance.parse_address_result(response_of_geocoding['results'].first)
  end

end