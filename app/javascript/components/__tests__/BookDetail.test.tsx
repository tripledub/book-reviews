import React from 'react'
import { render, screen, waitFor } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import userEvent from '@testing-library/user-event'
import BookDetail from '../BookDetail'
import { Book } from '../../types'

// Mock fetch
const mockFetch = fetch as jest.MockedFunction<typeof fetch>

// Mock react-router-dom
const mockNavigate = jest.fn()
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useParams: () => ({ id: '1' }),
  useNavigate: () => mockNavigate,
}))

const mockBook: Book = {
  id: 1,
  title: 'Pride and Prejudice',
  author: 'Jane Austen',
  subjects: ['Fiction', 'Romance', 'Classic'],
  languages: ['en', 'fr'],
  image: 'https://example.com/pride.jpg',
  reviews: [
    { id: 1, title: 'Excellent Classic', description: 'A wonderful read', score: 5, book_id: 1 },
    { id: 2, title: 'Timeless Story', description: 'Beautifully written', score: 4, book_id: 1 }
  ]
}

const renderWithRouter = (component: React.ReactElement) => {
  return render(
    <BrowserRouter>
      {component}
    </BrowserRouter>
  )
}

describe('BookDetail Component', () => {
  beforeEach(() => {
    mockFetch.mockClear()
    mockNavigate.mockClear()
  })

  it('renders loading state initially', () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockBook,
      } as Response)
    )

    renderWithRouter(<BookDetail />)
    
    expect(screen.getByRole('status')).toBeInTheDocument()
  })

  it('renders book details after successful API call', async () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockBook,
      } as Response)
    )

    renderWithRouter(<BookDetail />)
    
    await waitFor(() => {
      expect(screen.getByText('Pride and Prejudice')).toBeInTheDocument()
      expect(screen.getByText('by Jane Austen')).toBeInTheDocument()
    })
  })

  it('displays book image when available', async () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockBook,
      } as Response)
    )

    renderWithRouter(<BookDetail />)
    
    await waitFor(() => {
      const image = screen.getByAltText('Pride and Prejudice')
      expect(image).toBeInTheDocument()
      expect(image).toHaveAttribute('src', 'https://example.com/pride.jpg')
    })
  })

  it('displays placeholder when no image is available', async () => {
    const bookWithoutImage = { ...mockBook, image: '' }
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => bookWithoutImage,
      } as Response)
    )

    renderWithRouter(<BookDetail />)
    
    await waitFor(() => {
      expect(screen.getByText('No Image')).toBeInTheDocument()
    })
  })

  it('displays subjects as tags', async () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockBook,
      } as Response)
    )

    renderWithRouter(<BookDetail />)
    
    await waitFor(() => {
      expect(screen.getByText('Fiction')).toBeInTheDocument()
      expect(screen.getByText('Romance')).toBeInTheDocument()
      expect(screen.getByText('Classic')).toBeInTheDocument()
    })
  })

  it('displays languages as tags', async () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockBook,
      } as Response)
    )

    renderWithRouter(<BookDetail />)
    
    await waitFor(() => {
      expect(screen.getByText('en')).toBeInTheDocument()
      expect(screen.getByText('fr')).toBeInTheDocument()
    })
  })

  it('displays average rating correctly', async () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockBook,
      } as Response)
    )

    renderWithRouter(<BookDetail />)
    
    await waitFor(() => {
      expect(screen.getByText('4.5')).toBeInTheDocument() // (5+4)/2 = 4.5
      expect(screen.getByText('(2 reviews)')).toBeInTheDocument()
    })
  })

  it('displays all reviews', async () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockBook,
      } as Response)
    )

    renderWithRouter(<BookDetail />)
    
    await waitFor(() => {
      expect(screen.getByText('Excellent Classic')).toBeInTheDocument()
      expect(screen.getByText('A wonderful read')).toBeInTheDocument()
      expect(screen.getByText('Timeless Story')).toBeInTheDocument()
      expect(screen.getByText('Beautifully written')).toBeInTheDocument()
    })
  })

  it('renders review submission form', async () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockBook,
      } as Response)
    )

    renderWithRouter(<BookDetail />)
    
    await waitFor(() => {
      expect(screen.getByText('Add a Review')).toBeInTheDocument()
      expect(screen.getByLabelText(/title/i)).toBeInTheDocument()
      expect(screen.getByLabelText(/description/i)).toBeInTheDocument()
      expect(screen.getByLabelText(/score/i)).toBeInTheDocument()
      expect(screen.getByRole('button', { name: /submit review/i })).toBeInTheDocument()
    })
  })

  it('submits review successfully', async () => {
    const user = userEvent.setup()
    
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockBook,
      } as Response)
    )

    renderWithRouter(<BookDetail />)
    
    await waitFor(() => {
      expect(screen.getByText('Pride and Prejudice')).toBeInTheDocument()
    })

    const titleInput = screen.getByLabelText(/title/i)
    const descriptionInput = screen.getByLabelText(/description/i)
    const scoreSelect = screen.getByLabelText(/score/i)
    const submitButton = screen.getByRole('button', { name: /submit review/i })

    await user.type(titleInput, 'Great Book')
    await user.type(descriptionInput, 'Really enjoyed this classic')
    await user.selectOptions(scoreSelect, '5')

    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => ({ id: 3, title: 'Great Book', description: 'Really enjoyed this classic', score: 5, book_id: 1 }),
      } as Response)
    )

    await user.click(submitButton)

    await waitFor(() => {
      expect(mockFetch).toHaveBeenCalledWith('/api/v1/reviews', expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          'Content-Type': 'application/json',
        }),
        body: JSON.stringify({
          review: {
            title: 'Great Book',
            description: 'Really enjoyed this classic',
            score: 5,
            book_id: 1
          }
        })
      }))
    })
  })

  it('handles review submission errors', async () => {
    const user = userEvent.setup()
    
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockBook,
      } as Response)
    )

    renderWithRouter(<BookDetail />)
    
    await waitFor(() => {
      expect(screen.getByText('Pride and Prejudice')).toBeInTheDocument()
    })

    const titleInput = screen.getByLabelText(/title/i)
    const descriptionInput = screen.getByLabelText(/description/i)
    const submitButton = screen.getByRole('button', { name: /submit review/i })

    await user.type(titleInput, 'Great Book')
    await user.type(descriptionInput, 'Really enjoyed this classic')

    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: false,
        json: async () => ({ errors: ['Title is required'] }),
      } as Response)
    )

    const alertSpy = jest.spyOn(window, 'alert').mockImplementation(() => {})
    await user.click(submitButton)

    await waitFor(() => {
      expect(alertSpy).toHaveBeenCalledWith('Title is required')
    })

    alertSpy.mockRestore()
  })

  it('handles book not found error', async () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: false,
        status: 404,
      } as Response)
    )

    renderWithRouter(<BookDetail />)
    
    await waitFor(() => {
      expect(screen.getByText('Failed to load book')).toBeInTheDocument()
      expect(screen.getByRole('button', { name: /back to books/i })).toBeInTheDocument()
    })
  })

  it('navigates back to books when back button is clicked', async () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockBook,
      } as Response)
    )

    renderWithRouter(<BookDetail />)
    
    await waitFor(() => {
      expect(screen.getByText('Pride and Prejudice')).toBeInTheDocument()
    })

    const backButton = screen.getByRole('link', { name: /back to books/i })
    expect(backButton).toHaveAttribute('href', '/')
  })

  it('shows empty reviews state when no reviews exist', async () => {
    const bookWithoutReviews = { ...mockBook, reviews: [] }
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => bookWithoutReviews,
      } as Response)
    )

    renderWithRouter(<BookDetail />)
    
    await waitFor(() => {
      expect(screen.getByText('No reviews yet. Be the first to review this book!')).toBeInTheDocument()
    })
  })
}) 