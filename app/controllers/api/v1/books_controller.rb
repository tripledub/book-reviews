module Api
  module V1
    class BooksController < ApplicationController
      include Response
      include ExceptionHandler

      expose :book, -> { BookService.find_book(params[:id]) }
      expose :search_results, -> { BookService.search_books(params[:q]) }
      expose :books_collection, -> { BookService.paginated_books }

      def index
        pagy_object, books_array = pagy(books_collection)
        json_response({
          pagy: pagy_metadata(pagy_object),
          books: books_array.as_json(include: :reviews)
        })
      end

      def create
        save_book
      end

      def show
        json_response(book.as_json(include: :reviews))
      end

      def search
        json_response({
          books: search_results.as_json(include: :reviews)
        })
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
