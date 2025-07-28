import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { Book } from '../types'

const Books: React.FC = () => {
  const [books, setBooks] = useState<Book[]>([])
  const [loading, setLoading] = useState<boolean>(true)
  const [error, setError] = useState<string | null>(null)
  const [searchQuery, setSearchQuery] = useState<string>('')

  useEffect(() => {
    fetchBooks()
  }, [])

  const fetchBooks = async (query: string = ''): Promise<void> => {
    try {
      setLoading(true)
      const url = query 
        ? `/api/v1/books/search?q=${encodeURIComponent(query)}`
        : '/api/v1/books'
      
      const response = await fetch(url)
      if (!response.ok) throw new Error('Failed to fetch books')
      
      const data: Book[] = await response.json()
      setBooks(data)
      setError(null)
    } catch (err) {
      setError('Failed to load books')
      console.error('Error fetching books:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleSearch = (e: React.FormEvent<HTMLFormElement>): void => {
    e.preventDefault()
    fetchBooks(searchQuery)
  }

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <div className="text-red-600 text-lg">{error}</div>
        <button 
          onClick={() => fetchBooks()} 
          className="mt-4 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          Try Again
        </button>
      </div>
    )
  }

  return (
    <div>
      {/* Search Bar */}
      <div className="mb-8">
        <form onSubmit={handleSearch} className="flex gap-4">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search books by title or author..."
            className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
          <button
            type="submit"
            className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Search
          </button>
          {searchQuery && (
            <button
              type="button"
              onClick={() => {
                setSearchQuery('')
                fetchBooks()
              }}
              className="px-6 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600 transition-colors"
            >
              Clear
            </button>
          )}
        </form>
      </div>

      {/* Books Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {books.map((book) => (
          <Link
            key={book.id}
            to={`/books/${book.id}`}
            className="bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow duration-200 overflow-hidden"
          >
            <div className="aspect-w-3 aspect-h-4">
              {book.image ? (
                <img
                  src={book.image}
                  alt={book.title}
                  className="w-full h-64 object-cover"
                  onError={(e) => {
                    const target = e.target as HTMLImageElement
                    target.src = 'https://via.placeholder.com/300x400?text=No+Image'
                  }}
                />
              ) : (
                <div className="w-full h-64 bg-gray-200 flex items-center justify-center">
                  <span className="text-gray-500">No Image</span>
                </div>
              )}
            </div>
            <div className="p-4">
              <h3 className="font-semibold text-lg text-gray-900 mb-2 line-clamp-2">
                {book.title}
              </h3>
              <p className="text-gray-600 mb-2">by {book.author}</p>
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <span className="text-sm text-gray-500">
                    {book.reviews?.length || 0} reviews
                  </span>
                </div>
                {book.reviews?.length > 0 && (
                  <div className="flex items-center">
                    <span className="text-yellow-500">★</span>
                    <span className="text-sm text-gray-600 ml-1">
                      {(book.reviews.reduce((sum, review) => sum + review.score, 0) / book.reviews.length).toFixed(1)}
                    </span>
                  </div>
                )}
              </div>
            </div>
          </Link>
        ))}
      </div>

      {books.length === 0 && !loading && (
        <div className="text-center py-12">
          <div className="text-gray-500 text-lg">
            {searchQuery ? 'No books found matching your search.' : 'No books available.'}
          </div>
        </div>
      )}
    </div>
  )
}

export default Books 