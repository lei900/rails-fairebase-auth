class ChangePostColumnName < ActiveRecord::Migration[7.0]
  def change
    change_table :posts do |t|
      rename_column :posts, :user_uid_id, :user_uid
    end
  end
end
