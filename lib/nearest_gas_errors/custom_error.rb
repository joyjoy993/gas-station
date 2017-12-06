# Credit to 'https://medium.com/rails-ember-beyond/error-handling-in-rails-the-modular-way-9afcddd2fe1b'

module NearestGasErrors
  class CustomError < StandardError
    attr_reader :status_code, :message, :log_message

    def initialize(_status_code=nil, _message=nil, _log_message=nil)
      @status_code = _status_code || 500
      @message = _message || 'Internal Server Error'
      @log_message = _log_message || 'Error'
    end
    
  end
end