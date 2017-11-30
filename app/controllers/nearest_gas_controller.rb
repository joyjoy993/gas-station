class NearestGasController < ApplicationController
  def index
    permitted = params.permit(:lat, :lng)
    lat = permitted[:lat]
    lng = permitted[:lng]
    unless lat && lng
      render json: {
        error: 'params are invalid',
        status: 400
      }, status: 400
      return
    end
    render json: {
        message: 'hello',
        status: 200
      }, status: 200
  end
end
