module NearestGasErrors
  class GoogleMapApiError < CustomError
    GOOGLE_MAP_API_ERROR_STATUS_MAPPING = {
      ZERO_RESULTS: 'The geocode was successful but returned no results.
                This may occur if the geocoder was passed a non-existent address.',
      OVER_QUERY_LIMIT: 'Over query quota.',
      REQUEST_DENIED: 'Request was denied.',
      INVALID_REQUEST: 'The query (address, components or latlng) is missing.',
      UNKNOWN_ERROR: 'The request could not be processed due to a server error. 
                The request may succeed if you try again.'
    }
    def initialize(error_status, url)
      message = GOOGLE_MAP_API_ERROR_STATUS_MAPPING[error_status.to_sym]
      # do logging here, "[message] when fetching [url]"
      super(503, 'Service Unavailable')
    end
  end
end