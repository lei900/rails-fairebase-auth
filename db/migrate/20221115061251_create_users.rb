class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users, id: false, primary_key: :uid do |t|
      t.string :uid, null: false

      t.timestamps
    end
  end
end
