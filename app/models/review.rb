class Review < ApplicationRecord
  # Constants for score ranges
  MIN_SCORE = 1
  MAX_SCORE = 5
  HIGH_RATED_THRESHOLD = 4
  LOW_RATED_THRESHOLD = 2

  belongs_to :book

  validates :title, presence: true
  validates :description, presence: true
  validates :score, presence: true, inclusion: { in: MIN_SCORE..MAX_SCORE }
end
