require 'rails_helper'

RSpec.describe "Api::V1::Trips", type: :request do
  let(:json) { JSON.parse(response.body) }

  describe 'GET /api/v1/trips' do
    let!(:trips) { create_list(:trip, 15, name: "Trip") }

    it 'returns 200 and a list of trips' do
      get '/api/v1/trips'
      expect(response).to have_http_status(:ok)
      expect(json['data'].length).to eq(10)
    end

    it 'returns trimmed fields only' do
      get '/api/v1/trips'
      trip = json['data'].first
      expect(trip.keys).to include('id', 'name', 'image_url', 'short_description', 'rating')
      expect(trip.keys).not_to include('long_description')
    end

    it 'includes pagination metadata' do
      get '/api/v1/trips'
      meta = json['meta']
      expect(meta['total_count']).to eq(15)
      expect(meta['total_pages']).to eq(2)
      expect(meta['current_page']).to eq(1)
      expect(meta['per_page']).to eq(10)
    end

    it 'filters by search' do
      create(:trip, name: 'Zion National Park')
      get '/api/v1/trips', params: { search: 'zion' }
      expect(json['data']. map { |t| t['name'] }).to include ('Zion National Park')
    end

    it 'filters by min_rating' do
      create(:trip, name: 'Low Rated Trip', rating: 2)
      get '/api/v1/trips', params: { min_rating: 5 }
      names = json['data'].map { |t| t['name'] }
      expect(names).not_to include('Low Rated Trip')
    end

    it 'sorts by rating descending' do
      get '/api/v1/trips', params: { sort: 'rating_desc' }
      ratings = json['data'].map { |t| t['rating'] }
    end

    it 'paginates results' do
      get '/api/v1/trips', params: { page: 2, per_page: 10 }
      expect(json['meta']['current_page']).to eq(2)
    end
  end

  describe 'GET /api/v1/trips/:id' do
    let!(:trip) { create(:trip) }

    it 'returns 200 and full trip details' do
      get "/api/v1/trips/#{trip.id}"
      expect(response).to have_http_status(:ok)
      expect(json['data']['long_description']).to be_present
    end

    it 'returns 404 for non-existent trip' do
      get '/api/v1/trips/99999'
      expect(response).to have_http_status(:not_found)
      expect(json['error']).to eq('Record not found')
    end
  end

  describe 'POST /api/v1/trips' do
    let (:valid_params) do
      {
        trip: {
          name: 'Zion National Park',
          image_url: 'https://images.unsplash.com/photo-123',
          short_description: 'A stunning canyon park.',
          long_description: 'Zion is known for its towering sandstone cliffs.',
          rating: 5
        }
      }
    end

    it 'creates a trip and returns 201' do
      expect {
        post '/api/v1/trips', params: valid_params, as: :json
      }.to change(Trip, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it 'returns the created trip with full fields' do
      post '/api/v1/trips', params: valid_params, as: :json
      expect(json['data']['name']).to eq('Zion National Park')
      expect(json['data']['long_description']).to be_present
    end

    it 'returns 422 when name is missing' do
      post '/api/v1/trips', params: { trip: valid_params[:trip].except(:name) }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json['errors']).to include("Name can't be blank")
    end

    it 'returns 422 when rating is invalid' do
      post '/api/v1/trips', params: { trip: valid_params[:trip].merge(rating: 6) }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
