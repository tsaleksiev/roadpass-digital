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
- Sidekiq - background job processing
- Redis - job queue and cache store

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

**Why Blueprinter over alternatives:**
- **vs Active Model Serializers** - AMS has implicit association loading which can cause unexpected N+1 queries. Blueprinter is explicit - we define exactly what gets serialized.
- **vs Jbuilder** - template-based, good for complex nested JSON but overkill for a simple API with two response shapes.

**When AMS or Jbuilder would be better:**
- Complex, deeply nested associations
- Very dynamic JSON structures that change per user/role
- Team already standardized on them

### TripQuery object
Rather than chaining scopes directly in the controller, a dedicated `TripQuery` class handles search, filter, sort, and pagination. This keeps the controller thin and makes the query logic easy to test and extend independently. This is similar to a Service class - a plain object with a single responsibility that sits between the controller and the model.

**Why TripQuery over alternatives:**
- **vs scopes in the model** - model scopes are reusable but chaining them in the controller gets messy. The controller shouldn't care about how the query is built.
- **vs Ransack gem** - Ransack handles filtering/sorting automatically with less code but it's magic. You configure it on the model and it generates query methods from URL params. Less transparent, harder to debug, and you lose explicit control over what's searchable.
- **vs inline controller logic** - works for simple cases but becomes unreadable as filtering grows. Hard to test in isolation.

**When Ransack would be better**
- Large number of filterable fields
- Rapid prototyping where explicit control isn't a priority
- Admin interfaces where you need complex filtering fast.

### Kaminari for pagination
Kaminari adds `.page(n).per(n)` to ActiveRecord queries and provides metadata like `total_pages` and `total_count` out of the box.

**Why Kaminari over alternatives:**
- **vs Pagy** - Pagy is faster and more lightweight but requires more manual wiring to get pagination metadata. Kaminari integrates with ActiveRecord seamlessly and the metadata is available directly on the collection.
- **vs will_paginate** - older gem, less actively maintained, similar API to Kaminari but less flexible.
- **vs manual pagination** - we could do `Trip.limit(10).offset(page * 10)` but we'd have to manually calculate `total_pages`, `total_count` etc. Not worth reinventing.

**When Pagy would be better:**
- High traffic API where performance is critical - Pagy is significantly faster
- You need more control over how metadata is structured
- Large datasets where Kaminari's COUNT queries become a bottleneck

### Database-level constraints
All fields have `null: false` at the database level in addition to Rails model validations. Rails validations can be bypassed - the database is the last line of defense for data integrity.

### Indexes on name and rating
Added indexes on the `name` and `rating` columns since these are the columns used for searching, filtering, and sorting. This ensures queries stay performant as the dataset grows.

## Bonus features

### HTTP caching with ETags
The index endpoint uses Rails `stale?` which automatically sets `ETag` and `Last-Modified` headers. If the client sends back a matching `If-None-Match` header, the server returns `304 Not Modified` without querying the database.

**Tradeoffs:**
- **vs no caching** - adds a small overhead to compute the ETag but saves bandwidth and DB queries for repeat requests
- **vs `Cache-Control: max-age`** - `max-age` is simpler but serves stale data until expiry regardless of changes. ETags are precise - the client always gets fresh data when it changes.
- **vs fragment caching alone** - ETags work at the HTTP layer and save the server from doing any work at all on cache hits. Fragment caching still processes the request but skips the DB query.

### Redis fragment caching
On ETag miss, the rendered JSON is stored in Redis for 5 minutes. Subsequent requests are served directly from Redis without hitting the database.

Cache keys include a data fingerprint (maximum `updated_at` + record count combined with query params). This means
- Different filters/sorts have separate cache entries
- Cache automatically invalidates when trips are added, updated, or deleted

Redis database 1 is used for caching, separate from Sidekiq's database 0, to avoid key conflicts.

**Tradeoffs:**
- **vs `:memory_store`** - memory store is per-process and lost on restart. Redis is shared across multiple app instances and persistent - scales horizontally.
- **vs no fragment caching** - adds Redis as a dependency. Worth it when DB queries are expensive or traffic is high.
- **Hardcoded TTL** - cache expiry is currently hardcoded to 5 minutes. In production this should be an environment variable.
- **Extra DB queries for cache key** - computing `maximum(:updated_at)` and `count` adds two lightweight queries per request. A worthwhile tradeoff for cache correctness.

### Background job
`TripRatingSummaryJob` generates a nightly summary of trip ratings - total trips, average rating, and top rated trip. Uses Sidekiq as the queue backend.

Sidekiq dashboard available at `http://localhost:3000/sidekiq`.

To enqueue manually:
```bash
rails console
TripRatingSummaryJob.perform_later
```

**Tradeoffs:**
- **vs Active Job `:async` adapter** - async runs jobs in-process in a thread pool. Simple, no Redis needed, but jobs are lost if the server restarts. Not suitable for production.
- **vs Solid Queue** - Rails 8 ships with Solid Queue which uses your existing PostgreSQL database as the job queue. No extra infrastructure needed. For this project Solid Queue would have been simpler, but Sidekiq is the industry standard, has better tooling (web dashboard, retries, dead job queue) and leverages a broader ecosystem.
- **No scheduler** - the job currently has no automatic schedule. In production `sidekiq-cron` would be added to run it nightly automatically.
- **Redis dependency** - Sidekiq requires Redis. Since Redis is already in the stack for caching, this is not an additional dependency.

## Room for improvement
- **Full-text search** - replace `LIKE` with PostgreSQL `tsvector` for more powerful and performant search
- **Rate limiting** - add `rack-attack` to throttle the create endpoint
- **Add DELETE endpoint** - soft deleting using `deleted_at` so trips can be archived rather than permanently removed.
- **Configurable cache TTL** - cache expiry is currently hardcoded to 5 minutes, could be moved to an environment variable
- **Cache key sanitization** - The current `cache_key` includes the entire `query_params` hash. If an user passes random parameters like ?api_key=123&timestamp=999, it will create a new cache entry in Redis. An attacker could spam the API with random parameters to fill up Redis memory (Cache Exhaustion Attack). We should whitelist only the parameters that actually change the result.