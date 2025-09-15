module Api
  module V1
    class ReviewsController < ApplicationController
      include Response
      include ExceptionHandler

      expose :review, -> { Review.find(params[:id]) }
      expose :reviews_collection, -> { ReviewService.paginated_reviews }
      expose :search_results, -> { ReviewService.search_reviews(params[:q]) }

      def index
        pagy_object, reviews_array = pagy(reviews_collection)
        json_response({
          pagy: pagy_metadata(pagy_object),
          reviews: reviews_array.as_json(include: :book)
        })
      end

      def create
        save_review
      end

      def show
        json_response(review.as_json(include: :book))
      end

      def search
        pagy_object, reviews_array = pagy(search_results)
        json_response({
          pagy: pagy_metadata(pagy_object),
          reviews: reviews_array.as_json(include: :book)
        })
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
