class ChangePostColumn < ActiveRecord::Migration[7.0]
  def change
    change_table :posts do |t|
      change_column :posts, :user_uid_id, :string
    end
  end
end
