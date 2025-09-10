module Response
  def json_response(object, status = :ok)
    render json: object, status: status
  end

  def json_response_with_pagination(object, pagy_object, status = :ok)
    render json: {
      pagy: {
        count: pagy_object.count,
        page: pagy_object.page,
        pages: pagy_object.pages,
        limit: pagy_object.limit,
        from: pagy_object.from,
        to: pagy_object.to,
        prev: pagy_object.prev,
        next: pagy_object.next
      },
      books: object
    }, status: status
  end
end
