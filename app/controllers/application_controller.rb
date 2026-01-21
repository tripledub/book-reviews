class ApplicationController < ActionController::Base
  include Response
  include ExceptionHandler
  include Pagy::Backend

  def index
    render "application/index"
  end

  private

  def pagy_metadata(pagy_object)
    {
      count: pagy_object.count,
      page: pagy_object.page,
      pages: pagy_object.pages,
      limit: pagy_object.limit,
      from: pagy_object.from,
      to: pagy_object.to,
      prev: pagy_object.prev,
      next: pagy_object.next
    }
  end
end
