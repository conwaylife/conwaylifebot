class Pattern < ActiveRecord::Base
  include Concerns::Workable

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

  def still_life?
    apgcode.first(2) == 'xs'
  end

  def oscillator?
    apgcode.first(2) == 'xp'
  end

  def spaceship?
    apgcode.first(2) == 'xq'
  end

  def growing?
    apgcode.first(2) == 'yl'
  end

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

  def period
    return 1 if still_life?

    m = %r{x[pq](\d+)_}.match(apgcode)
    m && m[1].to_i
  end

  def interesting?
    if asymmetric?
      if still_life?
        cells >= 30 || eater2_variant? || eater2_precursor?
      elsif oscillator?
        !beacon_based?
      else
        true
      end
    else
      oscillator? ? period > 3 : !still_life?
    end
  end

  def description
    if still_life?
      if eater2_variant?
        "#{cells}-cell eater2 variant"
      elsif eater2_precursor?
        "#{cells}-cell eater2 precursor"
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
      else
        "period #{period} oscillator"
      end
    elsif spaceship?
      'spaceship'
    elsif growing?
      'growing object'
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
