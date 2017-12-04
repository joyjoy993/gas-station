class ApplicationController < ActionController::API
    include Errors::ErrorHandler
    include ControllerConcern
end
