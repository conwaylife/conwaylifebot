module Concerns
  module Workable
    delegate :eater2_variant?, :eater2_precursor?, :beacon_based?,
      :griddle_variant?, :cuphook_variant?, :candlefrobra_variant?,
      :bipole_variant?, to: :cell_set

    def cell_set
      @cell_set ||= CellSet.new(wechsler: apgcode)
    end
  end
end
