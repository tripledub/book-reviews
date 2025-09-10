module Api
  module V1
    class ReviewsController < ApplicationController
      expose :review_result, -> { ReviewService.create_review(review_params) }

      def create
        if review_result[:success]
          render json: review_result[:review].as_json(include: :book), status: :created
        else
          render json: { errors: review_result[:errors] }, status: :unprocessable_entity
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
