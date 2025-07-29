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
end
