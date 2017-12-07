require 'rails_helper'
require 'database_cleaner'
require 'factories/google_map_api_fake_response'
include GoogleMapApiFakeResponse

RSpec.describe Location, type: :model do

  before(:all) do
    Location.create_indexes
    DatabaseCleaner.strategy = :truncation
  end

  before(:each) do
    DatabaseCleaner.clean
    fake_response = fake_a_response
    fake_gps = fake_response[:fake_gps]
    @fake_location = {
      address: fake_response[:address][:parsed_address],
      nearest_gas_station: fake_response[:nearest_gas_station][:parsed_address],
      gps: [fake_gps[:lng], fake_gps[:lat]]
    }
  end

  it 'test gps validation' do
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

  it 'test gps & time uniqueness' do
    gps = [-122.412049, 37.77790]
    query_time = DateTime.now
    @fake_location[:gps] = gps
    @fake_location[:query_time] = query_time
    location = Location.new(@fake_location)
    location.save!
    location = Location.new(@fake_location)
    expect{ location.save! }.to raise_error(Mongo::Error::OperationFailure, /duplicate key error collection/)
  end

  it 'test empty address' do
    @fake_location.delete(:address)
    location = Location.new(@fake_location)
    location.valid?
    expect( location.errors[:address] ).to include("can't be blank")
  end

  it 'test empty nearest_gas_station' do
    @fake_location.delete(:nearest_gas_station)
    location = Location.new(@fake_location)
    location.valid?
    expect( location.errors[:nearest_gas_station] ).to include("can't be blank")
  end

end
