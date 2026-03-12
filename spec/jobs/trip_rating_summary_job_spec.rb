require 'rails_helper'

RSpec.describe TripRatingSummaryJob, type: :job do
  describe '#perform' do
    it 'runs without errors' do
      create(:trip)
      expect { described_class.perform_now }.not_to raise_error
    end

    it 'logs a summary' do
      create(:trip, rating: 5)
      expect(Rails.logger).to receive(:info).at_least(:once)
      described_class.perform_now
    end
  end
end
