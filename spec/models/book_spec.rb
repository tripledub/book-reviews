require 'rails_helper'

RSpec.describe Book, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      book = Book.new(
        title: 'Test Book',
        author: 'Test Author',
        subjects: [ 'Fiction' ],
        languages: [ 'en' ],
        image: 'https://example.com/image.jpg'
      )
      expect(book).to be_valid
    end

    it 'is not valid without a title' do
      book = Book.new(
        author: 'Test Author',
        subjects: [ 'Fiction' ],
        languages: [ 'en' ]
      )
      expect(book).not_to be_valid
      expect(book.errors[:title]).to include("can't be blank")
    end

    it 'is not valid without an author' do
      book = Book.new(
        title: 'Test Book',
        subjects: [ 'Fiction' ],
        languages: [ 'en' ]
      )
      expect(book).not_to be_valid
      expect(book.errors[:author]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it 'has many reviews' do
      book = Book.reflect_on_association(:reviews)
      expect(book.macro).to eq :has_many
    end
  end

  describe 'attributes' do
    it 'can store subjects as an array' do
      book = Book.create!(
        title: 'Test Book',
        author: 'Test Author',
        subjects: [ 'Fiction', 'Adventure' ],
        languages: [ 'en' ]
      )
      expect(book.subjects).to eq([ 'Fiction', 'Adventure' ])
    end

    it 'can store languages as an array' do
      book = Book.create!(
        title: 'Test Book',
        author: 'Test Author',
        subjects: [ 'Fiction' ],
        languages: [ 'en', 'fr' ]
      )
      expect(book.languages).to eq([ 'en', 'fr' ])
    end
  end

  describe 'database constraints' do
    it 'prevents NULL title at database level' do
      expect {
        Book.connection.execute("INSERT INTO books (author, created_at, updated_at) VALUES ('Test Author', NOW(), NOW())")
      }.to raise_error(ActiveRecord::NotNullViolation, /null value in column "title"/)
    end

    it 'prevents NULL author at database level' do
      expect {
        Book.connection.execute("INSERT INTO books (title, created_at, updated_at) VALUES ('Test Book', NOW(), NOW())")
      }.to raise_error(ActiveRecord::NotNullViolation, /null value in column "author"/)
    end

    # Note: Array constraints are more complex to test due to PostgreSQL array handling
    # The constraints are in place but testing them requires more sophisticated setup

    it 'prevents invalid image URL format at database level' do
      expect {
        Book.connection.execute("INSERT INTO books (title, author, image, created_at, updated_at) VALUES ('Test Book', 'Test Author', 'invalid-url', NOW(), NOW())")
      }.to raise_error(ActiveRecord::StatementInvalid, /violates check constraint "books_image_url_format"/)
    end

    it 'allows valid image URL format' do
      expect {
        Book.connection.execute("INSERT INTO books (title, author, image, created_at, updated_at) VALUES ('Test Book', 'Test Author', 'https://example.com/image.jpg', NOW(), NOW())")
      }.not_to raise_error
    end

    it 'allows NULL image' do
      expect {
        Book.connection.execute("INSERT INTO books (title, author, created_at, updated_at) VALUES ('Test Book', 'Test Author', NOW(), NOW())")
      }.not_to raise_error
    end
  end
end
