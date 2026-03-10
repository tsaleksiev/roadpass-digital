module Api
    module V1
        class TripsController < ApplicationController
            def index
                trips = TripQuery.new(query_params).call

                render json: {
                    data: TripBlueprint.render_as_hash(trips),
                    meta: pagination_meta(trips)
                }, status: :ok
            end

            def show
                trip = Trip.find(params[:id])
                render json: { data: TripBlueprint.render_as_hash(trip, view: :full) }, status: :ok
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
