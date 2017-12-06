# Credit to 'https://medium.com/rails-ember-beyond/error-handling-in-rails-the-modular-way-9afcddd2fe1b'

module NearestGasErrors
  module ErrorHandler
    def self.included(clazz)
      clazz.class_eval do
        rescue_from CustomError do |e|
          respond(e.status_code, e.message)
          log_error(e.log_message)
        end
      end
    end

    private
    def respond(status_code, message)
      render_json({
          status_code: status_code,
          message: message
        }, status_code)
    end

    def log_error(log_message)
      Rails.logger.error log_message
    end
  end
end