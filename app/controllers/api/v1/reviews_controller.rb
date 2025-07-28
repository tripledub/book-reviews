module Api
  module V1
    class ReviewsController < ApplicationController
      def create
        review = Review.new(review_params)
        if review.save
          render json: review.as_json(include: :book), status: :created
        else
          render json: { errors: review.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActionController::ParameterMissing
        render json: { error: "Review parameters are required" }, status: :bad_request
      end

      private

      def review_params
        params.require(:review).permit(:title, :description, :score, :book_id)
      end
    end
  end
end 