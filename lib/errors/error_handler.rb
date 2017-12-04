module Errors
  module ErrorHandler
    def self.included(clazz)
      clazz.class_eval do
        rescue_from CustomError do |e|
          respond(e.error, e.status, e.message)
        end
      end
    end

    private
    def respond(error, status, message)
      render_json({
          error: error,
          message: message
        }, status)
    end
  end
end