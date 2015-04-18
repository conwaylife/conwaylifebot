module Concerns
  module Workable
    delegate :eater2_variant?, to: :cell_set

    def cell_set
      @cell_set ||= CellSet.new(wechsler: apgcode)
    end
  end
end
