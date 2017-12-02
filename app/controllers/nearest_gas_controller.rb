require 'open-uri'

class NearestGasController < ApplicationController

  def index
    permitted = params.permit(:lat, :lng)
    lat = permitted[:lat]
    lng = permitted[:lng]
    location = Location.new
    nearest_gas_station = location.fetch_nearest_gas_station(lat, lng)
    address = location.fetch_address(lat, lng)

    render json: {
      address: address,
      nearest_gas_station: nearest_gas_station
    }, status: 200
  end
end
