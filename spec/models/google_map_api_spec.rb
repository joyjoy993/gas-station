require 'rails_helper'
require 'support/google_map_api_fake_response'
include GoogleMapApiFakeResponse

RSpec.describe GoogleMapApi, type: :model do

  before(:all) do
    google_api_key = Rails.application.secrets.google_api_key
    @google_map_api_instance = GoogleMapApi.new(google_api_key)
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
    fake_responses = get_some_fake_response(10)
    for fake_response in fake_responses
      fake_google_response = fake_response[:google_response].with_indifferent_access
      parsed_component = fake_response[:parsed_component]
      expect( @google_map_api_instance.parse_address_result(fake_google_response['results'][0]) ).to eq(parsed_component)
    end
  end
end
