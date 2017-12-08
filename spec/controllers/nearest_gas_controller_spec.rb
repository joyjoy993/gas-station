require 'rails_helper'
require 'database_cleaner'
require 'factories/google_map_api_fake_response'
require 'helpers/stub_request_helper'
include GoogleMapApiFakeResponse
include StubRequestHelper

RSpec.describe NearestGasController, type: :controller do

  before(:all) do
    Location.create_indexes
    DatabaseCleaner.strategy = :truncation
  end

  before(:each) do
    DatabaseCleaner.clean
  end
  
  it 'Invalid params' do
    invalid_params = [
      { # extra params
        lat: -111,
        lng: -91,
        test: 'hi'
      }, { # missing longitude 
        lat: -111
      }, { # missing latitude
        lng: -91
      }, { # missing all 
      }, { # invalid params 
        test: '??'
      }, { # longitude is over 6 decimal digits
        lng: -122.41204993,
        lat: 37.77790
      }, { # latitude is over 6 decimal digits
        lng: -122.412049,
        lat: 37.73779088 
      }, { # latitude is over 90 degree
        lng: -122.41204993,
        lat: 100 
      }, { # longitude is less than -180 degree
        lng: -181,
        lat: 37.77790 
      }, { # longitude is over 180 degree
        lng: 181,
        lat: 37.77790 
      }, { # latitude is less than -90 degree
        lng: -122.41204993,
        lat: -91 
      }, { # invalid longitude
        lng: 'string',
        lat: -91 
      }, { # invalid latitude
        lng: -111,
        lat: 'string' 
      }, { # both invalid
        lng: 'string',
        lat: 'string' 
      }, {  # longitude is blank
        lng: nil,
        lat: -91
      }, { # latitude is blank
        lng: -122,
        lat: nil 
      },
    ]
    for params in invalid_params
      get :show, params: params
      expect(response).to have_http_status(422)
    end
  end

  it 'Google server is down' do
    stub_error_request(:all)
    fake_gps = fake_gps_pair
    get :show, params: fake_gps
    expect(response).to have_http_status(500)
  end

  it 'Query some gps that Google will return result without \'OK\' status' do
    error_status = ['OVER_QUERY_LIMIT', 'REQUEST_DENIED', 'INVALID_REQUEST', 'UNKNOWN_ERROR']
    fake_gps = fake_gps_pair
    for status in error_status
      stub_request(:any, /https:\/\/maps.googleapis.com\/*/)
        .to_return(status: 200,  body: { results: [], status: status }.to_json)
      get :show, params: fake_gps
      expect(response).to have_http_status(503)
    end
  end

  it 'Query from google returns ZERO_RESULTS' do
    stub_request(:any, /https:\/\/maps.googleapis.com\/*/)
        .to_return(status: 200,  body: { results: [], status: 'ZERO_RESULTS' }.to_json)
    fake_gps = fake_gps_pair
    get :show, params: fake_gps
    expected_response = {
      address: nil,
      nearest_gas_station: nil
    }
    expect(response.body).to eq(expected_response.to_json)
  end

  it 'Normal requestes' do
    fake_responses = fake_some_responses(10)
    for fake_response in fake_responses
      stub_normal_request(fake_response)
      expected_response = {
        address: fake_response[:address][:parsed_address],
        # here I use address to fake gas station address, because they share the same parsing logic
        # they both use geocoding api to fetch address components and parse them to be address
        nearest_gas_station: fake_response[:address][:parsed_address]
      }
      get :show, params: fake_response[:fake_gps]
      expect(response.body).to eq(expected_response.to_json)
    end
  end

end
