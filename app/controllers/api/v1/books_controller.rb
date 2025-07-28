module Api
  module V1
    class BooksController < ApplicationController
      def index
        books = Book.includes(:reviews).all
        render json: books.as_json(include: :reviews)
      end

      def create
        book = Book.new(book_params)
        if book.save
          render json: book.as_json(include: :reviews), status: :created
        else
          render json: { errors: book.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def show
        book = Book.includes(:reviews).find(params[:id])
        render json: book.as_json(include: :reviews)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Book not found" }, status: :not_found
      end

      def search
        query = params[:q]
        if query.present?
          books = Book.includes(:reviews)
                      .where("title ILIKE ? OR author ILIKE ?", "%#{query}%", "%#{query}%")
          render json: books.as_json(include: :reviews)
        else
          render json: { error: "Search query is required" }, status: :bad_request
        end
      end

      private

      def book_params
        params.require(:book).permit(:title, :author, :image, subjects: [], languages: [])
      end
    end
  end
end
