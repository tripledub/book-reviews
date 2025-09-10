module ExceptionHandler
  # provides the more graceful `included` method
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound do |e|
      json_response({ message: e.message }, :not_found)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      json_response({ errors: e.record.errors.full_messages }, :unprocessable_content)
    end

    rescue_from ActionController::ParameterMissing do |e|
      json_response({ error: "Required parameters are missing: #{e.param}" }, :bad_request)
    end

    rescue_from ArgumentError do |e|
      json_response({ error: e.message }, :bad_request)
    end
  end
end
