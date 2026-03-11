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

## API Endpoints

### List trips
```
GET /api/v1/trips
```

Query parameters:
- `search` - case-insensitive partial match on name
- `min_rating` - filter trips with rating >= value
- `sort` - `rating_asc`, `rating_desc`, or default (alphabetical by name)
- `page` - page number (defeault: 1)
- `per_page` - results per page (default: 10)