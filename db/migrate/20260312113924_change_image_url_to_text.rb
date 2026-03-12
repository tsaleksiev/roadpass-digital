class ChangeImageUrlToText < ActiveRecord::Migration[8.1]
  def change
    change_column :trips, :image_url, :text
  end
end
