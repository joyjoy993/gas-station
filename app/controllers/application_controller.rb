class ApplicationController < ActionController::API
    include NearestGasErrors::ErrorHandler
    include ControllerConcern
end
