class ApplicationController < ActionController::Base
  include Response
  include ExceptionHandler

  def index
    render "application/index"
  end
end
