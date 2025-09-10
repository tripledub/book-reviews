module Api
  module V1
    class BooksController < ApplicationController
      include Response
      include ExceptionHandler

      expose :book, -> { BookService.find_book(params[:id]) }

      def index
        books_collection = BookService.paginated_books
        @pagy, @books = pagy(books_collection)
        json_response_with_pagination(@books.as_json(include: :reviews), @pagy)
      end

      def create
        save_book
      end

      def show
        json_response(book.as_json(include: :reviews))
      end

      def search
        books = BookService.search_books(params[:q])
        json_response(books.as_json(include: :reviews))
      end

      private

      def save_book
        book = BookService.create_book(book_params)
        json_response(book.as_json(include: :reviews), :created)
      end

      def book_params
        params.require(:book).permit(:title, :author, :image, subjects: [], languages: [])
      end
    end
  end
end
