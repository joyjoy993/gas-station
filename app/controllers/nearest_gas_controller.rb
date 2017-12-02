require 'open-uri'

class NearestGasController < ApplicationController

  GOOGLE_MAP_KEY = Rails.application.secrets.google_api_key
  REVERSE_GPS_QUERY_URL = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=%s,%s&key=%s'
  GAS_STATION_QUERY_URL = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%s,%s&type=gas_station&rankby=distance&key=%s'
  GEOCODING_QUERY_URL = 'https://maps.googleapis.com/maps/api/geocode/json?address=%s&key=%s'
  GOOGLE_ADDRESS_COMPONENT_MAPPING_KEYS = {
    street_number: {
      original_key: 'long_name',
      mapping_key: 'street_number'
    },
    route: {
      original_key: 'long_name',
      mapping_key: 'route'
    },
    locality: {
      original_key: 'long_name',
      mapping_key: 'city'
    },
    administrative_area_level_1: {
      original_key: 'short_name',
      mapping_key: 'state'
    },
    postal_code: {
      original_key: 'long_name',
      mapping_key: 'postal_code'
    },
    postal_code_suffix: {
      original_key: 'long_name',
      mapping_key: 'postal_code_suffix'
    }
  }

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

  def parse_address_components_helper(types, parsed_address_components, address_component)
    types.each{ |type|
      type_symbol = type.to_sym
      if GOOGLE_ADDRESS_COMPONENT_MAPPING_KEYS.include? type_symbol
        mapping_key = GOOGLE_ADDRESS_COMPONENT_MAPPING_KEYS[type_symbol][:mapping_key]
        original_key = GOOGLE_ADDRESS_COMPONENT_MAPPING_KEYS[type_symbol][:original_key]
        parsed_address_components[mapping_key] = address_component[original_key]
      end
    }
  end

  def concat_postal_code_or_address_string_helper(parsed_address_components, pattern, first_key, second_key)
    formatted_string = ''
    if parsed_address_components.key?(second_key) && parsed_address_components[second_key] != ''
      formatted_string = format(
                          pattern,
                          parsed_address_components[first_key],
                          parsed_address_components[second_key])
    else
      formatted_string = parsed_address_components[first_key]
    end
    return formatted_string
  end

  # A function to parse address components from google api
  def parse_address_components_from_google_api(address_components)
    parsed_address_components = {}
    begin
      address_components.each{ |address_component|
        types = address_component['types']
        parse_address_components_helper(
          types,
          parsed_address_components,
          address_component)
      }
      postal_code = concat_postal_code_or_address_string_helper(
                      parsed_address_components,
                      '%s-%s',
                      'postal_code',
                      'postal_code_suffix')
      street_address = concat_postal_code_or_address_string_helper(
                        parsed_address_components,
                        '%s %s',
                        'street_number',
                        'route')
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
