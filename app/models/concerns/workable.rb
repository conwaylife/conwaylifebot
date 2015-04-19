module Concerns
  module Workable
    delegate :eater2_variant?, :eater2_precursor?, :beacon_based?, to: :cell_set

    def cell_set
      @cell_set ||= CellSet.new(wechsler: apgcode)
    end
  end
end
