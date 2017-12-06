module GoogleMapApiFakeResponse
  def fake_geocoding_response(fake_address)
    # only contain address_components
    {
      results: [{
        address_components: [{
          long_name: fake_address[:street_number],
          short_name: fake_address[:street_number],
          types: [ "street_number" ]
        }, {
          long_name: fake_address[:street_name],
          short_name: fake_address[:street_name],
          types: [ "route" ]
        }, {
          long_name: fake_address[:city],
          short_name: fake_address[:city],
          types: [ "locality", "political" ]
        }, {
          long_name: fake_address[:city],
          short_name: fake_address[:city],
          types: [ "administrative_area_level_2", "political" ]
        }, {
          long_name: fake_address[:state],
          short_name: fake_address[:state_abbr],
          types: [ "administrative_area_level_1", "political" ]
        }, {
          long_name: fake_address[:country],
          short_name: fake_address[:country_abbr],
          types: [ "country", "political" ]
        }, {
          long_name: fake_address[:zipcode],
          short_name: fake_address[:zipcode],
          types: [ "postal_code" ]
        }],
      }],
      status: "OK"
    }
  end

  def fake_nearby_response()
    # only conatin vicnity
    # vicnity contains a feature name of a nearby location. 
    # Often this feature refers to a street or neighborhood within the given results.
    # The vicinity property is only returned for a Nearby Search.
    {
      results: Array.new(5) {
        {
          vicnity: Faker::Address.street_address
        }
      },
      status: "OK"
    }
  end

  def get_parsed_address(fake_address)
    {
      streetAddress: format("%s %s", fake_address[:street_number], fake_address[:street_name]),
      city: fake_address[:city],
      state: fake_address[:state_abbr],
      postalCode: fake_address[:zipcode]
    }
  end

  def fake_address_parameters
    {
      street_number: Faker::Address.building_number,
      street_name: Faker::Address.street_name,
      city: Faker::Address.city,
      state: Faker::Address.state,
      state_abbr: Faker::Address.state_abbr,
      country: Faker::Address.country,
      country_abbr: Faker::Address.country_code,
      zipcode: Faker::Address.zip
    }
  end

  def fake_gps_pair
    {
      lat: Faker::Address.latitude.to_f.round(6),
      lng: Faker::Address.longitude.to_f.round(6)
    }
  end

  def get_fake_geocoding_response_and_parsed_address
    address_components = fake_address_parameters
    {
      geocoding_response: fake_geocoding_response(address_components),
      parsed_address: get_parsed_address(address_components)
    }
  end

  # contain reverse, geocoding and nearby result from google api
  def fake_a_response
    {
      fake_gps: fake_gps_pair,
      address: get_fake_geocoding_response_and_parsed_address,
      nearest_gas_station: get_fake_geocoding_response_and_parsed_address,
      nearest_gas_station_response: fake_nearby_response,
    }
  end

  def fake_some_responses(count)
    Array.new(count) {fake_a_response}
  end

end