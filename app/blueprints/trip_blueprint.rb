class TripBlueprint < Blueprinter::Base
    identifier :id

    fields :name, :image_url, :short_description, :rating

    view :full do
        fields :name, :image_url, :short_description, :long_description, :rating
    end
end