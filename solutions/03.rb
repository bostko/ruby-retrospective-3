module Graphics
  class Canvas
    attr_reader :width, :height

    def initialize(width, height)
      @width, @height = width, height
      @container = Array.new(height) { Array.new width, false }
    end

    def set_pixel(x, y)
      if y < @container.length && x < @container[y].length
        @container[y][x] = true
      end
    end

    def pixel_at?(x, y)
      @container[y][x]
    end

    def draw(figure)
      figure.rasterize.each do |point|
        draw_point(Point.new(figure.start.x + point.x, figure.start.y + point.y))
      end
    end

    def render_as renderer
      if renderer == Renderers::Ascii
        map_lane('@', '-')
      elsif renderer == Renderers::Html
        output = <<HTML
<!DOCTYPE html>
<html>
<head>
  <title>Rendered Canvas</title>
  <style type="text/css">
    .canvas {
      font-size: 1px;
      line-height: 1px;
    }
    .canvas * {
      display: inline-block;
      width: 10px;
      height: 10px;
      border-radius: 5px;
    }
    .canvas i {
      background-color: #eee;
    }
    .canvas b {
      background-color: #333;
    }
  </style>
</head>
<body>
  <div class="canvas">
HTML
        output += "#{map_lane('<b></b>', '<i></i>', '<br>')}</div></body></html>"
      end
    end

    def map_lane(filled, empty, row_delimiter = "\n")
      @container.map do |row|
        map_lane_row(row, filled, empty)
      end.join row_delimiter
    end

    private

    def map_lane_row(row, filled, empty)
      row.map { |s| s ? filled : empty }.join
    end

    def draw_point(point)
      @container[point.y][point.x] = true
    end
  end

  module Renderers
    class Ascii
    end

    class Html
    end
  end

  class Point
    attr_reader :x, :y

    def initialize(x, y)
      @x, @y = x, y
    end

    def ==(object)
      if object.kind_of? Point
        object.x == x && object.y == y
      else
        false
      end
    end

    def eql?(point)
      point.hash == hash
    end

    def hash
      x * 100 + y
    end

    def rasterize
      [self]
    end

    def start
      Point.new(0, 0)
    end

    def +(point)
      Point.new(@x + point.x, @y + point.y)
    end

    def -(point)
      Point.new(@x - point.x, @y - point.y)
    end
  end

  class Line
    def initialize(first, second)
      @first, @second = first, second
    end

    def from
      if @first.x < @second.x
        @first
      elsif @first.x > @second.x
        @second
      else
        y_from
      end
    end

    def to
      if @first.x > @second.x
        @first
      elsif @first.x < @second.x
        @second
      else
        y_to
      end
    end

    def start
      from
    end

    def rasterize(shift = Point.new(0, 0))
      if from.x == to.x
        (from.y..to.y).map { |y| Point.new(start.x, y) - start + shift }
      elsif from.y == to.y
        (from.x..to.x).map { |x| Point.new(x, start.y) - start + shift }
      else
        BresenhamAlgorithm.new(from, to).rasterize
      end
    end

    def ==(line)
      from == to
    end

    def eql?(line)
      line.hash == hash
    end

    def hash
      from.hash * 1000 + to.hash
    end

    private

    def y_from
      if @first.y < @second.y
        @first
      else
        @second
      end
    end

    def y_to
      if @first.y > @second.y
        @first
      else
        @second
      end
    end

    class BresenhamAlgorithm
      def initialize(from, to)
        @from, @to = from, to
      end

      def rasterize
        @error = 0.0
        @y     = @from.y - 1

        (@from.x - 1).upto(@to.x - 1).map do |x|
          calculate_next_point(x, @y).tap { calculate_next_y_approximation }
        end
      end

      private

      def calculate_next_point(x, y)
        if steep_slope?
          Point.new y, x
        else
          Point.new x, y
        end
      end

      def steep_slope?
        (@to.y - @from.y).abs > (@to.x - @from.x).abs
      end

      def calculate_next_y_approximation
        @error += error_delta
        if @error >= 0.5
          @error -= 1.0
          @y += vertical_drawing_direction
        end
      end

      def vertical_drawing_direction
        @from.y < @to.y ? 1 : -1
      end

      def error_delta
        delta_x = @to.x - @from.x
        delta_y = (@to.y - @from.y).abs

        delta_y.to_f / delta_x
      end
    end
  end

  class Rectangle
    attr_reader :left, :right

    def initialize(first, second)
      diagonal = Line.new(first, second)
      @left = diagonal.from
      @right = diagonal.to
    end

    def start
      top_left
    end

    def top_left
      left.y < right.y && left || Point.new(left.x, right.y)
    end

    def top_right
      right.y < left.y && right || Point.new(right.x, left.y)
    end

    def bottom_left
      left.y > right.y && left || Point.new(left.x, right.y)
    end

    def bottom_right
      right.y > left.y && right || Point.new(right.x, left.y)
    end

    def ==(rectangle)
      top_left == rectangle.top_left and bottom_right == rectangle.bottom_right
    end

    def eql?(rectangle)
      rectangle.hash == hash
    end

    def rasterize
      [
        [top_left, top_right], [top_right, bottom_right],
        [bottom_right, bottom_left], [bottom_left, top_left],
      ].map do |from, to|
        Line.new(from, to).rasterize(top_left - from)
      end.reduce(:+)
    end

    def hash
      Line.new(top_left, bottom_right).hash
    end
  end
end

