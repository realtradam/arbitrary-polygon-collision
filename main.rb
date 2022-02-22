GameName = 'Hextest'
Rl.init_window(800, 600, GameName)

include FECS

source_shine = Rl::Rectangle.new(7,
                                 128,
                                 111,
                                 128)
source = Rl::Rectangle.new(7,
                           0,
                           111,
                           128)

offset_x = 100
offset_y = 100

Cmp.new('Position', x: 0, y: 0)
#Cmp.new('Shape', radius: 50, line_thickness: 5, sides: 3)
Cmp.new('Shape', :obj)
Cmp.new('ArraySpot', :x, :y)
Cmp.new('ShapeColor', :color)
Cmp.new('BorderColor', :color)

ShapeSize = 6.0 # needs to be float

Sys.new('InitGrid') do
  arry = Array.new(5) do |x|
    Array.new(5) do |y|
      x_thingie = 90
      Ent.new(
        Cmp::Position.new(
          x: (x * x_thingie) + (y * (x_thingie/2)) + offset_x,
          y: (y * 50) + (y * 30) + offset_y,
        ),
        Cmp::Shape.new(sides: 6),
        Cmp::ArraySpot.new(x: x, y: y)
      )
    end
  end
end


#Sys::InitGrid.call

Sys.new('InitShape') do
  xoff = 350
  yoff = 350
  multi = 100
  #shape = Cmp::Shape.new(sides:6)
  ShapeSize.to_i.times do |point|
    Ent.new(
      Cmp::Position.new(
        x: Math.sin((point/ShapeSize) * Math::PI * 2) * multi + xoff,
        y: Math.cos((point/ShapeSize) * Math::PI * 2) * multi + yoff
      ),
      Cmp::Shape.new(sides:ShapeSize)
    )
  end
end

#Sys::InitShape.call


class Shape
  attr_reader :angle, :size, :x, :y, :sides
  def initialize(angle: 0, size: 0, x: 0, y: 0, sides: 3)
    @sides = sides
    @angle = angle
    @size = size
    @x = x
    @y = y
    #self.points = Array.new(6) do |point_num|
    #  { x: Math.sin(((point_num/6.0) * Math::PI * 2) + angle) * size + x,
    #    y: Math.cos(((point_num/6.0) * Math::PI * 2) + angle) * size + y }
    #end
    update
  end

  def points
    @points ||= []
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
      points[point_num][:x] = Math.sin(((point_num/sides.to_f) * Math::PI * 2) + angle) * size + x
      points[point_num][:y] = Math.cos(((point_num/sides.to_f) * Math::PI * 2) + angle) * size + y
    end
    [sides - points.length, 0].max.times do
      points.pop # strip extra points
    end
  end
end

MouseFollow = Cmp::Shape.new(obj: Shape.new(sides: 6, size: 100))
Target = Cmp::Shape.new(obj: Shape.new(sides: 6, size: 100, x: 300, y: 300))

Ent.new(
  MouseFollow,
  Cmp::ShapeColor.new(color: Rl::Color.dodger_blue),
  Cmp::BorderColor.new(color: Rl::Color.dodger_blue)
)

Ent.new(
  Target,
  Cmp::ShapeColor.new(color: Rl::Color.medium_orchid),
  Cmp::BorderColor.new(color: Rl::Color.medium_orchid)
)

Sys.new('DrawShape') do
  Ent.group(Cmp::Shape, Cmp::ShapeColor, Cmp::BorderColor) do |shape_cmp, color_cmp, border_color_cmp, entity|
    shape = shape_cmp.obj
    array_spot = false
    #if !entity.components[Cmp::ArraySpot].nil?
    #  array_spot = entity.component[Cmp::ArraySpot]
    #end
    Rl.draw_poly(center: Rl::Vector2.new(shape.x, shape.y),
                 radius: shape.size,
                 sides: shape.sides,
                 color: color_cmp.color)
    Rl.draw_poly_lines(center: Rl::Vector2.new(shape.x, shape.y),
                       radius: shape.size,
                       sides: shape.sides,
                       color: border_color_cmp.color,
                       line_thickness: 7)
    if array_spot
      "x: #{array_spot.x}".draw(x: position.x - 30, y: position.y - 20, color: Rl::Color.dark_violet)
      "y: #{array_spot.y}".draw(x: position.x - 30, y: position.y, color: Rl::Color.dark_violet)
    end
  end
end

module SAT
  class << self
    # The hitbox logic
    def hitbox_check(shape_a, shape_b)
      # Get normals of both shapes
      inverted = build_inverted_edges(shape_a)
      inverted.concat(build_inverted_edges(shape_b))

      #DEBUG
      #debug_outer_loop(inverted)

      inverted.each_with_index do |line, line_index|
        # Determine max and min of a and b shapes
        amax, amin = calculate_minmax(shape_a, line)
        bmax, bmin = calculate_minmax(shape_b, line)

        #DEBUG
        #debug_inner_loop(shape_a, shape_b, line_index, amax, amin, bmax, bmin)

        if ((amin <= bmax) && (amin >= bmin)) || ((bmin <= amax) && (bmin >= amin))
          #next
        else
          # The logic should end the calculations early once it detects lack of collision
          # however for debug purposes this is disabled
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
