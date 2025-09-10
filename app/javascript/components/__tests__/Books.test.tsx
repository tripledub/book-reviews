import React from 'react'
import { render, screen, waitFor } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import userEvent from '@testing-library/user-event'
import Books from '../Books'
import { Book, PaginatedResponse } from '../../types'

// Mock fetch
const mockFetch = fetch as jest.MockedFunction<typeof fetch>

const mockBooks: Book[] = [
  {
    id: 1,
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
    subjects: ['Fiction', 'Romance'],
    languages: ['en'],
    image: 'https://example.com/pride.jpg',
    reviews: [
      { id: 1, title: 'Great book', description: 'Excellent read', score: 5, book_id: 1 }
    ]
  },
  {
    id: 2,
    title: '1984',
    author: 'George Orwell',
    subjects: ['Fiction', 'Dystopian'],
    languages: ['en'],
    image: 'https://example.com/1984.jpg',
    reviews: []
  }
]

const mockPaginatedResponse: PaginatedResponse<Book> = {
  pagy: {
    count: 2,
    page: 1,
    pages: 1,
    limit: 20,
    from: 1,
    to: 2,
    prev: null,
    next: null
  },
  books: mockBooks
}

const renderWithRouter = (component: React.ReactElement) => {
  return render(
    <BrowserRouter>
      {component}
    </BrowserRouter>
  )
}

