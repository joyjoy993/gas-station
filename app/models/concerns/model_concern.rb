module ModelConcern
  require 'open-uri'
  extend ActiveSupport::Concern

  def format_url_and_return_json_response(base_url, *params)
    formatted_url = URI.encode(base_url % params)
    begin
      response = open(formatted_url).read
    rescue OpenURI::HTTPError => error
      error_response = error.io
      status = error_response[0]
      message = error_response[1]
      raise Errors::CustomError.new('Error', status, message)
    end
    return JSON.parse(response)
  end

end