module Errors
  class GoogleMapApiError < CustomError
    GOOGLE_MAP_API_ERROR_STATUS_MAPPING = {
        ZERO_RESULTS: {
            status: 404,
            message: 'The geocode was successful but returned no results. 
                    This may occur if the geocoder was passed a non-existent address.'
        },
        OVER_QUERY_LIMIT: {
            status: 500,
            message: 'Over query quota.'
        },
        REQUEST_DENIED: {
            status: 500,
            message: 'Request was denied.'
        },
        INVALID_REQUEST: {
            status: 404,
            message: 'The query (address, components or latlng) is missing.'
        },
        UNKNOWN_ERROR: {
            status: 404,
            message: 'The request could not be processed due to a server error. 
                    The request may succeed if you try again.'
        }
    }
    def initialize(_status)
        status = GOOGLE_MAP_API_ERROR_STATUS_MAPPING[_status.to_sym][:status]
        message = GOOGLE_MAP_API_ERROR_STATUS_MAPPING[_status.to_sym][:message]
      super('Google map api error', status, message)
    end
  end
end