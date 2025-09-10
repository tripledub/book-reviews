module Api
  module V1
    class BooksController < ApplicationController
      include Response
      include ExceptionHandler

      expose :books, -> { BookService.all_books }
      expose :book, -> { BookService.find_book(params[:id]) }
      expose :search_result, -> { BookService.search_books(params[:q]) }

      def index
        json_response(books.as_json(include: :reviews))
      end

      def create
        save_book
      end

      def show
        json_response(book.as_json(include: :reviews))
      end

      def search
        if search_result[:success]
          json_response(search_result[:books].as_json(include: :reviews))
        else
          json_response({ error: search_result[:error] }, :bad_request)
        end
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
