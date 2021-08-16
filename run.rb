require 'ruby2d'
require 'ruby2d/camera'

# SOURCES FOR MATH USED
# here are the websites I tried to look at, understand, and implement the math from(unsuccessfully)
#
# Currently Main Source:
# http://programmerart.weebly.com/separating-axis-theorem.html
#
# Other sources read through:
# https://dyn4j.org/2010/01/sat/
# https://www.sevenson.com.au/programming/sat/
#
# more stuff near the bottom of this link:
# https://developer.mozilla.org/en-US/docs/Games/Techniques/2D_collision_detection

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
svA = {x1: 200.0, y1: 100.0,
       x2: 200.0, y2: 200.0,
       x3: 100.0, y3: 200.0,
       x4: 100.0, y4: 100.0}

svB = {x1: 275.0 - 275.0, y1: 175.0 - 175.0,
       x2: 375.0 - 275.0, y2: 225.0 - 175.0,
       x3: 300.0 - 275.0, y3: 350.0 - 175.0,
       x4: 250.0 - 275.0, y4: 250.0 - 175.0}

# The 2 shapes being tested for collision

sA = Camera::Quad.new(
  **svA,
  color: 'olive',
  z: 10
)

sB = Camera::Quad.new(
  **svB,
  color: 'aqua',
  z: 10
)

# The hitbox logic
def hitbox_check(shape_a, shape_b)

  # Get normals of both shapes
  inverted = build_inverted_edges(shape_b)
  inverted.concat(build_inverted_edges(shape_a))

  #DEBUG
  debug_outer_loop(inverted)

  inverted.each_with_index do |line, line_index|

    # Determine max and min of a and b shapes
    amax, amin = calculate_minmax(shape_a, line)
    bmax, bmin = calculate_minmax(shape_b, line)

    #DEBUG
    debug_inner_loop(shape_a, shape_b, line_index, amax, amin, bmax, bmin)

    if (((amin <= bmax) && (amin >= bmin)) || ((bmin <= amax) && (bmin >= amin)))
      #next
    else
      # The logic should end the calculations early once it detects lack of collision
      # however for debug purposes this is disabled
      #return false
    end
  end
  true
end

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
                -(vertex_end[0] - vertex_start[0])]
  end
  edges
end

# Dot product
def vecDotProd(a,b)
  return (a[0] * b[0]) + (a[1] * b[1])
end

# Calculates the minimum point and maximum point projected onto the line
def calculate_minmax(shape, line)
  min = vecDotProd(shape.first, line)
  max = vecDotProd(shape.first, line)
  shape.each_with_index do |vertex, vertex_index|
    dot = vecDotProd(vertex, line)
    if dot > max
      max = dot
    elsif dot < min
      min = dot
    end
  end
  [max, min]
end

# Displays debug info(used inside the inverted.each loop)
def debug_inner_loop(shape_a, shape_b, line_index, amax, amin, bmax, bmin)
  #DEBUG: display the lines(uninverted), transluscent if they are not "seperating"
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

# Displays debug info(used outside the inverted.each loop)
def debug_outer_loop(inverted)
  if $i == 0
    puts
    puts "debug of inverted edges:"
    pp inverted
  end
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
  sB.x = Camera.coordinate_to_worldspace(get(:mouse_x),0)[0]
  sB.y = Camera.coordinate_to_worldspace(0, get(:mouse_y))[1]

  # Check hitboxes
  a = hitbox_check(
    [[sA.x1, sA.y1],
     [sA.x2, sA.y2],
     [sA.x3, sA.y3],
     [sA.x4, sA.y4]],
  [[sB.x1 + sB.x, sB.y1 + sB.y],
   [sB.x2 + sB.x, sB.y2 + sB.y],
   [sB.x3 + sB.x, sB.y3 + sB.y],
   [sB.x4 + sB.x, sB.y4 + sB.y]],
  )

  #DEBUG
  if $i == 0
    pp [[sA.x1, sA.y1],
        [sA.x2, sA.y2],
        [sA.x3, sA.y3],
        [sA.x4, sA.y4]]
    pp [[sB.x1 + sB.x, sB.y1 + sB.y],
        [sB.x2 + sB.x, sB.y2 + sB.y],
        [sB.x3 + sB.x, sB.y3 + sB.y],
        [sB.x4 + sB.x, sB.y4 + sB.y]]
  end

end

show
