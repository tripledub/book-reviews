require 'rails_helper'

RSpec.describe Review, type: :model do
  let(:book) { Book.create!(title: 'Test Book', author: 'Test Author', subjects: [ 'Fiction' ], languages: [ 'en' ]) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      review = Review.new(
        title: 'Great Book',
        description: 'This is a wonderful book',
        score: 5,
        book: book
      )
      expect(review).to be_valid
    end

    it 'is not valid without a title' do
      review = Review.new(
        description: 'This is a wonderful book',
        score: 5,
        book: book
      )
      expect(review).not_to be_valid
      expect(review.errors[:title]).to include("can't be blank")
    end

    it 'is not valid without a description' do
      review = Review.new(
        title: 'Great Book',
        score: 5,
        book: book
      )
      expect(review).not_to be_valid
      expect(review.errors[:description]).to include("can't be blank")
    end

    it 'is not valid without a score' do
      review = Review.new(
        title: 'Great Book',
        description: 'This is a wonderful book',
        book: book
      )
      expect(review).not_to be_valid
      expect(review.errors[:score]).to include("can't be blank")
    end

    it 'is not valid with a score below 1' do
      review = Review.new(
        title: 'Great Book',
        description: 'This is a wonderful book',
        score: 0,
        book: book
      )
      expect(review).not_to be_valid
      expect(review.errors[:score]).to include('is not included in the list')
    end

    it 'is not valid with a score above 5' do
      review = Review.new(
        title: 'Great Book',
        description: 'This is a wonderful book',
        score: 6,
        book: book
      )
      expect(review).not_to be_valid
      expect(review.errors[:score]).to include('is not included in the list')
    end

    it 'is valid with score 1' do
      review = Review.new(
        title: 'Great Book',
        description: 'This is a wonderful book',
        score: 1,
        book: book
      )
      expect(review).to be_valid
    end

    it 'is valid with score 5' do
      review = Review.new(
        title: 'Great Book',
        description: 'This is a wonderful book',
        score: 5,
        book: book
      )
      expect(review).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a book' do
      review = Review.reflect_on_association(:book)
      expect(review.macro).to eq :belongs_to
    end
  end
end
