import React from 'react'
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import App from '../App'

// Mock the child components to focus on App component testing
jest.mock('../Books', () => {
  return function MockBooks() {
    return <div data-testid="books-component">Books Component</div>
  }
})

jest.mock('../BookDetail', () => {
  return function MockBookDetail() {
    return <div data-testid="book-detail-component">Book Detail Component</div>
  }
})

const renderWithRouter = (component: React.ReactElement) => {
  return render(
    <BrowserRouter>
      {component}
    </BrowserRouter>
  )
}

describe('App Component', () => {
  it('renders the navigation bar with correct title', () => {
    renderWithRouter(<App />)
    
    expect(screen.getByText('📚 Book Review')).toBeInTheDocument()
    expect(screen.getByText('Books')).toBeInTheDocument()
  })

  it('renders the main navigation link', () => {
    renderWithRouter(<App />)
    
    const booksLink = screen.getByRole('link', { name: /books/i })
    expect(booksLink).toBeInTheDocument()
    expect(booksLink).toHaveAttribute('href', '/')
  })

  it('renders the main content area', () => {
    renderWithRouter(<App />)
    
    expect(screen.getByRole('main')).toBeInTheDocument()
  })

  it('has proper navigation styling classes', () => {
    renderWithRouter(<App />)
    
    const nav = screen.getByRole('navigation')
    expect(nav).toHaveClass('bg-white', 'shadow-lg')
  })

  it('has responsive layout classes', () => {
    renderWithRouter(<App />)
    
    const main = screen.getByRole('main')
    expect(main).toHaveClass('max-w-7xl', 'mx-auto')
  })
}) 