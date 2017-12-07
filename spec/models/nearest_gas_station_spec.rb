require 'rails_helper'
require 'database_cleaner'
require 'factories/google_map_api_fake_response'
require 'helpers/stub_request_helper'
require 'helpers/location_helper'
include GoogleMapApiFakeResponse
include StubRequestHelper
include LocationHelper

RSpec.describe NearestGasStation, type: :model do

  before(:all) do
    Location.create_indexes
    DatabaseCleaner.strategy = :truncation
  end

  before(:each) do
    DatabaseCleaner.clean
    stub_normal_request(fake_a_response)
  end

  it 'Normal query and create data in database' do
    fake_gps = fake_gps_pair
    nearest_gas_station = NearestGasStation.new(fake_gps[:lat], fake_gps[:lng])
    nearest_gas_station.get_result()
    expect(Location.where(gps: [fake_gps[:lng], fake_gps[:lat]])).to be_present
  end

  it 'Caching: same gps' do
    fake_gps = fake_gps_pair
    first_nearest_gas_station = NearestGasStation.new(fake_gps[:lat], fake_gps[:lng])
    first_nearest_gas_station.get_result()
    second_nearest_gas_station = NearestGasStation.new(fake_gps[:lat], fake_gps[:lng])
    second_nearest_gas_station.get_result()
    expect(Location.where(gps: [fake_gps[:lng], fake_gps[:lat]]).count).to eq(1)
  end

  it 'Caching: nearby gps' do
    first_gps_pair = [-122.412049, 37.77790]
    second_gps_pair = [-122.412049, 37.77791] # nearby gps
    first_nearest_gas_station = NearestGasStation.new(first_gps_pair[1], first_gps_pair[0])
    first_nearest_gas_station.get_result()
    first_nearest_gas_station_result = Location.where(gps: first_gps_pair).first.nearest_gas_station
    # deny nearby request
    # if it uses cached nearest_gas_station, the nearby api won't be hit
    # if not, it will raise the exception, and then the case fail
    stub_error_request(:nearby)
    second_nearest_gas_station = NearestGasStation.new(second_gps_pair[1], second_gps_pair[0])
    second_nearest_gas_station.get_result()
    second_nearest_gas_station_result = Location.where(gps: second_gps_pair).first.nearest_gas_station
    expect(second_nearest_gas_station_result).to eq(first_nearest_gas_station_result)
  end

  it 'Caching: cached address data is stale' do
    # if data is not stale, the same gps query will return cached data
    # else create a new data
    fake_location = fake_a_location_document
    # stale day is 3 days, can be changed in nearest_gas_station.rb
    fake_location[:query_time] = 259202.seconds.ago # 259200 seconds is 3 days
    fake_gps = fake_location[:gps]
    location = Location.new(fake_location)
    location.save!
    nearest_gas_station = NearestGasStation.new(fake_gps[1], fake_gps[0])
    nearest_gas_station.get_result()
    expect(Location.where(gps: fake_gps).count).to eq(2)
  end

end
