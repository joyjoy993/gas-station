require 'rails_helper'
require 'factories/google_map_api_fake_response'
require 'helpers/stub_request_helper'
include GoogleMapApiFakeResponse
include StubRequestHelper

RSpec.describe GoogleMapApi, type: :model do

  before(:all) do
    google_api_key = Rails.application.secrets.google_api_key
    @google_map_api_instance = GoogleMapApi.new(google_api_key)
    fake_response = fake_a_response
    fake_gps = fake_response[:fake_gps]
    @gps = [fake_gps[:lng], fake_gps[:lat]]
  end

  it 'Google server is down' do
    stub_error_request(:all)
    expect{ @google_map_api_instance.reverse_gps(@gps[0], @gps[1]) }.to raise_error(NearestGasErrors::CustomError)
  end

  it 'Google returns result with status that is not OK' do
    error_status = ['ZERO_RESULTS', 'OVER_QUERY_LIMIT', 'REQUEST_DENIED', 'INVALID_REQUEST', 'UNKNOWN_ERROR']
    for status in error_status
      stub_request(:any, /https:\/\/maps.googleapis.com\/*/)
        .to_return(status: 200,  body: { status: status }.to_json)
      expect{ @google_map_api_instance.reverse_gps(@gps[0], @gps[1]) }.to raise_error(NearestGasErrors::GoogleMapApiError)
    end
  end

  it 'Parse components in result and return json of address' do
    fake_responses = fake_some_responses(10)
    for fake_response in fake_responses
      fake_google_response = fake_response[:address][:geocoding_response].with_indifferent_access
      parsed_address = fake_response[:address][:parsed_address]
      expect( @google_map_api_instance.parse_address_result(fake_google_response['results'][0]) ).to eq(parsed_address)
    end
  end
end
