class Location
  include ModelConcern
  include Mongoid::Document
  field :gps, type: Array
  field :address, type: Hash
  field :nearest_gas_station, type: Hash
  field :query_time, type: DateTime, default: DateTime.now

  validates :gps, :query_time, :address, :nearest_gas_station, presence: true

  index({gps: '2d'}, {min: -180, max: 180})

  CACHING_PRECISION = 0.005 / 111.12 # 5 meters
  STALE_TIME = 3.days.ago # expire time

  def fetch_and_create_location(lat, lng)
    @lat = lat.to_f
    @lng = lng.to_f
    @gps = Array[@lng, @lat]
    location_result = fetch_address()
    address = location_result[:address]
    nearest_gas_station = location_result[:nearest_gas_station]
    unless nearest_gas_station
      nearest_gas_station = fetch_nearest_gas_station()
    end
    create_location(address, nearest_gas_station)
    location_result = {
      address: address,
      nearest_gas_station: nearest_gas_station
    }
    return location_result
  end

  def create_location(address, nearest_gas_station)
    unless @is_cached
      location = Location.new(
        gps: @gps,
        address: address,
        nearest_gas_station: nearest_gas_station
      )
      location.save!
    end
  end

  def fetch_cache_gas_station()
    caching_result = Location.where(:query_time.gte => STALE_TIME)
                      .geo_near(@gps).max_distance(CACHING_PRECISION)
    unless caching_result.empty?
      return caching_result.first[:nearest_gas_station]
    else
      return nil
    end
  end

  def fetch_cache_address()
    caching_result = Location.where(gps: @gps, :query_time.gte => STALE_TIME)
    unless caching_result.empty?
      @is_cached = true
      return caching_result.first
    else
      @is_cached = false
      return nil
    end
  end

  def fetch_nearest_gas_station()
    gas_station_address = fetch_cache_gas_station()
    if gas_station_address
      return gas_station_address
    end
    response_from_gas_station_query = fetch_data_from_google(
                                        GAS_STATION_QUERY_URL,
                                        @lat,
                                        @lng,
                                        GOOGLE_MAP_KEY)
    gas_station_address = response_from_gas_station_query['results'].first['vicinity']
    response_from_geocoding_query = fetch_data_from_google(
                                      GEOCODING_QUERY_URL,
                                      gas_station_address,
                                      GOOGLE_MAP_KEY)
    address_components = response_from_geocoding_query['results'].first['address_components']
    return parse_address_components_from_google_api(address_components)
  end

  def fetch_address()
    address = fetch_cache_address()
    if address
      return address
    end
    addresses = []
    response_from_reverse_gps_query = fetch_data_from_google(
                                        REVERSE_GPS_QUERY_URL,
                                        @lat,
                                        @lng,
                                        GOOGLE_MAP_KEY)
    response_from_reverse_gps_query['results'].each { |result|
      address = parse_address_components_from_google_api(result['address_components'])
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

end
