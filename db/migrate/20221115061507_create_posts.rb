class CreatePosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts do |t|
      t.references :user_uid, references: :users, null: false
      t.string :title, null: false
      t.text :body, null: false

      t.timestamps
    end

    rename_column :posts, :user_uid_id, :user_uid
    add_foreign_key :posts, :users, column: "user_uid", primary_key: "uid"
  end
end
