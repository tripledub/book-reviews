class Book < ApplicationRecord
  include RatingStatistics
  include BookScopes

  has_many :reviews, dependent: :destroy

  validates :title, presence: true
  validates :author, presence: true
end
