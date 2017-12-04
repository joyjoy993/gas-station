require 'open-uri'

class NearestGasController < ApplicationController

  def show
    permitted = params.permit(:lat, :lng)
    lat = permitted[:lat]
    lng = permitted[:lng]
    location = Location.new
    location_result = location.fetch_and_create_location(lat, lng)
    render_json(location_result, 200)
  end
  
end
