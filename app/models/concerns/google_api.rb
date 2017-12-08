module GoogleApi
  # can add other google api in this concerns in the future
  
  require 'open-uri'
  extend ActiveSupport::Concern

  class GoogleMapApi

    REVERSE_GPS_QUERY_URL = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=%s,%s&key=%s'
    NEARBY_QUERY_URL = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%s,%s&type=%s&rankby=%s&key=%s'
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

    def initialize(api_key)
      @api_key = api_key
    end

    def reverse_gps(lat, lng)
      fetch_data_from_google(REVERSE_GPS_QUERY_URL, lat, lng, @api_key)
    end

    def geocoding(address)
      fetch_data_from_google(GEOCODING_QUERY_URL, address, @api_key)
    end

    def nearby(lat, lng, type, rank_by=distance)
      fetch_data_from_google(NEARBY_QUERY_URL, lat, lng, type, rank_by, @api_key)
    end

    # A function to parse address components from google api
    def parse_address_result(address_result)
      address_components = address_result['address_components']
      parsed_address_components = {}
      address_components.each{ |address_component|
        types = address_component['types']
        parse_address_components_helper(
          types,
          parsed_address_components,
          address_component)
      }
      postal_code_suffix = parsed_address_components['postal_code_suffix']
      postal_code = parsed_address_components['postal_code']
      postal_code = postal_code_suffix ? format('%s-%s', postal_code, postal_code_suffix) : postal_code
      route = parsed_address_components['route']
      street_number = parsed_address_components['street_number']
      street_address = route ? format('%s %s', street_number, route) : street_number
      address = {
        streetAddress: street_address,
        city: parsed_address_components['city'],
        state: parsed_address_components['state'],
        postalCode: postal_code
      }
      address
    end

    private

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

    def fetch_data_from_google(base_url, *params)
      response = format_url_and_return_json_response(base_url, *params)
      data = response[:data]
      url = response[:url]
      unless data['status'] == 'OK'
        raise NearestGasErrors::GoogleMapApiError.new(data['status'], url)
      end
      data
    end

    def format_url_and_return_json_response(base_url, *params)
      formatted_url = URI.encode(base_url % params)
      begin
        response = open(formatted_url).read
      rescue OpenURI::HTTPError => error
        error_response = error.io
        message = error_response.status[1]
        log_message = format('%s when fetching %s', message, formatted_url)
        raise NearestGasErrors::CustomError.new(500, 'Internal Server Error', log_message)
      end
      return {
        data: JSON.parse(response),
        url: formatted_url
      }
    end
  end
end