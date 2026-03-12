class TripRatingSummaryJob < ApplicationJob
  queue_as :default

  def perform
    average = Trip.average(:rating).to_f.round(2)
    top_trip = Trip.order(rating: :desc).first

    Rails.logger.info "=== Nightly trip rating summary ==="
    Rails.logger.info "Total trips: #{Trip.count}"
    Rails.logger.info "Average rating: #{average}"
    Rails.logger.info "Top rated trip: #{top_trip.name} (#{top_trip.rating} stars)"
    Rails.logger.info "==================================="
  end
end
