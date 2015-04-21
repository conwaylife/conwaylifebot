class Pattern < ActiveRecord::Base
  include Concerns::Workable

  before_update :set_delta

  scope :still_lifes, -> { where('apgcode like ?', 'xs%') }
  scope :oscillators, -> { where('apgcode like ?', 'xp%') }
  scope :spaceships,  -> { where('apgcode like ?', 'xq%') }

  scope :rare, -> { where('occurrences < ?', 5) }

  scope :created_recently, -> { where('delta IS NULL') }
  scope :updated_recently, -> { where('delta > ?', 0) }

  def still_life?
    apgcode.first(2) == 'xs'
  end

  def oscillator?
    apgcode.first(2) == 'xp'
  end

  def spaceship?
    apgcode.first(2) == 'xq'
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
    if still_life?
      cells >= 30 || eater2_variant? || eater2_precursor?
    elsif oscillator?
      !beacon_based?
    else
      true
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
