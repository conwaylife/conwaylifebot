class Publication < ActiveRecord::Base
  validates :symmetry, uniqueness: true

  def self.timestamp(symmetry)
    find_by(symmetry: symmetry).try(:updated_at) || Time.new(2010, 1, 1)
  end
end
