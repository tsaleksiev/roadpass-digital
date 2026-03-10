FactoryBot.define do
  factory :trip do
    name { "MyString" }
    image_url { "MyString" }
    short_description { "MyText" }
    long_description { "MyText" }
    rating { 1 }
  end
end
