module LocationConcern
  extend ActiveSupport::Concern

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

  def format_url_and_return_json_response(base_url, *params)
    formatted_url = URI.encode(base_url % params)
    response = open(formatted_url).read
    return JSON.parse(response)
  end

end