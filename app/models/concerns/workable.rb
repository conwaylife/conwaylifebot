module Concerns
  module Workable
    delegate :eater2_variant?, :eater2_precursor?, :beacon_based?,
      :griddle_variant?, :cuphook_variant?, :candlefrobra_variant?,
      :bipole_variant?, :test_tube_baby_variant?, :spark_coil_variant?,
      :great_on_off_variant?, :light_bulb_variant?, :pi_splitting_catalyst?,
      :snark_catalyst?, :still_life?, :oscillator?, :spaceship?,
      :growing?, :oversized?, :period, :image, to: :cell_set

    def cell_set
      @cell_set ||= CellSet.new(wechsler: apgcode)
    end
  end
end
