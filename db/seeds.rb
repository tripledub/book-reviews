require 'net/http'
require 'json'

puts 'Fetching books from Gutendex...'
url = URI('https://gutendex.com/books/?page=1')
response = Net::HTTP.get(url)
books = JSON.parse(response)["results"]

books.each do |book_data|
  book = Book.create!(
    title: book_data["title"],
    author: book_data["authors"].first&.dig("name") || "Unknown",
    subjects: book_data["subjects"],
    languages: book_data["languages"],
    image: book_data["formats"]["image/jpeg"]
  )

  # Add 2 sample reviews for each book
  2.times do |i|
    Review.create!(
      book: book,
      title: "Sample Review #{i+1} for #{book.title}",
      description: "This is a test review for #{book.title}.",
      score: rand(1..5)
    )
  end
end

puts 'Seeding complete!'
