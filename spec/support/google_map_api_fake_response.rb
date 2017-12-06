
module GoogleMapApiFakeResponse
  def get_google_response(fake_address)
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

  def get_parsed_address(fake_address)
    {
      streetAddress: format("%s %s", fake_address[:street_number], fake_address[:street_name]),
      city: fake_address[:city],
      state: fake_address[:state_abbr],
      postalCode: fake_address[:zipcode]
    }
  end

  def generate_parameters
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

  def generate_fake_gps_pair
    {
      lat: Faker::Address.latitude,
      lng: Faker::Address.longitude
    }
  end

  def get_a_fake_response
    parameters = generate_parameters
    {
      google_response: get_google_response(parameters),
      parsed_address: get_parsed_address(parameters)
    }
  end

  def get_some_fake_response(count)
    Array.new(count) {get_a_fake_response}
  end

end