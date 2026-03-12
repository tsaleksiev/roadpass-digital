FactoryBot.define do
  factory :trip do
    sequence(:name) { |n| "Trip #{n}" }
    image_url { "https://images.unsplash.com/photo-1501785888041-af3ef285b470" }
    short_description { "Vast red rock canyon carved by the Colorado River." }
    long_description { "Stretching 277 miles long and over a mile deep, the Grand Canyon reveals nearly two billion years of Earth's history." }
    rating { 5 }
  end
end
