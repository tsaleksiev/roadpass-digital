# roadpass-digital

A RESTful JSON API built with Ruby on Rails and PostgreSQL that serves trip/destination data with search, filter, sort, and pagination support.

## Tech stack

- Ruby 3.3.10
- Rails 8.1.2 (API-only)
- PostgreSQL 16
- Blueprinter - serialization
- Kaminari - pagination
- RSpec - testing
- Docker / docker-compose - local setup

## Getting started

### Option 1: Docker (recommended)
```bash
git clone 
cd roadpass-digital
docker-compose up --build
```

The API will be available at `http://localhost:3000`.
The first boot automatically runs migrations and seeds the database with 20 trips.

### Option 2: Local setup

Prerequisites: Ruby 3.3.10, PostgreSQL, Bundler
```bash
bundle install
rails db:create db:migrate db:seed
rails server
```

## Running the test suite
```bash
bundle exec rspec
```

## API endpoints

### List trips
```
GET /api/v1/trips
```

Query parameters:
- `search` - case-insensitive partial match on name
- `min_rating` - filter trips with rating >= value
- `sort` - `rating_asc`, `rating_desc`, or default (alphabetical by name)
- `page` - page number (default: 1)
- `per_page` - results per page (default: 10)

### Get trip
```
GET /api/v1/trips/:id
```

### Create trip
```
POST /api/v1/trips
Content-Type: application/json

{
  "trip": {
    "name": "Zion National Park",
    "image_url": "https://...",
    "short_description": "A stunning canyon park.",
    "long_description": "Zion is known for its towering sandstone cliffs.",
    "rating": 5
  }
}
```

## Design decisions

### Blueprinter for serialization
Blueprinter is explicit and lightweight. It lets us define two views cleanly - a trimmed list view and a full detail view - without implicit behavior.

### TripQuery object
Rather than chaining scopes directly in the controller, a dedicated `TripQuery` class handles search, filter, sort, and pagination. This keeps the controller thin and makes the query logic easy to test and extend independently.

### Database-level constraints
All fields have `null: false` at the database level in addition to Rails model validations. Rails validations can be bypassed - the database is the last line of defense for data integrity.

### Indexes on name and rating
Added indexes on the `name` and `rating` columns since these are the columns used for searching, filtering, and sorting. This ensures queries stay performant as the dataset grows.

## Bonus features

### HTTP caching
The index endpoint uses Rails `stale?` with ETags. If the data hasn't changed since the last request, the server returns `304 Not Modified` without querying the database.

### Background job
`TripRatingSummaryJob` generates a nightly summary of trip ratings - total trips, average rating, and top rated trip. Uses Sidekiq as the queue adapter.

## Room for improvement
- **Full-text search** - replace `LIKE` with PostgreSQL `tsvector` for more powerful and performant search
- **Rate limiting** - add `rack-attack` to throttle the create endpoint
- **Background job** - add a Sidekiq job for nightly trip rating summaries
- **HTTP caching** - add ETag headers on the index endpoint to reduce unnecessary DB hits
- **Add DELETE endpoint** - soft deleting using `deleted_at` so trips can be archived rather than permanently removed.