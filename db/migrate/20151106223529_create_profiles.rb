class CreateProfiles < ActiveRecord::Migration
  def change
    create_table :profiles do |t|
      t.string :avatar
      t.string :display_name, null: false

      t.timestamps null: false
    end
  end
end
