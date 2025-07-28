export interface Book {
  id: number
  title: string
  author: string
  subjects: string[]
  languages: string[]
  image: string
  reviews: Review[]
}

export interface Review {
  id: number
  title: string
  description: string
  score: number
  book_id: number
  book?: Book
}

export interface NewReview {
  title: string
  description: string
  score: number
}

export interface ApiError {
  errors?: string[]
  error?: string
} 