describe('Books Component', () => {
  beforeEach(() => {
    mockFetch.mockClear()
  })

  it('renders loading state initially', () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockPaginatedResponse,
      } as Response)
    )

    renderWithRouter(<Books />)
    
    expect(screen.getByTestId('loading-spinner')).toBeInTheDocument()
  })

  it('renders books after successful API call', async () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockPaginatedResponse,
      } as Response)
    )

    renderWithRouter(<Books />)
    
    await waitFor(() => {
      expect(screen.getByText('Pride and Prejudice')).toBeInTheDocument()
      expect(screen.getByText('1984')).toBeInTheDocument()
    })
  })

  it('renders search form', async () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockPaginatedResponse,
      } as Response)
    )

    renderWithRouter(<Books />)
    
    await waitFor(() => {
      expect(screen.getByPlaceholderText(/search books/i)).toBeInTheDocument()
      expect(screen.getByRole('button', { name: /search/i })).toBeInTheDocument()
    })
  })

  it('performs search when form is submitted', async () => {
    const user = userEvent.setup()
    
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockPaginatedResponse,
      } as Response)
    )

    renderWithRouter(<Books />)
    
    await waitFor(() => {
      expect(screen.getByText('Pride and Prejudice')).toBeInTheDocument()
    })

    const searchInput = screen.getByPlaceholderText(/search books/i)
    const searchButton = screen.getByRole('button', { name: /search/i })

    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => ({ ...mockPaginatedResponse, books: [mockBooks[0]] }), // Only return first book
      } as Response)
    )

    await user.type(searchInput, 'Pride')
    await user.click(searchButton)

    await waitFor(() => {
      expect(mockFetch).toHaveBeenCalledWith('/api/v1/books/search?q=Pride')
    })
  })

  it('shows clear button when search query exists', async () => {
    const user = userEvent.setup()
    
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockPaginatedResponse,
      } as Response)
    )

    renderWithRouter(<Books />)
    
    await waitFor(() => {
      expect(screen.getByText('Pride and Prejudice')).toBeInTheDocument()
    })

    const searchInput = screen.getByPlaceholderText(/search books/i)
    await user.type(searchInput, 'test')

    expect(screen.getByRole('button', { name: /clear/i })).toBeInTheDocument()
  })

  it('clears search when clear button is clicked', async () => {
    const user = userEvent.setup()
    
    // Mock successful initial load
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockPaginatedResponse,
      } as Response)
    )

    renderWithRouter(<Books />)
    
    // Wait for books to load
    await waitFor(() => {
      expect(screen.getByText('Pride and Prejudice')).toBeInTheDocument()
    })

    const searchInput = screen.getByPlaceholderText(/search books/i)
    await user.type(searchInput, 'test')

    // Mock successful clear operation
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockPaginatedResponse,
      } as Response)
    )

    const clearButton = screen.getByRole('button', { name: /clear/i })
    await user.click(clearButton)

    // Wait for the component to re-render after clearing
    await waitFor(() => {
      const updatedSearchInput = screen.getByPlaceholderText(/search books/i)
      expect(updatedSearchInput).toHaveValue('')
    })
  })

  it('displays book information correctly', async () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockPaginatedResponse,
      } as Response)
    )

    renderWithRouter(<Books />)
    
    await waitFor(() => {
      expect(screen.getByText('Pride and Prejudice')).toBeInTheDocument()
      expect(screen.getByText('by Jane Austen')).toBeInTheDocument()
      expect(screen.getByText('1 reviews')).toBeInTheDocument()
      expect(screen.getByText('5.0')).toBeInTheDocument() // Average rating
    })
  })

  it('handles API errors gracefully', async () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.reject(new Error('Network error'))
    )

    renderWithRouter(<Books />)
    
    await waitFor(() => {
      expect(screen.getByText('Failed to load books')).toBeInTheDocument()
      expect(screen.getByRole('button', { name: /try again/i })).toBeInTheDocument()
    })
  })

  it('shows empty state when no books are returned', async () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => ({ ...mockPaginatedResponse, books: [] }),
      } as Response)
    )

    renderWithRouter(<Books />)
    
    await waitFor(() => {
      expect(screen.getByText('No books available.')).toBeInTheDocument()
    })
  })

  it('renders book links with correct hrefs', async () => {
    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => mockPaginatedResponse,
      } as Response)
    )

    renderWithRouter(<Books />)
    
    await waitFor(() => {
      expect(screen.getByText('Pride and Prejudice')).toBeInTheDocument()
      expect(screen.getByText('1984')).toBeInTheDocument()
    })

    const prideLink = screen.getByRole('link', { name: /pride and prejudice/i })
    const orwellLink = screen.getByRole('link', { name: /1984/i })

    expect(prideLink).toHaveAttribute('href', '/books/1')
    expect(orwellLink).toHaveAttribute('href', '/books/2')
  })

  it('renders pagination controls when there are multiple pages', async () => {
    const multiPageResponse: PaginatedResponse<Book> = {
      pagy: {
        count: 40,
        page: 1,
        pages: 2,
        limit: 20,
        from: 1,
        to: 20,
        prev: null,
        next: 2
      },
      books: mockBooks
    }

    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => multiPageResponse,
      } as Response)
    )

    renderWithRouter(<Books />)
    
    await waitFor(() => {
      expect(screen.getByText('Previous')).toBeInTheDocument()
      expect(screen.getByText('Next')).toBeInTheDocument()
      expect(screen.getByText('1')).toBeInTheDocument()
      expect(screen.getByText('2')).toBeInTheDocument()
      expect(screen.getByText('Showing 1 to 20 of 40 books')).toBeInTheDocument()
    })
  })

  it('handles page navigation correctly', async () => {
    const user = userEvent.setup()
    
    const multiPageResponse: PaginatedResponse<Book> = {
      pagy: {
        count: 40,
        page: 1,
        pages: 2,
        limit: 20,
        from: 1,
        to: 20,
        prev: null,
        next: 2
      },
      books: mockBooks
    }

    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => multiPageResponse,
      } as Response)
    )

    renderWithRouter(<Books />)
    
    await waitFor(() => {
      expect(screen.getByText('1')).toBeInTheDocument()
    })

    // Mock the second page response
    const secondPageResponse: PaginatedResponse<Book> = {
      pagy: {
        count: 40,
        page: 2,
        pages: 2,
        limit: 20,
        from: 21,
        to: 40,
        prev: 1,
        next: null
      },
      books: mockBooks
    }

    mockFetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: async () => secondPageResponse,
      } as Response)
    )

    const nextButton = screen.getByText('Next')
    await user.click(nextButton)

    await waitFor(() => {
      expect(mockFetch).toHaveBeenCalledWith('/api/v1/books?page=2')
    })
  })
}) 