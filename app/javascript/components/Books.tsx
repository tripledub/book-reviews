import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { Book, PaginationMeta } from '../types'
import SearchBar from './SearchBar'

const Books: React.FC = () => {
  const [books, setBooks] = useState<Book[]>([])
  const [pagination, setPagination] = useState<PaginationMeta | null>(null)
  const [loading, setLoading] = useState<boolean>(true)
  const [error, setError] = useState<string | null>(null)
  const [currentPage, setCurrentPage] = useState<number>(1)

  useEffect(() => {
    fetchBooks()
  }, [currentPage])

  const fetchBooks = async (query: string = '', page: number = 1): Promise<void> => {
    try {
      setLoading(true)
      const url = query 
        ? `/api/v1/books/search?q=${encodeURIComponent(query)}`
        : `/api/v1/books?page=${page}`
      
      const response = await fetch(url)
      if (!response.ok) throw new Error('Failed to fetch books')
      
      const data = await response.json()
      
      // Defensive programming: ensure books is an array
      if (data && Array.isArray(data.books)) {
        setBooks(data.books)
        setPagination(data.pagy)
        setError(null)
      } else {
        console.error('Invalid response structure:', data)
        setError('Invalid response format')
        setBooks([])
        setPagination(null)
      }
    } catch (err) {
      setError('Failed to load books')
      console.error('Error fetching books:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleSearch = (query: string): void => {
    setCurrentPage(1) // Reset to first page when searching
    fetchBooks(query, 1)
  }

  const handlePageChange = (page: number): void => {
    setCurrentPage(page)
    fetchBooks('', page)
  }

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div data-testid="loading-spinner" className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
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
      <SearchBar
        onSearch={handleSearch}
        onClear={() => fetchBooks()}
        placeholder="Search books by title or author..."
      />

      {/* Books Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {Array.isArray(books) && books.map((book) => (
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

      {Array.isArray(books) && books.length === 0 && !loading && (
        <div className="text-center py-12">
          <div className="text-gray-500 text-lg">
            No books available.
          </div>
        </div>
      )}

      {/* Pagination Controls */}
      {pagination && pagination.pages > 1 && (
        <div className="mt-8 flex justify-center items-center space-x-2">
          {/* Previous Button */}
          <button
            onClick={() => handlePageChange(pagination.page - 1)}
            disabled={!pagination.prev}
            className={`px-3 py-2 rounded-md text-sm font-medium ${
              pagination.prev
                ? 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
                : 'bg-gray-100 text-gray-400 cursor-not-allowed'
            }`}
          >
            Previous
          </button>

          {/* Page Numbers */}
          {Array.from({ length: pagination.pages }, (_, i) => i + 1).map((page) => (
            <button
              key={page}
              onClick={() => handlePageChange(page)}
              className={`px-3 py-2 rounded-md text-sm font-medium ${
                page === pagination.page
                  ? 'bg-blue-600 text-white'
                  : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
              }`}
            >
              {page}
            </button>
          ))}

          {/* Next Button */}
          <button
            onClick={() => handlePageChange(pagination.page + 1)}
            disabled={!pagination.next}
            className={`px-3 py-2 rounded-md text-sm font-medium ${
              pagination.next
                ? 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
                : 'bg-gray-100 text-gray-400 cursor-not-allowed'
            }`}
          >
            Next
          </button>
        </div>
      )}

      {/* Pagination Info */}
      {pagination && (
        <div className="mt-4 text-center text-sm text-gray-600">
          Showing {pagination.from} to {pagination.to} of {pagination.count} books
        </div>
      )}
    </div>
  )
}

export default Books 