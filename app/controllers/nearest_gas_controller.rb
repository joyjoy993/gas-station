class NearestGasController < ApplicationController

  before_action :validate_params

  def show
    location = Location.new
    nearest_gas_station_result = location.get_result(@lat, @lng)
    render_json(nearest_gas_station_result, 200)
  end

  private

  def validate_params
    permitted = params.permit(:lat, :lng)
    @lat = permitted[:lat]
    @lng = permitted[:lng]
    gps_validator = NearestGasValidators::GpsValidator.new(@lat, @lng)
    # validate latitude and longitude in url,
    # but without 6 decimal digits limitation
    unless gps_validator.valid_params?
      raise NearestGasErrors::InvalidParametersError.new
    end
  end
  
end
