require 'open-uri'

class NearestGasController < ApplicationController

  def show
    permitted = params.permit(:lat, :lng)
    lat = permitted[:lat]
    lng = permitted[:lng]
    nearest_gas_station = NearestGasStation.new(lat, lng)
    nearest_gas_station_result = nearest_gas_station.get_result()
    render_json(nearest_gas_station_result, 200)
  end
  
end
