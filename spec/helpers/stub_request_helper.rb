module StubRequestHelper

  URL_REGEX = {
    geocoding_by_gps: /https:\/\/maps.googleapis.com\/maps\/api\/geocode\/json?(.*)latlng=(.*)/,
    nearby: /https:\/\/maps.googleapis.com\/maps\/api\/place\/nearbysearch\/json?(.*)location=(.*)/,
    geocoding_by_address: /https:\/\/maps.googleapis.com\/maps\/api\/geocode\/json?(.*)address=(.*)/,
    all: /https:\/\/maps.googleapis.com\/*/
  }

  def stub_normal_request(fake_response)
    # geocoding query, used in reversing gps
    stub_request(:any, URL_REGEX[:geocoding_by_gps]).to_return(
      status: 200,
      body: fake_response[:address][:geocoding_response].to_json)
    # near by gas station query
    stub_request(:any, URL_REGEX[:nearby]).to_return(
      status: 200,
      body: fake_response[:nearest_gas_station_response].to_json)
    # geocoding query, used in formatting address
    stub_request(:any, URL_REGEX[:geocoding_by_address]).to_return(
      status: 200,
      body: fake_response[:address][:geocoding_response].to_json)
  end

  def stub_error_request(type)
    stub_request(:any, URL_REGEX[type]).to_return(status: [500, 'Internal Server Error'])
  end

end
