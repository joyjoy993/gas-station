# Credit to 'https://medium.com/rails-ember-beyond/error-handling-in-rails-the-modular-way-9afcddd2fe1b'

module NearestGasErrors
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