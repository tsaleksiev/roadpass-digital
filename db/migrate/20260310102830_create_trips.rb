class CreateTrips < ActiveRecord::Migration[8.1]
  def change
    create_table :trips do |t|
      t.string :name, null: false
      t.string :image_url, null: false
      t.text :short_description, null: false
      t.text :long_description, null: false
      t.integer :rating, null: false

      t.timestamps
    end

    add_index :trips, :name
    add_index :trips, :rating
  end
end
