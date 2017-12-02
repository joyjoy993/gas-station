require 'open-uri'

class NearestGasController < ApplicationController

  GOOGLE_MAP_KEY = Rails.application.secrets.google_api_key
  REVERSE_GPS_QUERY_URL = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=%s,%s&key=%s'
  GAS_STATION_QUERY_URL = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%s,%s&type=gas_station&rankby=distance&key=%s'
  GEOCODING_QUERY_URL = 'https://maps.googleapis.com/maps/api/geocode/json?address=%s&key=%s'

  def index
    permitted = params.permit(:lat, :lng)
    lat = permitted[:lat]
    lng = permitted[:lng]
    unless lat && lng
      render json: {
        error: 'params are invalid'
      }, status: 400
      return
    end
    addresses = reverse_gps(lat, lng)
    unless addresses
      render json: {
        error: 'latitude and longitude not found'
      }, status: 404
      return
    end
    nearest_gas_station = fetch_nearest_gas_station(lat, lng)
    unless nearest_gas_station
      render json: {
        error: 'gas station nearby not found'
      }, status: 404
      return
    end
    gps = Array[lng.to_f, lat.to_f]
    NearestGasStaion.create({
        gps: gps,
        addresses: addresses,
        nearest_gas_station: nearest_gas_station
    })
    render json: {
        addresses: addresses,
        nearest_gas_station: nearest_gas_station
      }, status: 200
  end

  # A function to fetch possible addresses by reversing gps
  def reverse_gps(lat, lng)
    begin
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
      return addresses
    rescue Exception => e
      puts 'error when fetching response from api: %s' % e.message
      return nil
    end
  end

  def format_url_and_return_json_response(base_url, *params)
    formatted_url = URI.encode(base_url % params)
    response = open(formatted_url).read
    return JSON.parse(response)
  end

  def fetch_nearest_gas_station(lat, lng)
    begin
      response_from_gas_station_query = format_url_and_return_json_response(
                                          GAS_STATION_QUERY_URL,
                                          lat,
                                          lng,
                                          GOOGLE_MAP_KEY)
      gas_station_address = response_from_gas_station_query['results'][0]['vicinity']
      response_from_geocoding_query = format_url_and_return_json_response(
                                        GEOCODING_QUERY_URL,
                                        gas_station_address,
                                        GOOGLE_MAP_KEY)
      address_components = response_from_geocoding_query['results'][0]['address_components']
      return parse_address_components_from_google_api(address_components)
    rescue Exception => e
      puts 'error when fetching response from api: #{e.message}'
      return nil
    end
  end

  # A function to parse address components from google api
  def parse_address_components_from_google_api(address_components)
    unless address_components
      return nil
    end
    parsed_address_components = {}
    begin
      address_components.each{ |address_component|
        types = address_component['types']
        if types.include? 'street_number'
          # street_number indicates the precise street number
          parsed_address_components['street_number'] = address_component['long_name']
        elsif types.include? 'route'
          # route indicates named route (such as "US 101")
          parsed_address_components['route'] = address_component['long_name']
        elsif types.include? 'locality'
          # locality indicates an incorporated city or town political entity
          parsed_address_components['city'] = address_component['long_name']
        elsif types.include? 'administrative_area_level_1'
          # administrative_area_level_1 indicates a first-order civil entity below the country level
          parsed_address_components['state'] = address_component['short_name']
        elsif types.include? 'postal_code'
          # postal_code indicates a postal code as used to address postal mail within the country
          parsed_address_components['postal_code'] = address_component['long_name']
        elsif types.include? 'postal_code_suffix'
          # postal_code_suffix indicates a postal code suffix as used to address postal mail within the country
          parsed_address_components['postal_code_suffix'] = address_component['long_name']
        end
      }
      postal_code = ''
      if parsed_address_components.key?('postal_code_suffix') && parsed_address_components['postal_code_suffix'] != ''
        postal_code = format('%s-%s', parsed_address_components['postal_code'], parsed_address_components['postal_code_suffix'])
      else
        postal_code = parsed_address_components['postal_code']
      end
      street_address = ''
      if parsed_address_components.key?('route') && parsed_address_components['route'] != ''
        street_address = format('%s %s', parsed_address_components['street_number'], parsed_address_components['route'])
      else
        street_address = parsed_address_components['street_number']
      end
      address = {
        streetAddress: street_address,
        city: parsed_address_components['city'],
        state: parsed_address_components['state'],
        postalCode: postal_code
      }
      return address
    rescue Exception => e
      puts 'error when parsing address components from api: #{e.message}'
      return nil
    end
  end

end
