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
    [new(rle: '4bo$b2o2bo$b2obo$4bo$ob2o$bo!'), new(rle: '4o$o2b2o$o2bobo$4obo$bo2b2o$2b3o!')], # hedonismbot
    [new(rle: '4bo$b2o2bo$b2obo$4bo$b2obo$bo!'), new(rle: '4o$o2b2o$o2bobo$4obo$o2bobo$ob2o!')], # thinker
    [new(rle: '4bo$b2o2bo$b2obo$4bo$b2obo$2bo!'), new(rle: '4o$o2b2o$o2bobo$4obo$o2bobo$2obo!')], # bored
    [new(rle: '4bo$b2o2bo$b2obo$4bo$b2obo!'), new(rle: '4o$o2b2o$o2bobo$4obo$o2bobo$b2o!')], # jordan
    [new(rle: '4bo$b2o2bo$b2obo$4bo$b2o$3bo!'), new(rle: '4o$o2b2o$o2bobo$4obo$o2b2o$b2o!')], # triskelion
    [new(rle: '$b2obo$b2ob2o2$ob2o$2bo!'), new(rle: '6o$o2bobo$o2bo$6o$bo2bo$bob2o!')], # boulders
    [new(rle: '$b2obo$b2obo$5bo$ob2o$2bo!'), new(rle: '5o$o2bobo$o2bobo$5o$bo2bo$bob2o!')], # waiter
  ]

  EATER2_PRECURSORS = [
    [new(rle: '$4bo$4b2o2$b2obo$2bo!'), new(rle: '3b3o$3bobo$3bo$6o$o2bo$2obo!')], # canonical
    [new(rle: '$4bo$4bo$5bo$b2obo$2bo!'), new(rle: '3b2o$3bobo$3bobo$5o$o2bo$2obo!')], # smallest bounding box
    [new(rle: '4bo$5bo$4bo$4bo$ob2o$bo!'), new(rle: '3bo$3b2o$3bobo$4obo$bo2b2o$2b3o!')], # hedonismbot
    [new(rle: '4bo$5bo$4bo$4bo$b2obo$bo!'), new(rle: '3bo$3b2o$3bobo$4obo$o2bobo$ob2o!')], # thinker
    [new(rle: '4bo$5bo$4bo$4bo$b2obo$2bo!'), new(rle: '3bo$3b2o$3bobo$4obo$o2bobo$2obo!')], # bored
    [new(rle: '4bo$5bo$4bo$4bo$b2obo!'), new(rle: '3bo$3b2o$3bobo$4obo$o2bobo$b2o!')], # jordan
    [new(rle: '4bo$5bo$4bo$4bo$b2o$3bo!'), new(rle: '3bo$3b2o$3bobo$4obo$o2b2o$b2o!')], # triskelion
    [new(rle: '$4bo$4b2o2$ob2o$2bo!'), new(rle: '3b3o$3bobo$3bo$6o$bo2bo$bob2o!')], # boulders
    [new(rle: '$4bo$4bo$5bo$ob2o$2bo!'), new(rle: '3b2o$3bobo$3bobo$5o$bo2bo$bob2o!')], # waiter
  ]

  def eater2_variant?
    @eater2_variant ||= matches_any?(EATER2_VARIANTS)
  end

  def eater2_precursor?
    @eater2_precursor ||= matches_any?(EATER2_PRECURSORS)
  end
end
