module Api
  module V1
    class ReviewsController < ApplicationController
      def create
        result = ReviewService.create_review(review_params)
        if result[:success]
          render json: result[:review].as_json(include: :book), status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
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
