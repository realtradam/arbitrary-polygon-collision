require 'ruby2d'
require 'ruby2d/camera'

#DEBUG: used to colour all debug lines unique colours
$colors = ['blue', 'teal', 'green', 'lime',
           'yellow', 'orange', 'red', 'fuchsia']

#DEBUG: used to draw, store and update debug lines
class DebugLines
  class <<self
    def [](index)
      data[index] ||= Camera::Line.new(color: 'red', z: 99, width: 5)
    end

    def data
      @data ||= []
    end
  end
end

# The coordinates of the 2 shapes being tested for collision
sv1 = {x1: 275.0 - 275.0, y1: 175.0 - 175.0,
       x2: 375.0 - 275.0, y2: 225.0 - 175.0,
       x3: 300.0 - 275.0, y3: 350.0 - 175.0,
       x4: 250.0 - 275.0, y4: 250.0 - 175.0}

sv2 = {x1: 200.0, y1: 100.0,
       x2: 200.0, y2: 200.0,
       x3: 100.0, y3: 200.0,
       x4: 100.0, y4: 100.0}

# The 2 shapes being tested for collision
s1 = Camera::Quad.new(
  **sv1,
  color: 'aqua',
  z: 10
)

s2 = Camera::Quad.new(
  **sv2,
  color: 'olive',
  z: 10
)

# Creates edges out using coordinates and then gets the normal
def build_inverted_edges(shape)
  edges = []
  shape.each_with_index do |vertex_start, index|
    if index == shape.length - 1
      vertex_end = shape[0]
    else
      vertex_end = shape[index + 1]
    end
    edges.push [vertex_end[1] - vertex_start[1],
                -vertex_end[0] + vertex_start[0]]
  end
  edges
end

# Dot product
def vecDotProd(a,b)
  return (a[0] * b[0]) + (a[1] * b[1])
end

# The hitbox logic
def hitbox_check(shape_a, shape_b)

  # Get normals of both shapes
  inverted = build_inverted_edges(shape_b)
  inverted.concat(build_inverted_edges(shape_a))

  #DEBUG
  if $i == 0
    puts
    puts "debug of inverted edges:"
    pp inverted
  end

  inverted.each_with_index do |line, line_index|

    # Initialize max and min
    amin = vecDotProd(shape_a.first, line)
    amax = vecDotProd(shape_a.first, line)
    bmin = vecDotProd(shape_b.first, line)
    bmax = vecDotProd(shape_b.first, line)

    # Determine max and min of a_shape
    shape_a.each_with_index do |vertex, vertex_index|
      dot = vecDotProd(vertex, line)
      if dot > amax
        amax = dot
      elsif dot < amin
        amin = dot
      end
    end

    # Determine max and min of b_shape
    shape_b.each_with_index do |vertex, vertex_index|
      dot = vecDotProd(vertex, line)
      if dot > bmax
        bmax = dot
      elsif dot < bmin
        bmin = dot
      end
    end

    #DEBUG: display the lines, transluscent if they are not "seperating"
    # If all lines are transluscent then the logic believes the
    # shapes are colliding
    if line_index < shape_a.length
      DebugLines[line_index].x1 = shape_a[line_index][0]
      DebugLines[line_index].y1 = shape_a[line_index][1]
      if shape_a[line_index].nil?
        DebugLines[line_index].x2 = shape_a[line_index + 1][0]
        DebugLines[line_index].y2 = shape_a[line_index + 1][1]
      else
        DebugLines[line_index].x2 = shape_a[0][0]
        DebugLines[line_index].y2 = shape_a[0][1]
      end
    else
      DebugLines[line_index].x1 = shape_b[line_index - shape_a.length][0]
      DebugLines[line_index].y1 = shape_b[line_index - shape_a.length][1]
      if shape_a[line_index - shape_a.length + 1].nil?
        DebugLines[line_index].x2 = shape_b[0][0]
        DebugLines[line_index].y2 = shape_b[0][1]
      else
        DebugLines[line_index].x2 = shape_b[line_index - shape_a.length + 1][0]
        DebugLines[line_index].y2 = shape_b[line_index - shape_a.length + 1][1]
      end
    end
    DebugLines[line_index].color = $colors[line_index % $colors.length]

    #DEBUG: print out line information
    if $i == 0
      puts
      puts $colors[line_index % $colors.length]
      puts line_index
      puts "x1 #{DebugLines[line_index].x1}"
      puts "y1 #{DebugLines[line_index].y1}"
      puts "x2 #{DebugLines[line_index].x2}"
      puts "y2 #{DebugLines[line_index].y2}"
      puts "(((#{amin} < #{bmax}) && (#{amin} > #{bmin})) || ((#{bmin} < #{amax}) && (#{bmin} > #{amin})))"
    end
    if (((amin <= bmax) && (amin >= bmin)) || ((bmin <= amax) && (bmin >= amin)))
      DebugLines[line_index].color.a = 0.2
    else
      DebugLines[line_index].color.a = 1.0

      # The logic should end the calculations early once it detects lack of collision
      # however for debug purposes this is disabled
      #return false
    end

    #DEBUG: make the debug lines effectively infinitly long
    tempx1 = DebugLines[line_index].x1
    tempx2 = DebugLines[line_index].x2
    tempy1 = DebugLines[line_index].y1
    tempy2 = DebugLines[line_index].y2
    DebugLines[line_index].x1 = (tempx1 *(1+1000)/2) + (tempx2 * (1-1000)/2)
    DebugLines[line_index].y1 = (tempy1 *(1+1000)/2) + (tempy2 * (1-1000)/2)
    DebugLines[line_index].x2 = (tempx2 *(1+1000)/2) + (tempx1 * (1-1000)/2)
    DebugLines[line_index].y2 = (tempy2 *(1+1000)/2) + (tempy1 * (1-1000)/2)
  end
  true
end

# Move camera
on :key_held do |event|
  if event.key == 'w'
    Camera.y -= 5
  end
  if event.key == 's'
    Camera.y += 5
  end
  if event.key == 'a'
    Camera.x -= 5
  end
  if event.key == 'd'
    Camera.x += 5
  end
end

# Initialize frame counter
# resets to 0 periodically by a set amount
$i = 0

# "Game" loop
update do
  # Advance frame
  $i += 1

  # Reset every 5 frames
  $i %= 5

  # Update shape 1 position to mouse
  s1.x = Camera.coordinate_to_worldspace(get(:mouse_x),0)[0]
  s1.y = Camera.coordinate_to_worldspace(0, get(:mouse_y))[1]

  # Check hitboxes
  a = hitbox_check(
    [[s2.x1, s2.y1],
     [s2.x2, s2.y2],
     [s2.x3, s2.y3],
     [s2.x4, s2.y4]],
  [[s1.x1 + s1.x, s1.y1 + s1.y],
   [s1.x2 + s1.x, s1.y2 + s1.y],
   [s1.x3 + s1.x, s1.y3 + s1.y],
   [s1.x4 + s1.x, s1.y4 + s1.y]],
  )

  #DEBUG
  if $i == 0
    pp [[s2.x1, s2.y1],
        [s2.x2, s2.y2],
        [s2.x3, s2.y3],
        [s2.x4, s2.y4]]
    pp [[s1.x1 + s1.x, s1.y1 + s1.y],
        [s1.x2 + s1.x, s1.y2 + s1.y],
        [s1.x3 + s1.x, s1.y3 + s1.y],
        [s1.x4 + s1.x, s1.y4 + s1.y]]
  end

end

show
