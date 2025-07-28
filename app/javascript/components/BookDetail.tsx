import React, { useState, useEffect } from 'react'
import { useParams, Link, useNavigate } from 'react-router-dom'
import { Book, NewReview } from '../types'

const BookDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [book, setBook] = useState<Book | null>(null)
  const [loading, setLoading] = useState<boolean>(true)
  const [error, setError] = useState<string | null>(null)
  const [newReview, setNewReview] = useState<NewReview>({ title: '', description: '', score: 5 })
  const [submittingReview, setSubmittingReview] = useState<boolean>(false)

  // Get CSRF token from meta tag
  const getCsrfToken = (): string | null => {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || null
  }

  useEffect(() => {
    if (id) {
      fetchBook()
    }
  }, [id])

  const fetchBook = async (): Promise<void> => {
    if (!id) return
    
    try {
      setLoading(true)
      const response = await fetch(`/api/v1/books/${id}`)
      if (!response.ok) throw new Error('Book not found')
      
      const data: Book = await response.json()
      setBook(data)
      setError(null)
    } catch (err) {
      setError('Failed to load book')
      console.error('Error fetching book:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleReviewSubmit = async (e: React.FormEvent<HTMLFormElement>): Promise<void> => {
    e.preventDefault()
    if (!id) return
    
    setSubmittingReview(true)
    
    try {
      const response = await fetch('/api/v1/reviews', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': getCsrfToken() || '',
        },
        body: JSON.stringify({
          review: {
            ...newReview,
            book_id: parseInt(id)
          }
        })
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.errors?.join(', ') || 'Failed to submit review')
      }

      // Reset form and refresh book data
      setNewReview({ title: '', description: '', score: 5 })
      await fetchBook()
    } catch (err) {
      alert(err instanceof Error ? err.message : 'An error occurred')
    } finally {
      setSubmittingReview(false)
    }
  }

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  if (error || !book) {
    return (
      <div className="text-center py-12">
        <div className="text-red-600 text-lg">{error || 'Book not found'}</div>
        <button 
          onClick={() => navigate('/')} 
          className="mt-4 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          Back to Books
        </button>
      </div>
    )
  }

  const averageScore = book.reviews?.length > 0 
    ? (book.reviews.reduce((sum, review) => sum + review.score, 0) / book.reviews.length).toFixed(1)
    : null

  return (
    <div className="space-y-8">
      {/* Back Button */}
      <Link 
        to="/" 
        className="inline-flex items-center text-blue-600 hover:text-blue-800 mb-6"
      >
        ← Back to Books
      </Link>

      {/* Book Details */}
      <div className="bg-white rounded-lg shadow-lg overflow-hidden">
        <div className="md:flex">
          {/* Book Image */}
          <div className="md:w-1/3">
            {book.image ? (
              <img
                src={book.image}
                alt={book.title}
                className="w-full h-96 md:h-full object-cover"
                onError={(e) => {
                  const target = e.target as HTMLImageElement
                  target.src = 'https://via.placeholder.com/400x600?text=No+Image'
                }}
              />
            ) : (
              <div className="w-full h-96 md:h-full bg-gray-200 flex items-center justify-center">
                <span className="text-gray-500">No Image</span>
              </div>
            )}
          </div>

          {/* Book Info */}
          <div className="md:w-2/3 p-6">
            <h1 className="text-3xl font-bold text-gray-900 mb-4">{book.title}</h1>
            <p className="text-xl text-gray-600 mb-4">by {book.author}</p>
            
            {/* Rating */}
            {averageScore && (
              <div className="flex items-center mb-4">
                <div className="flex items-center">
                  {[...Array(5)].map((_, i) => (
                    <span key={i} className="text-yellow-500 text-xl">
                      {i < Math.round(parseFloat(averageScore)) ? '★' : '☆'}
                    </span>
                  ))}
                </div>
                <span className="ml-2 text-gray-600">
                  {averageScore} ({book.reviews.length} reviews)
                </span>
              </div>
            )}

            {/* Subjects */}
            {book.subjects?.length > 0 && (
              <div className="mb-4">
                <h3 className="font-semibold text-gray-900 mb-2">Subjects:</h3>
                <div className="flex flex-wrap gap-2">
                  {book.subjects.map((subject, index) => (
                    <span 
                      key={index}
                      className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm"
                    >
                      {subject}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Languages */}
            {book.languages?.length > 0 && (
              <div className="mb-4">
                <h3 className="font-semibold text-gray-900 mb-2">Languages:</h3>
                <div className="flex flex-wrap gap-2">
                  {book.languages.map((language, index) => (
                    <span 
                      key={index}
                      className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm"
                    >
                      {language}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Reviews Section */}
      <div className="bg-white rounded-lg shadow-lg p-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-6">Reviews</h2>
        
        {/* Add Review Form */}
        <div className="mb-8 p-4 bg-gray-50 rounded-lg">
          <h3 className="text-lg font-semibold mb-4">Add a Review</h3>
          <form onSubmit={handleReviewSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Title
              </label>
              <input
                type="text"
                value={newReview.title}
                onChange={(e) => setNewReview({...newReview, title: e.target.value})}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Description
              </label>
              <textarea
                value={newReview.description}
                onChange={(e) => setNewReview({...newReview, description: e.target.value})}
                rows={3}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Score
              </label>
              <select
                value={newReview.score}
                onChange={(e) => setNewReview({...newReview, score: parseInt(e.target.value)})}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                {[5, 4, 3, 2, 1].map(score => (
                  <option key={score} value={score}>{score} Star{score !== 1 ? 's' : ''}</option>
                ))}
              </select>
            </div>
            <button
              type="submit"
              disabled={submittingReview}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
            >
              {submittingReview ? 'Submitting...' : 'Submit Review'}
            </button>
          </form>
        </div>

        {/* Reviews List */}
        {book.reviews?.length > 0 ? (
          <div className="space-y-4">
            {book.reviews.map((review) => (
              <div key={review.id} className="border-b border-gray-200 pb-4 last:border-b-0">
                <div className="flex items-center justify-between mb-2">
                  <h4 className="font-semibold text-gray-900">{review.title}</h4>
                  <div className="flex items-center">
                    {[...Array(5)].map((_, i) => (
                      <span key={i} className="text-yellow-500">
                        {i < review.score ? '★' : '☆'}
                      </span>
                    ))}
                  </div>
                </div>
                <p className="text-gray-600">{review.description}</p>
              </div>
            ))}
          </div>
        ) : (
          <p className="text-gray-500 text-center py-8">No reviews yet. Be the first to review this book!</p>
        )}
      </div>
    </div>
  )
}

export default BookDetail 