require 'rails_helper'
require 'database_cleaner'

RSpec.describe Location, type: :model do

  before(:all) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
    Location.create_indexes
  end

  before(:each) do
    @location_without_gps = {
      address: {
        streetAddress: "1155 Mission Street", 
        city: "San Francisco", 
        state: "CA", 
        postalCode: "94103-1514"
      },
      nearest_gas_station: {
        streetAddress: "1298 Howard Street", 
        city: "San Francisco", 
        state: "CA", 
        postalCode: "94103-2712"
      }
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
      @location_without_gps['gps'] = gps
      location = Location.new(@location_without_gps)
      location.valid?
      expect( location.errors[:gps] ).to include('Invalid gps pair')
    end
  end

  it 'test gps & time uniqueness' do
    gps = [-122.412049, 37.77790]
    query_time = DateTime.now
    @location_without_gps['gps'] = gps
    @location_without_gps['query_time'] = query_time
    location = Location.new(@location_without_gps)
    location.save!
    location = Location.new(@location_without_gps)
    expect{ location.save! }.to raise_error(Mongo::Error::OperationFailure, /duplicate key error collection/)
  end

  it 'test empty address' do
    location_without_address = {
      gps: [-122.412043, 37.77790],
      nearest_gas_station: {
        streetAddress: "1298 Howard Street", 
        city: "San Francisco", 
        state: "CA", 
        postalCode: "94103-2712"
      }
    }
    location = Location.new(location_without_address)
    location.valid?
    expect( location.errors[:address] ).to include("can't be blank")
  end

  it 'test empty nearest_gas_station' do
    location_without_nearest_gas_station = {
      gps: [-122.412043, 37.77790],
      address: {
        streetAddress: "1155 Mission Street", 
        city: "San Francisco", 
        state: "CA", 
        postalCode: "94103-1514"
      }
    }
    location = Location.new(location_without_nearest_gas_station)
    location.valid?
    expect( location.errors[:nearest_gas_station] ).to include("can't be blank")
  end

end
