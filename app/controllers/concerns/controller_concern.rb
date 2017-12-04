module ControllerConcern
    extend ActiveSupport::Concern

    def render_json(data, status)
        render json: data, status: status
    end
end