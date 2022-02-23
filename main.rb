GameName = 'Hextest'
Rl.init_window(800, 600, GameName)

include FECS

Cmp.new('Shape', :obj)
Cmp.new('ShapeColor', :color)
Cmp.new('BorderColor', :color)

class Shape
  attr_reader :angle, :size, :x, :y, :sides
  def initialize(angle: 0, size: 0, x: 0, y: 0, sides: 3)
    @sides = sides
    @angle = angle
    @size = size
    @x = x
    @y = y
    update
  end

  def points
    @points ||= []
  end

  def sides=(sides)
    @sides = sides
    self.update
  end

  def angle=(angle)
    @angle = angle
    self.update
  end

  def size=(size)
    @size = size
    self.update
  end

  def x=(x)
    @x = x
    self.update
  end

  def y=(y)
    @y = y
    self.update
  end

  private
  def update
    sides.times do |point_num|
      points[point_num] ||= Hash.new
      points[point_num][:x] = Math.sin(((point_num/sides.to_f) * Math::PI * 2) - angle) * size + x
      points[point_num][:y] = Math.cos(((point_num/sides.to_f) * Math::PI * 2) - angle) * size + y
    end
    [sides - points.length, 0].max.times do
      points.pop # strip extra points
    end
  end
end

Target = Cmp::Shape.new(obj: Shape.new(sides: 6, size: 100, x: 300, y: 300))
MouseFollow = Cmp::Shape.new(obj: Shape.new(sides: 6, size: 100))


Ent.new(
  Target,
  Cmp::ShapeColor.new(color: Rl::Color.medium_orchid),
  Cmp::BorderColor.new(color: Rl::Color.medium_orchid)
)

Ent.new(
  MouseFollow,
  Cmp::ShapeColor.new(color: Rl::Color.dodger_blue),
  Cmp::BorderColor.new(color: Rl::Color.dodger_blue)
)

Sys.new('DrawShape') do
  Ent.group(Cmp::Shape, Cmp::ShapeColor, Cmp::BorderColor) do |shape_cmp, color_cmp, border_color_cmp, entity|
    shape = shape_cmp.obj
    Rl.draw_poly(center: Rl::Vector2.new(shape.x, shape.y),
                 radius: shape.size,
                 sides: shape.sides,
                 rotation: shape.angle,
                 color: color_cmp.color)
    Rl.draw_poly_lines(center: Rl::Vector2.new(shape.x, shape.y),
                       radius: shape.size,
                       sides: shape.sides,
                       rotation: shape.angle,
                       color: border_color_cmp.color,
                       line_thickness: shape.size/10)
  end
end

module SAT
  class << self
    # The hitbox logic
    def hitbox_check(shape_a, shape_b)
      # Get normals of both shapes
      inverted = build_inverted_edges(shape_a)
      inverted.concat(build_inverted_edges(shape_b))

      inverted.each_with_index do |line, line_index|
        # Determine max and min of a and b shapes
        amax, amin = calculate_minmax(shape_a, line)
        bmax, bmin = calculate_minmax(shape_b, line)

        if ((amin <= bmax) && (amin >= bmin)) || ((bmin <= amax) && (bmin >= amin))
          next
        else
          return false
        end
      end
      true
    end

    # Creates edges out using coordinates and then gets the normal
    def build_inverted_edges(shape)
      edges = []
      shape.each_with_index do |vertex_start, index|
        vertex_end = if index == shape.length - 1
                       shape[0]
                     else
                       shape[index + 1]
                     end
        edges.push [vertex_end[1] - vertex_start[1],
                    -(vertex_end[0] - vertex_start[0])]
      end
      edges
    end

    # Dot product
    def vecDotProd(a, b)
      (a[0] * b[0]) + (a[1] * b[1])
    end

    # Calculates the minimum point and maximum point projected onto the line
    def calculate_minmax(shape, line)
      min = vecDotProd(shape.first, line)
      max = vecDotProd(shape.first, line)
      shape.each_with_index do |vertex, _vertex_index|
        dot = vecDotProd(vertex, line)
        if dot > max
          max = dot
        elsif dot < min
          min = dot
        end
      end
      [max, min]
    end
  end
end

Rl.target_fps = 60
Rl.while_window_open do
  if Rl.key_pressed? 61 # plus/equal
    if (Rl.key_down? 340) || (Rl.key_down? 344)
      Target.obj.sides += 1 unless Target.obj.sides == 9
    else
      MouseFollow.obj.sides += 1 unless MouseFollow.obj.sides == 9
    end
  end
  if Rl.key_pressed? 45 # minus/underscore
    if (Rl.key_down? 340) || (Rl.key_down? 344)
      Target.obj.sides -= 1 unless Target.obj.sides == 3
    else
      MouseFollow.obj.sides -= 1 unless MouseFollow.obj.sides == 3
    end
  end
  if Rl.key_down? 65 # a
    if (Rl.key_down? 340) || (Rl.key_down? 344)
      Target.obj.angle -= (Math::PI/180) * 2
    else
      MouseFollow.obj.angle -= (Math::PI/180) * 2
    end
  end
  if Rl.key_down? 68 # d
    if (Rl.key_down? 340) || (Rl.key_down? 344)
      Target.obj.angle += (Math::PI/180) * 2
    else
      MouseFollow.obj.angle += (Math::PI/180) * 2
    end
  end
  if Rl.key_down? 87 # w
    if (Rl.key_down? 340) || (Rl.key_down? 344)
      Target.obj.size += 1
    else
      MouseFollow.obj.size += 1
    end
  end
  if Rl.key_down? 83 # s
    if (Rl.key_down? 340) || (Rl.key_down? 344)
      Target.obj.size -= 1
    else
      MouseFollow.obj.size -= 1
    end
  end
  Rl.draw(clear_color: Rl::Color.black) do
    MouseFollow.obj.x = Rl.mouse_x
    MouseFollow.obj.y = Rl.mouse_y
    if SAT.hitbox_check(
        Array.new(MouseFollow.obj.sides) do |side|
          [MouseFollow.obj.points[side][:x],
           MouseFollow.obj.points[side][:y]]
        end,
        Array.new(Target.obj.sides) do |side|
          [Target.obj.points[side][:x],
           Target.obj.points[side][:y]]
        end
    )
      MouseFollow.entity.component[Cmp::ShapeColor].color = Rl::Color.fire_brick
    else
      MouseFollow.entity.component[Cmp::ShapeColor].color = Rl::Color.lime_green
    end
    Sys::DrawShape.call
  end
end
