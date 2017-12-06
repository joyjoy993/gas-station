module ModelConcern
  require 'open-uri'
  extend ActiveSupport::Concern

  def format_url_and_return_json_response(base_url, *params)
    formatted_url = URI.encode(base_url % params)
    begin
      response = open(formatted_url).read
    rescue OpenURI::HTTPError => error
      error_response = error.io
      message = error_response.status[1]
      log_message = format('%s when fetching %s', message, formatted_url)
      raise NearestGasErrors::CustomError.new(_log_message: log_message)
    end
    return {
      data: JSON.parse(response),
      url: formatted_url
    }
  end

end