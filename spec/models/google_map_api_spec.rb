require 'rails_helper'

RSpec.describe GoogleMapApi, type: :model do

  before(:all) do
    google_api_key = Rails.application.secrets.google_api_key
    @google_map_api_instance = GoogleMapApi.new(google_api_key)
    @sample_result = {
      "results": [{
        "address_components": [{
          "long_name": "1600",
          "short_name": "1600",
          "types": [ "street_number" ]
        }, {
          "long_name": "Amphitheatre Pkwy",
          "short_name": "Amphitheatre Pkwy",
          "types": [ "route" ]
        }, {
          "long_name": "Mountain View",
          "short_name": "Mountain View",
          "types": [ "locality", "political" ]
        }, {
          "long_name": "Santa Clara County",
          "short_name": "Santa Clara County",
          "types": [ "administrative_area_level_2", "political" ]
        }, {
          "long_name": "California",
          "short_name": "CA",
          "types": [ "administrative_area_level_1", "political" ]
        }, {
          "long_name": "United States",
          "short_name": "US",
          "types": [ "country", "political" ]
        }, {
          "long_name": "94043",
          "short_name": "94043",
          "types": [ "postal_code" ]
        }],
        "formatted_address": "1600 Amphitheatre Parkway, Mountain View, CA 94043, USA",
        "geometry": {
          "location": {
            "lat": 37.4224764,
            "lng": -122.0842499
          },
          "location_type": "ROOFTOP",
          "viewport": {
            "northeast": {
              "lat": 37.4238253802915,
              "lng": -122.0829009197085
            },
            "southwest": {
              "lat": 37.4211274197085,
              "lng": -122.0855988802915
            }
          }
        },
        "place_id": "ChIJ2eUgeAK6j4ARbn5u_wAGqWA",
        "types": [ "street_address" ]
      }]
    }.with_indifferent_access
  end

  it 'Google server is down' do
    stub_request(:any, /https:\/\/maps.googleapis.com\/*/).to_return(status: [500, 'Internal Server Error'])
    expect{ @google_map_api_instance.reverse_gps(37.7779056, -122.4120423) }.to raise_error(NearestGasErrors::CustomError)
  end

  it 'Google returns result with status that is not OK' do
    error_status = ['ZERO_RESULTS', 'OVER_QUERY_LIMIT', 'REQUEST_DENIED', 'INVALID_REQUEST', 'UNKNOWN_ERROR']
    for status in error_status
      stub_request(:any, /https:\/\/maps.googleapis.com\/*/)
        .to_return(status: 200,  body: { status: status }.to_json)
      expect{ @google_map_api_instance.reverse_gps(37.7779056, -122.4120423) }.to raise_error(NearestGasErrors::GoogleMapApiError)
    end
  end

  it 'Parse components in result and return json of address' do
    expect( @google_map_api_instance.parse_address_result(@sample_result['results'][0]) ).to eq({
      streetAddress: '1600 Amphitheatre Pkwy',
      city: 'Mountain View',
      state: 'CA',
      postalCode: '94043'
    })
  end
end
