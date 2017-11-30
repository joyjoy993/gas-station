require 'open-uri'

class NearestGasController < ApplicationController

  GOOGLE_MAP_KEY = Rails.application.secrets.google_api_key
  REVESE_GPS_QUERY_URL = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=%s,%s&key=%s'
  GAS_STATION_QUERY_URL = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%s,%s&type=gas_station&rankby=distance&key=%s'
  GEOCODING_QUERY_URL = 'https://maps.googleapis.com/maps/api/geocode/json?address=%s&key=%s'

  def index
    permitted = params.permit(:lat, :lng)
    lat = permitted[:lat]
    lng = permitted[:lng]
    unless lat && lng
      render json: {
        error: 'params are invalid',
        status: 400
      }, status: 400
      return
    end
    nearest_gas_station = fetch_nearest_gas_station(lat, lng)
    render json: {
        address: nearest_gas_station,
        status: 200
      }, status: 200
  end

  def fetch_nearest_gas_station(lat, lng)
    begin
      formatted_gas_station_query_url = URI.encode(format(GAS_STATION_QUERY_URL, lat, lng, GOOGLE_MAP_KEY))
      gas_station_address = JSON.parse(open(formatted_gas_station_query_url).read)['results'][0]['vicinity']
      return gas_station_address
    rescue Exception => e
      puts e
      return {}
    end
  end

end
