require 'rails_helper'
require 'database_cleaner'
require 'factories/google_map_api_fake_response'
require 'helpers/stub_request_helper'
require 'helpers/location_helper'
include GoogleMapApiFakeResponse
include StubRequestHelper
include LocationHelper

RSpec.describe Location, type: :model do

  before(:all) do
    Location.create_indexes
    DatabaseCleaner.strategy = :truncation
  end

  before(:each) do
    stub_normal_request(fake_a_response)
    DatabaseCleaner.clean
    @fake_location = fake_a_location_document
  end

  ### testing about field validations

  it 'gps validation' do
    invalid_gps = [
      [-122.41204993, 37.77790], # longitude is over 6 decimal digits
      [-122.412049, 37.73779088], # latitude is over 6 decimal digits
      [-122.41204993, 100], # latitude is over 90 degree
      [-181, 37.77790], # longitude is less than -180 degree
      [181, 37.77790], # longitude is over 180 degree
      [-122.41204993, -91], # latitude is less than -90 degree
    ]
    for gps in invalid_gps
      @fake_location[:gps] = gps
      location = Location.new(@fake_location)
      location.valid?
      expect( location.errors[:gps] ).to include('Invalid gps pair')
    end
  end

  it 'gps & time uniqueness' do
    gps = [-122.412049, 37.77790]
    query_time = DateTime.now
    @fake_location[:gps] = gps
    @fake_location[:query_time] = query_time
    location = Location.new(@fake_location)
    location.save!
    location = Location.new(@fake_location)
    expect{ location.save! }.to raise_error(Mongo::Error::OperationFailure, /duplicate key error collection/)
  end

  it 'normal data insertion' do
    10.times do
      fake_location = fake_a_location_document
      location = Location.new(fake_location)
      location.save!
      expect(Location.where(gps: fake_location[:gps]).count).to eq(1)
    end
  end

  ### testing about bussiness logic

  it 'Normal query and create data in database' do
    fake_gps = fake_gps_pair
    nearest_gas_station = Location.new
    nearest_gas_station.get_result(fake_gps[:lat], fake_gps[:lng])
    expect(Location.where(gps: [fake_gps[:lng], fake_gps[:lat]])).to be_present
  end

  it 'Caching: same gps' do
    fake_gps = fake_gps_pair
    first_nearest_gas_station = Location.new
    first_nearest_gas_station.get_result(fake_gps[:lat], fake_gps[:lng])
    second_nearest_gas_station = Location.new
    second_nearest_gas_station.get_result(fake_gps[:lat], fake_gps[:lng])
    expect(Location.where(gps: [fake_gps[:lng], fake_gps[:lat]]).count).to eq(1)
  end

  it 'Caching: nearby gps' do
    first_gps_pair = [-122.412049, 37.77790]
    second_gps_pair = [-122.412049, 37.77791] # nearby gps
    first_nearest_gas_station = Location.new
    first_nearest_gas_station.get_result(first_gps_pair[1], first_gps_pair[0])
    first_nearest_gas_station_result = Location.where(gps: first_gps_pair).first.nearest_gas_station
    # deny nearby request
    # if it uses cached nearest_gas_station, the nearby api won't be hit
    # if not, it will raise the exception, and then the case fail
    stub_error_request(:nearby)
    second_nearest_gas_station = Location.new
    second_nearest_gas_station.get_result(second_gps_pair[1], second_gps_pair[0])
    second_nearest_gas_station_result = Location.where(gps: second_gps_pair).first.nearest_gas_station
    expect(second_nearest_gas_station_result).to eq(first_nearest_gas_station_result)
  end

  it 'Caching: cached address data is stale' do
    # if data is not stale, the same gps query will return cached data
    # else create a new data
    # stale day is 3 days, can be changed in nearest_gas_station.rb
    @fake_location[:query_time] = 259202.seconds.ago # 259200 seconds is 3 days
    fake_gps = @fake_location[:gps]
    location = Location.new(@fake_location)
    location.save!
    nearest_gas_station = Location.new
    nearest_gas_station.get_result(fake_gps[1], fake_gps[0])
    expect(Location.where(gps: fake_gps).count).to eq(2)
  end

end
