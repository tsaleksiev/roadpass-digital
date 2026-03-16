module Api
    module V1
        class TripsController < ApplicationController
            before_action :set_trip, only: :show

            def index
                trips = TripQuery.new(query_params).call

                if stale?(trips, public: true)
                    cache_key = "api/v1/trips/#{Trip.maximum(:updated_at).to_i}-#{Trip.count}-#{query_params}"
                    payload = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
                        {
                            data: TripBlueprint.render_as_hash(trips),
                            meta: pagination_meta(trips)
                        }
                    end
                    render json: payload, status: :ok
                end
            end

            def show
                render json: { data: TripBlueprint.render_as_hash(@trip, view: :full) }, status: :ok
            end

            def create
                trip = Trip.new(trip_params)

                if trip.save
                    render json: { data: TripBlueprint.render_as_hash(trip, view: :full) }, status: :created
                else
                    render json: { errors: trip.errors.full_messages }, status: :unprocessable_entity
                end
            end

            private

            def set_trip
                @trip = Trip.find(params[:id])
            end

            def trip_params
                params.require(:trip).permit(:name, :image_url, :short_description, :long_description, :rating)
            end

            def query_params
                params.permit(:search, :min_rating, :sort, :page, :per_page)
            end

            def pagination_meta(collection)
                {
                    current_page: collection.current_page,
                    total_pages: collection.total_pages,
                    total_count: collection.total_count,
                    per_page: collection.limit_value
                }
            end
        end
    end
end
