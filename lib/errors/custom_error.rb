module Errors
  class CustomError < StandardError
    attr_reader :status, :error, :message

    def initialize(_error=nil, _status=nil, _message=nil)
      @error = _error || 'Error'
      @status = _status || 500
      @message = _message || 'Something went wrong'
    end
    
  end
end