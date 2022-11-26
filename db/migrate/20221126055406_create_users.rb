class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :uid, unique: true, null: false
      t.timestamps
    end
  end
end
