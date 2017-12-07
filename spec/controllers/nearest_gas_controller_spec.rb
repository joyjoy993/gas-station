require 'rails_helper'
require 'database_cleaner'
require 'factories/google_map_api_fake_response'
include GoogleMapApiFakeResponse

RSpec.describe NearestGasController, type: :controller do

  before(:all) do
    Location.create_indexes
    DatabaseCleaner.strategy = :truncation
  end

  before(:each) do
    DatabaseCleaner.clean
  end

  it 'Invalid gps parameters' do
    invalid_gps = [
      [-122.41204993, 37.77790], # longitude is over 6 decimal digits
      [-122.412049, 37.73779088], # latitude is over 6 decimal digits
      [-122.41204993, 100], # latitude is over 90 degree
      [-181, 37.77790], # longitude is less than -180 degree
      [181, 37.77790], # longitude is over 180 degree
      [-122.41204993, -91], # latitude is less than -90 degree
    ]
    for gps in invalid_gps
      params = {
        lat: gps[1],
        lng: gps[0]
      }
      get :show, params: params
      expect(response).to have_http_status(422)
    end
  end

  it 'Google server is down' do
    fake_gps = fake_gps_pair
    stub_request(:any, /https:\/\/maps.googleapis.com\/*/).to_return(status: [500, 'Internal Server Error'])
    get :show, params: fake_gps
    expect(response).to have_http_status(500)
  end

  it 'Normal requestes' do
    fake_responses = fake_some_responses(10)
    for fake_response in fake_responses
      # geocoding query, used in reversing gps
      stub_request(:any, /https:\/\/maps.googleapis.com\/maps\/api\/geocode\/json?(.*)latlng=(.*)/).to_return(
        status: 200,
        body: fake_response[:address][:geocoding_response].to_json)
      # near by gas station query
      stub_request(:any, /https:\/\/maps.googleapis.com\/maps\/api\/place\/nearbysearch\/json?(.*)location=(.*)/).to_return(
        status: 200,
        body: fake_response[:nearest_gas_station_response].to_json)
      # geocoding query, used in formatting address
      stub_request(:any, /https:\/\/maps.googleapis.com\/maps\/api\/geocode\/json?(.*)address=(.*)/).to_return(
        status: 200,
        body: fake_response[:address][:geocoding_response].to_json)
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
