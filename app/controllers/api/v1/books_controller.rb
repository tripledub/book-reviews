module Api
  module V1
    class BooksController < ApplicationController
      def index
        books = BookService.all_books
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
        book = BookService.find_book(params[:id])
        render json: book.as_json(include: :reviews)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Book not found" }, status: :not_found
      end

      def search
        result = BookService.search_books(params[:q])
        if result[:success]
          render json: result[:books].as_json(include: :reviews)
        else
          render json: { error: result[:error] }, status: :bad_request
        end
      end

      private

      def book_params
        params.require(:book).permit(:title, :author, :image, subjects: [], languages: [])
      end
    end
  end
end
