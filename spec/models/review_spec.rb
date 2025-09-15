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

  describe 'constants' do
    it 'defines MIN_SCORE' do
      expect(Review::MIN_SCORE).to eq(1)
    end

    it 'defines MAX_SCORE' do
      expect(Review::MAX_SCORE).to eq(5)
    end

    it 'defines HIGH_RATED_THRESHOLD' do
      expect(Review::HIGH_RATED_THRESHOLD).to eq(4)
    end

    it 'defines LOW_RATED_THRESHOLD' do
      expect(Review::LOW_RATED_THRESHOLD).to eq(2)
    end
  end

  describe 'database constraints' do
    it 'prevents NULL title at database level' do
      expect {
        Review.connection.execute("INSERT INTO reviews (description, score, book_id, created_at, updated_at) VALUES ('Great book', 5, #{book.id}, NOW(), NOW())")
      }.to raise_error(ActiveRecord::NotNullViolation, /null value in column "title"/)
    end

    it 'prevents NULL description at database level' do
      expect {
        Review.connection.execute("INSERT INTO reviews (title, score, book_id, created_at, updated_at) VALUES ('Great Book', 5, #{book.id}, NOW(), NOW())")
      }.to raise_error(ActiveRecord::NotNullViolation, /null value in column "description"/)
    end

    it 'prevents NULL score at database level' do
      expect {
        Review.connection.execute("INSERT INTO reviews (title, description, book_id, created_at, updated_at) VALUES ('Great Book', 'Great book', #{book.id}, NOW(), NOW())")
      }.to raise_error(ActiveRecord::NotNullViolation, /null value in column "score"/)
    end

    it 'prevents score below 1 at database level' do
      expect {
        Review.connection.execute("INSERT INTO reviews (title, description, score, book_id, created_at, updated_at) VALUES ('Great Book', 'Great book', 0, #{book.id}, NOW(), NOW())")
      }.to raise_error(ActiveRecord::StatementInvalid, /violates check constraint "reviews_score_range"/)
    end

    it 'prevents score above 5 at database level' do
      expect {
        Review.connection.execute("INSERT INTO reviews (title, description, score, book_id, created_at, updated_at) VALUES ('Great Book', 'Great book', 6, #{book.id}, NOW(), NOW())")
      }.to raise_error(ActiveRecord::StatementInvalid, /violates check constraint "reviews_score_range"/)
    end

    it 'prevents empty title at database level' do
      expect {
        Review.connection.execute("INSERT INTO reviews (title, description, score, book_id, created_at, updated_at) VALUES ('   ', 'Great book', 5, #{book.id}, NOW(), NOW())")
      }.to raise_error(ActiveRecord::StatementInvalid, /violates check constraint "reviews_title_not_empty"/)
    end

    it 'prevents empty description at database level' do
      expect {
        Review.connection.execute("INSERT INTO reviews (title, description, score, book_id, created_at, updated_at) VALUES ('Great Book', '   ', 5, #{book.id}, NOW(), NOW())")
      }.to raise_error(ActiveRecord::StatementInvalid, /violates check constraint "reviews_description_not_empty"/)
    end

    it 'allows valid score range at database level' do
      expect {
        Review.connection.execute("INSERT INTO reviews (title, description, score, book_id, created_at, updated_at) VALUES ('Great Book', 'Great book', 3, #{book.id}, NOW(), NOW())")
      }.not_to raise_error
    end
  end

  describe 'cache invalidation callbacks' do
    describe '#invalidate_book_related_cache' do
      it 'can be called without error' do
        review = Review.new(
          title: 'Great Book',
          description: 'This is a wonderful book',
          score: 5,
          book: book
        )

        # Test that the method can be called without error
        expect { review.send(:invalidate_book_related_cache) }.not_to raise_error
      end
    end

    describe 'callback methods' do
      it 'calls invalidate_book_related_cache on after_create' do
        review = Review.new(
          title: 'Great Book',
          description: 'This is a wonderful book',
          score: 5,
          book: book
        )

        expect(review).to receive(:invalidate_book_related_cache)
        review.send(:invalidate_cache_after_create)
      end

      it 'calls invalidate_book_related_cache on after_update' do
        review = Review.new(
          title: 'Great Book',
          description: 'This is a wonderful book',
          score: 5,
          book: book
        )

        expect(review).to receive(:invalidate_book_related_cache)
        review.send(:invalidate_cache_after_update)
      end

      it 'calls invalidate_book_related_cache on after_destroy' do
        review = Review.new(
          title: 'Great Book',
          description: 'This is a wonderful book',
          score: 5,
          book: book
        )

        expect(review).to receive(:invalidate_book_related_cache)
        review.send(:invalidate_cache_after_destroy)
      end
    end
  end
end
