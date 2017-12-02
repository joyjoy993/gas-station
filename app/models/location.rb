class Location
  include LocationConcern
  include Mongoid::Document
  field :gps, type: Array
  field :address, type: Hash
  field :nearest_gas_station, type: Hash
  field :query_time, type: DateTime, default: DateTime.now

  validates :gps, :query_time, :address, :nearest_gas_station, presence: true

  index({gps: '2d'}, {min: -180, max: 180})

  CACHING_PRECISION = 0.005 / 111.12 # 5 meters
  STALE_TIME = 3.days.ago # expire time
  GOOGLE_MAP_KEY = Rails.application.secrets.google_api_key
  REVERSE_GPS_QUERY_URL = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=%s,%s&key=%s'
  GAS_STATION_QUERY_URL = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%s,%s&type=gas_station&rankby=distance&key=%s'
  GEOCODING_QUERY_URL = 'https://maps.googleapis.com/maps/api/geocode/json?address=%s&key=%s'

  def fetch_location(lat, lng)
    nearest_gas_station = fetch_nearest_gas_station(lat, lng)
    address = fetch_address(lat, lng)
    return {
      address: address,
      nearest_gas_station: nearest_gas_station
    }
  end

  def fetch_cache_gas_station(lat, lng)
    gps = Array[lng.to_f, lat.to_f]
    caching_result = Location.where(:query_time.gte => STALE_TIME)
                      .geo_near(gps).max_distance(CACHING_PRECISION)
    unless caching_result.empty?
      return caching_result.first[:nearest_gas_station]
    else
      return nil
    end
  end

  def fetch_cache_address(lat, lng)
    gps = Array[lng.to_f, lat.to_f]
    caching_result = Location.where(gps: gps)
    unless caching_result.empty?
      return caching_result.first[:address]
    else
      return nil
    end
  end

  def fetch_nearest_gas_station(lat, lng)
    gas_station_address = fetch_cache_gas_station(lat, lng)
    if gas_station_address
      return gas_station_address
    end
    response_from_gas_station_query = format_url_and_return_json_response(
                                        GAS_STATION_QUERY_URL,
                                        lat,
                                        lng,
                                        GOOGLE_MAP_KEY)
    gas_station_address = response_from_gas_station_query['results'].first['vicinity']
    response_from_geocoding_query = format_url_and_return_json_response(
                                      GEOCODING_QUERY_URL,
                                      gas_station_address,
                                      GOOGLE_MAP_KEY)
    address_components = response_from_geocoding_query['results'].first['address_components']
    return parse_address_components_from_google_api(address_components)
  end

  def fetch_address(lat, lng)
    address = fetch_cache_address(lat, lng)
    if address
      return address
    end
    addresses = []
    response_from_reverse_gps_query = format_url_and_return_json_response(
                                        REVERSE_GPS_QUERY_URL,
                                        lat,
                                        lng,
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
    return address
  end

end
