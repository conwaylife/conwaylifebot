class Pattern < ActiveRecord::Base
  include Concerns::Workable
  include Concerns::Contributed

  before_update :set_delta

  scope :asymmetric, -> { where(symmetry: 'C1') }
  scope :symmetric, -> { where('symmetry <> ?', 'C1') }

  scope :still_lifes,  -> { where('apgcode LIKE ?', 'xs%') }
  scope :oscillators,  -> { where('apgcode LIKE ?', 'xp%') }
  scope :spaceships,   -> { where('apgcode LIKE ?', 'xq%') }
  scope :undetermined, -> { where('apgcode LIKE ? OR apgcode LIKE ? OR apgcode = ?', 'ov%', 'zz%', 'PATHOLOGICAL') }

  scope :rare, -> { where('occurrences < ?', 5) }

  scope :created_recently, -> { where('delta IS NULL') }
  scope :updated_recently, -> { where('delta > ?', 0) }

  SYMMETRIES = %w{ 8x32 C1 C2_1 C2_2 C2_4 C4_1 C4_4 D2_+1 D2_+2 D2_x D4_+1 D4_+2 D4_+4 D4_x1 D4_x4 D8_1 D8_4 }

  def asymmetric?
    symmetry == 'C1'
  end

  def symmetric?
    !asymmetric?
  end

  def cells
    m = %r{xs(\d+)_}.match(apgcode)
    m && m[1].to_i
  end

  def interesting?
    if asymmetric?
      if still_life?
        cells == 14 || cells >= 33 || eater2_variant? || eater2_precursor? || pi_splitting_catalyst? || snark_catalyst?
      elsif oscillator?
        !beacon_based? || cells >= 33
      else
        true
      end
    else
      if oscillator?
        period > 3
      elsif oversized?
        !['ov_p24', 'ov_p30', 'ov_p46', 'ov_p177'].include?(apgcode)
      else
        !still_life?
      end
    end
  end

  def description
    if still_life?
      if eater2_variant?
        "#{cells}-cell eater2 variant"
      elsif eater2_precursor?
        "#{cells}-cell eater2 precursor"
      elsif pi_splitting_catalyst?
        "pi splitting catalyst"
      elsif snark_catalyst?
        "snark catalyst"
      else
        "#{cells}-cell still life"
      end
    elsif oscillator?
      if griddle_variant?
        "griddle variant"
      elsif cuphook_variant?
        "cuphook variant"
      elsif candlefrobra_variant?
        "candlefrobra variant"
      elsif bipole_variant?
        "bipole variant"
      elsif test_tube_baby_variant?
        "test tube baby variant"
      elsif spark_coil_variant?
        "spark coil variant"
      elsif great_on_off_variant?
        "great on-off variant"
      elsif light_bulb_variant?
        "light bulb variant"
      elsif beacon_based?
        "beacon-based oscillator"
      else
        "period #{period} oscillator"
      end
    elsif spaceship?
      'spaceship'
    elsif growing?
      'growing object'
    elsif oversized?
      'oversized object'
    else
      'object'
    end
  end

  def url
    "http://catagolue.appspot.com/object/#{apgcode}/b3s23"
  end

  private

  def set_delta
    self.delta = self.occurrences - self.occurrences_was
  end
end
