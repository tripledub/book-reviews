# Book Review API

A Rails API for managing books and reviews, built with Rails 8, PostgreSQL, and RSpec.

## Features

- **Books API** - CRUD operations for books with search functionality
- **Reviews API** - Create reviews for books
- **PostgreSQL Arrays** - Subjects and languages stored as native arrays
- **RSpec Testing** - Comprehensive test coverage
- **API Versioning** - Namespaced under `/api/v1/`
- **Pre-commit Hooks** - Automatic linting and testing

## Setup

1. **Install dependencies:**
   ```bash
   bundle install
   npm install
   ```

2. **Setup database:**
   ```bash
   rails db:create db:migrate db:seed
   ```

3. **Start the server:**
   ```bash
   rails server
   ```

## API Endpoints

### Books
- `GET /api/v1/books` - List all books with reviews
- `POST /api/v1/books` - Create a new book
- `GET /api/v1/books/:id` - Get a specific book with reviews
- `GET /api/v1/books/search?q=query` - Search books by title or author

### Reviews
- `POST /api/v1/reviews` - Create a new review

## Development

### Pre-commit Hooks

This project uses Husky and lint-staged for pre-commit hooks that automatically:

- **Lint code** with RuboCop and auto-fix issues
- **Run tests** for modified files
- **Prevent commits** if tests fail

The hooks run automatically on every commit. If you need to bypass them (not recommended):

```bash
git commit --no-verify -m "Emergency fix"
```

### Manual Commands

```bash
# Lint code
npm run lint

# Fix linting issues
npm run lint:fix

# Run all tests
npm run test

# Run tests with fail-fast
npm run test:fast
```

### Database

The app uses PostgreSQL with native array support for:
- `subjects` - Array of book subjects
- `languages` - Array of book languages

## Testing

```bash
# Run all specs
bundle exec rspec

# Run specific specs
bundle exec rspec spec/requests/api/v1/books_spec.rb
bundle exec rspec spec/requests/api/v1/reviews_spec.rb
```

## CI/CD

The project includes GitHub Actions that run:
- RSpec tests with PostgreSQL
- RuboCop linting
- Brakeman security scanning

## Data Source

Books are seeded from the [Gutendex API](https://gutendex.com/books/) - a comprehensive database of public domain books.
