module NearestGasErrors
  class InvalidParametersError < CustomError
    def initialize
      super(422, 'Invalid parameters', 'Invalid parameters')
    end
  end
end