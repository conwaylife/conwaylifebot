class Pattern < ActiveRecord::Base
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

  def description
    if still_life?
      "#{cells}-cell still life"
    elsif oscillator?
      "period #{period} oscillator"
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
