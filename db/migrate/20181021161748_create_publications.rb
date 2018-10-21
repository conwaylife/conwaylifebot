class CreatePublications < ActiveRecord::Migration
  def change
    create_table :publications do |t|
      t.string :symmetry, null: false

      t.timestamps null: false
    end

    add_index :publications, :symmetry, unique: true
  end
end
