require 'set'

class CellSet < Set
  attr_accessor :meta

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
    self.meta, encoded = data.split('_', 2)
    return if encoded.blank?

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

  def bounding_box(generations = 1)
    xmin, xmax, ymin, ymax = nil, nil, nil, nil
    p = self
    generations.times do
      p.each do |x, y|
        if !xmin || x < xmin
          xmin = x
        end
        if !xmax || x > xmax
          xmax = x
        end
        if !ymin || y < ymin
          ymin = y
        end
        if !ymax || y > ymax
          ymax = y
        end
      end
      p = p.evolve
    end
    [xmin, xmax, ymin, ymax]
  end

  def image(options = {cell_size: 14, grid_width: 2})
    @image ||= begin
      cell_size = options[:cell_size]
      grid_width = options[:grid_width]
      cell_color = 'rgb(0,0,0)'
      grid_color = 'rgb(200,200,200)'

      p = self
      xmin, xmax, ymin, ymax = p.bounding_box(period)
      if xmax - xmin < ymax - ymin
        p = p.transform(0, 0, 0, 1, -1, 0)
        xmin, xmax, ymin, ymax = p.bounding_box(period)
      end

      x0, y0 = xmin - 1, ymin - 1
      width, height = xmax - x0 + 2, ymax - y0 + 2

      canvas_width = (cell_size + grid_width) * width + grid_width
      canvas_height = (cell_size + grid_width) * height + grid_width

      image_list = Magick::ImageList.new

      # TODO: move the grid gradually for spaceships
      (oscillator? ? period : 1).times do
        gc = Magick::Draw.new

        if grid_width > 0
          gc.stroke(grid_color)
          gc.fill(grid_color)

          (0..width).each do |x|
            x1 = (cell_size + grid_width) * x
            gc.rectangle(x1, 0, x1 + grid_width - 1, canvas_height)
          end

          (0..height).each do |y|
            y1 = (cell_size + grid_width) * y
            gc.rectangle(0, y1, canvas_width, y1 + grid_width - 1)
          end
        end

        gc.stroke(cell_color)
        gc.fill(cell_color)

        p.each do |x, y|
          x1 = (cell_size + grid_width) * (x - x0) + grid_width
          y1 = (cell_size + grid_width) * (y - y0) + grid_width
          if cell_size > 1
            gc.rectangle(x1, y1, x1 + cell_size - 1, y1 + cell_size - 1)
          else
            gc.point(x1, y1)
          end
        end

        frame = Magick::Image.new(canvas_width, canvas_height)
        gc.draw(frame)

        image_list << frame

        p = p.evolve
      end
      image_list.delay = 25

      Tempfile.new(['pattern', '.gif']).tap {|f| image_list.write(f.path) }
    end
  end

  def evolve(generations = 1)
    result = self.to_set

    generations.times do
      temp = result.inject({}) do |t, coords|
        t.merge(coords => 9)
      end

      result.each do |x, y|
        (-1..1).each do |dy|
          (-1..1).each do |dx|
            temp[[x+dx, y+dy]] ||= 0
            temp[[x+dx, y+dy]] += 1
          end
        end
      end

      result = temp.select {|_, v| v.in?([3, 12, 13]) }.keys
    end

    self.class.new(result)
  end

  def still_life?
    meta && meta.first(2) == 'xs'
  end

  def oscillator?
    meta && meta.first(2) == 'xp'
  end

  def spaceship?
    meta && meta.first(2) == 'xq'
  end

  def growing?
    meta && meta.first(2) == 'yl'
  end

  def oversized?
    meta && meta.first(2) == 'ov'
  end

  def period
    return 1 if still_life?

    m = %r{x[pq](\d+)}.match(meta)
    m && m[1].to_i
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

  PI_SPLITTING_CATALYST = [new(rle: '$7bo$5b2obo$8bo$b2o2b3o$2bobo$3bobo$4bo!'), new(rle: '6b4o$5b2ob2o$7bobo$5b3obo$3b2o3b2o$2obob5o$3obob4o$4ob5o$10o!')]

  SNARK_CATALYST = [
    [new(rle: '$8bo$4b2obobo$o2bobobobo$3bobobobo$4ob2o2bo$4bo!'), new(rle: '10o$8obo$4o2bobo$b2obobobo$3obobobo$4bo2b2o$2b2ob2o!')],
    [new(rle: '$8bo$4b2obobo$3bobobobo$o2bobobobo$4ob2o2bo$4bo!'), new(rle: '10o$b7obo$4o2bobo$3obobobo$b2obobobo$4bo2b2o$2b2ob2o!')],
  ]

  BEACON = [new(rle: '$b2o$bo$4bo$3b2o!'), new(rle: '4o$o2b2o$ob4o$4obo$b2o2bo$2b4o!')]
  GRIDDLE = [new(rle: '$4bo$2bobo$bo4bo$2b4o!'), new(rle: 'b6o$4ob3o$2obob3o$2b4o!')]
  CUPHOOK = [new(rle: 'o$o$o2bo$2bo!'), new(rle: 'b4o$b4o$b2obo2$b3o!')]
  CANDLEFROBRA = [new(rle: '$o$b2obo$3bobo$4bo!'), new(rle: '6o$b5o$o2bobo$3obo$4o$b5o!')]
  BIPOLE = [new(rle: '2o$obo2$2bobo$3b2o!'), new(rle: '2b3o$bob2o$5o$2obo$3o!')]
  TEST_TUBE_BABY = [new(rle: '$bo2bo$bo2bo$bo2bo$2b2o!'), new(rle: 'bo2bo$ob2obo$ob2obo$ob2obo$2o2b2o!')]
  SPARK_COIL = [new(rle: 'o3bo$b3o3$b3o$o3bo!'), new(rle: 'b3o$o3bo$b3o$b3o$o3bo$b3o!')]
  GREAT_ON_OFF = [new(rle: 'o$ob2o$bo2bo$4bo$3bo$4b2o!'), new(rle: 'b5o$bo2b2o$ob2obo$4obo$3ob2o$b3o!')]
  LIGHT_BULB = [new(rle: '$2b3o$bo3bo$bo3bo$2bobo!'), new(rle: '7o$2o3b2o$ob3obo$ob3obo$2obob2o!')]

  def eater2_variant?
    @eater2_variant ||= matches_any?(EATER2_VARIANTS)
  end

  def eater2_precursor?
    @eater2_precursor ||= matches_any?(EATER2_PRECURSORS)
  end

  def pi_splitting_catalyst?
    @pi_splitting_catalyst ||= matches_any?([PI_SPLITTING_CATALYST])
  end

  def snark_catalyst?
    @snark_catalyst ||= matches_any?(SNARK_CATALYST)
  end

  def beacon_based?
    @beacon_based ||= (!meta || meta == 'xp2') && matches_any?([BEACON])
  end

  def griddle_variant?
    @griddle_variant ||= (!meta || meta == 'xp2') && matches_any?([GRIDDLE])
  end

  def cuphook_variant?
    @cuphook_variant ||= (!meta || meta == 'xp3') && matches_any?([CUPHOOK])
  end

  def candlefrobra_variant?
    @candlefrobra_variant ||= (!meta || meta == 'xp3') && matches_any?([CANDLEFROBRA])
  end

  def bipole_variant?
    @bipole_variant ||= (!meta || meta == 'xp2') && matches_any?([BIPOLE])
  end

  def test_tube_baby_variant?
    @test_tube_baby_variant ||= (!meta || meta == 'xp2') && matches_any?([TEST_TUBE_BABY])
  end

  def spark_coil_variant?
    @spark_coil_variant ||= (!meta || meta == 'xp2') && matches_any?([SPARK_COIL])
  end

  def great_on_off_variant?
    @great_on_off_variant ||= (!meta || meta == 'xp2') && matches_any?([GREAT_ON_OFF])
  end

  def light_bulb_variant?
    @light_bulb_variant ||= (!meta || meta == 'xp2') && matches_any?([LIGHT_BULB])
  end
end
