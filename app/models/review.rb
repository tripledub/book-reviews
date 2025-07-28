class Review < ApplicationRecord
  belongs_to :book

  validates :title, presence: true
  validates :description, presence: true
  validates :score, presence: true, inclusion: { in: 1..5 }
end
