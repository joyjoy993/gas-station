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

  it 'Invalid lat and lng pairs' do
    invalid_gps = [
      [-122.41204993, 37.77790], # longitude is over 6 decimal digits
      [-122.412049, 37.73779088], # latitude is over 6 decimal digits
      [-122.41204993, 100], # latitude is over 90 degree
      [-181, 37.77790], # longitude is less than -180 degree
      [181, 37.77790], # longitude is over 180 degree
      [-122.41204993, -91], # latitude is less than -90 degree
      ['string', -91], # invalid longitude
      [-111, 'string'], # invalid latitude
      ['string', 'string'], # both invalid
      [nil, -91], # longitude is blank
      [-122, nil] # latitude is blank
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

  it 'Invalid params' do
    invalid_params = [
      {
        lat: -111,
        lng: -91,
        test: 'hi'
      }, #extra params
      {
        lat: -111
      }, # missing longitude
      {
        lng: -91
      }, # missing latitude
      {
      }, # missing all
      {
        test: '??'
      } # invalid params
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
