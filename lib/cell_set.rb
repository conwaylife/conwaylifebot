require 'set'

class CellSet < Set
  TRANSFORMATIONS = [
      [1, 0, 0, 1],
      [0, -1, 1, 0],
      [-1, 0, 0, -1],
      [0, 1, -1, 0],
      [-1, 0, 0, 1],
      [0, 1, 1, 0],
      [1, 0, 0, -1],
      [0, -1, -1, 0],
  ]

  def initialize(options)
    super

    if options.kind_of?(Hash)
      if options[:wechsler]
        decode_wechsler(options[:wechsler])
      elsif options[:rle]
        decode_rle(options[:rle])
      end
    end
  end

  def decode_wechsler(data)
    _, encoded = data.split('_', 2)

    clear

    x, y = 0, 0
    pos = 0

    while pos < encoded.length
      ch = encoded[pos]
      case ch
      when 'w'
        x += 2
      when 'x'
        x += 3
      when 'y'
        pos += 1
        x += 4 + encoded[pos].to_i(36)
      when 'z'
        x = 0
        y += 5
      else
        value = ch.to_i(36)
        5.times do |n|
          add([x, y+n]) if value & (1 << n) != 0
        end
        x += 1
      end

      pos += 1
    end
  end

  def decode_rle(encoded)
    x, y = 0, 0
    pos = 0

    clear

    while pos < encoded.length
      prev = pos
      while encoded[pos].in?('0'..'9')
        pos += 1
      end

      n = pos > prev ? encoded[prev, pos - prev].to_i : 1
      ch = encoded[pos]
      case ch
      when '$'
        y += n
        x = 0
      when 'b'
        x += n
      when 'o'
        n.times do |i|
          add([x, y])
          x += 1
        end
      end

      pos += 1
    end
  end

  def matches?(wanted, unwanted)
    pivot = wanted.each.next rescue nil
    return unless pivot

    each do |x, y|
      catch :failed do
        wanted.each do |i, j|
          throw :failed unless [x+i-pivot[0], y+j-pivot[1]].in?(self)
        end

        unwanted.each do |i, j|
          throw :failed if [x+i-pivot[0], y+j-pivot[1]].in?(self)
        end

        return true
      end
    end

    false
  end

  def transform(dx = 0, dy = 0, dxx = 1, dxy = 0, dyx = 0, dyy = 1)
    self.class.new(collect {|x, y| [x*dxx + y*dxy + dx, x*dyx + y*dyy + dy] })
  end

  def matches_any?(targets)
    TRANSFORMATIONS.any? do |t|
      p = transform(0, 0, *t)
      targets.any? {|target| p.matches?(*target) }
    end
  end

  EATER2_VARIANTS = [
    [new(rle: '$b2obo$b2ob2o2$b2obo$2bo!'), new(rle: '6o$o2bobo$o2bo$6o$o2bo$2obo!')], # canonical
    [new(rle: '$b2obo$b2obo$5bo$b2obo$2bo!'), new(rle: '5o$o2bobo$o2bobo$5o$o2bo$2obo!')], # smallest bounding box
  ]

  def eater2_variant?
    @eater2_variant ||= matches_any?(EATER2_VARIANTS)
  end
end
