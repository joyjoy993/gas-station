class NearestGasController < ApplicationController
  attr_accessor :lat, :lng

  before_action :validate_params

  def show
    nearest_gas_station = NearestGasStation.new(@lat, @lng)
    nearest_gas_station_result = nearest_gas_station.get_result()
    render_json(nearest_gas_station_result, 200)
  end

  private

  def validate_params
    permitted = params.permit(:lat, :lng)
    @lat = permitted[:lat]
    @lng = permitted[:lng]
    location = NearestGasValidators::GpsValidator.new(@lat, @lng)
    unless location.valid?
      raise Errors::CustomError.new('Error', 422, 'Invalid paramters')
    end
  end
  
end
