ActiveRecord::Schema[8.1].define(version: 2026_03_12_113924) do
  enable_extension "pg_catalog.plpgsql"

  create_table "trips", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "image_url", null: false
    t.text "long_description", null: false
    t.string "name", null: false
    t.integer "rating", null: false
    t.text "short_description", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_trips_on_name"
    t.index ["rating"], name: "index_trips_on_rating"
  end
end
