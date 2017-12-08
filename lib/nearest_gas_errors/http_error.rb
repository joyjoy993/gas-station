module NearestGasErrors
  class HttpError < CustomError
    def initialize(log_message)
      super(500, 'Internal Server Error', log_message)
    end
  end
end