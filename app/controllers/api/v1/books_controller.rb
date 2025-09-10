module Api
  module V1
    class BooksController < ApplicationController
      expose :books, -> { BookService.all_books }
      expose :book, -> { BookService.find_book(params[:id]) }
      expose :search_result, -> { BookService.search_books(params[:q]) }

      def index
        render json: books.as_json(include: :reviews)
      end

      def create
        result = BookService.create_book(book_params)
        if result[:success]
          render json: result[:book].as_json(include: :reviews), status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      def show
        render json: book.as_json(include: :reviews)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Book not found" }, status: :not_found
      end

      def search
        if search_result[:success]
          render json: search_result[:books].as_json(include: :reviews)
        else
          render json: { error: search_result[:error] }, status: :bad_request
        end
      end

      private

      def book_params
        params.require(:book).permit(:title, :author, :image, subjects: [], languages: [])
      end
    end
  end
end
