class ApplicationController < ActionController::Base
  include Response
  include ExceptionHandler
  include Pagy::Backend

  def index
    render "application/index"
  end
end
