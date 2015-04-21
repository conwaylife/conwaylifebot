class AddSymmetryToPatterns < ActiveRecord::Migration
  def change
    add_column :patterns, :symmetry, :string, null: false, default: 'C1'
    add_index :patterns, [:apgcode, :symmetry], unique: true
    remove_index :patterns, :apgcode
  end
end
