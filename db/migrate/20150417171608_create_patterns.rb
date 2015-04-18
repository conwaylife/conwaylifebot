class CreatePatterns < ActiveRecord::Migration
  def change
    create_table :patterns do |t|
      t.string :apgcode
      t.integer :occurrences, limit: 8
      t.integer :delta, limit: 8

      t.timestamps
    end

    add_index :patterns, :apgcode, :unique => true
  end
end
