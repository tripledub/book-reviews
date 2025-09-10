module Api
  module V1
    class ReviewsController < ApplicationController
      include Response
      include ExceptionHandler

      def create
        save_review
      end

      private

      def save_review
        review = ReviewService.create_review(review_params)
        json_response(review.as_json(include: :book), :created)
      end

      def review_params
        params.require(:review).permit(:title, :description, :score, :book_id)
      end
    end
  end
end
