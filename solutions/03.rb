module Graphics

  class Canvas

    require 'set'
    attr_reader :width, :height

    def initialize(width, height)
      @width = width
      @height = height
      @filled_pixels = Set.new
    end

    def set_pixel(x, y)
      @filled_pixels.add [x, y]
    end

    def pixel_at?(x, y)
      @filled_pixels.member? [x, y]
    end

    def draw(figure)
      figure.pixels.each { |pixel| set_pixel pixel.x, pixel.y}
    end

    def render_as(renderer)
      rendered_canvas = renderer.render_canvas self
      puts rendered_canvas
      rendered_canvas
    end

    def clear
      @filled_pixels = Set.new
    end
  end

  class Point

    attr_reader :x, :y
    alias_method :eql?, :==

    def initialize(x, y)
      @x = x
      @y = y
    end

    def coordinates
      [x, y]
    end

    def pixels
      [self]
    end

    def <=>(other)
      coordinates <=> other.coordinates
    end

    def ==(other)
      (x == other.x and y == other.y)
    end

    def hash
      coordinates.hash
    end
  end

  class Line

    attr_reader :from, :to
    alias_method :eql?, :==

    def initialize(from, to)
      @from, @to = [from, to].sort
    end

    def ==(other)
      (from == other.from and to == other.to) or (from == other.to and to == other.from)
    end

    def hash
      [from.coordinates, to.coordinates].hash
    end

    def pixels
      distances = [(to.x - from.x).abs, -(to.y - from.y).abs]
      steps = [from.x <= to.x ? 1 : -1, from.y <= to.y ? 1 : -1]
      error = distances.reduce(&:+)
      line_points_bresenham(from, error, distances, steps)
    end

    private

    def line_points_bresenham(point, error, distances, steps)
      points = [point]
      loop do
        break if point == to or point.x < 0
        point, error = calculate_next_point(point, error, distances, steps)
        points << point
      end
      points
    end

    def calculate_next_point(point, error, distances, steps)
      new_coordinates = point.coordinates.each_with_index.map do |coordinate, index|
        if should_change_coordinates?(distances, 2 * error)[index]
          coordinate += steps[index]
          error += distances[(index - 1).abs]
        end
        coordinate
      end
      [Point.new(new_coordinates[0], new_coordinates[1]), error]
    end

    def should_change_coordinates?(distances, error)
      [error >= distances[1], error < distances[0]]
    end

  end

  class Rectangle

    attr_reader :left, :right
    attr_reader :top_left, :top_right, :bottom_left, :bottom_right
    alias_method :eql?, :==

    def initialize(first_point, second_point)
      @left, @right = [first_point, second_point].sort
      @top_left, @bottom_left  = [left, Point.new(left.x, right.y)].sort
      @top_right, @bottom_right = [right, Point.new(right.x, left.y)].sort
    end

    def pixels
      vertexes = [top_left, top_right, bottom_right, bottom_left, top_left]
      vertexes.each_cons(2).map { |from, to| Graphics::Line.new(from, to).pixels }.flatten
    end

    def ==(other)
      top_left == other.top_left and bottom_right == other.bottom_right
    end

    def hash
      [top_left, bottom_right].hash
    end

  end

  module Renderers

    module Renderer
      def render_canvas(canvas)
        @@canvas = canvas
        0.upto(canvas.height - 1).map do |y|
          row = 0.upto(canvas.width - 1).map { |x| render_pixel_at(x, y) } * ""
        end * line_separator
      end

      def render_pixel_at(x, y)
        @@canvas.pixel_at?(x, y) ? filled_pixel : empty_pixel
      end
    end

    class Ascii

      extend Renderer

      class << self

        def line_separator
          "\n"
        end

        def filled_pixel
          "@"
        end

        def empty_pixel
          "-"
        end
      end
    end

    class Html

      extend Renderer

      class << self
        def line_separator
          "<br>"
        end

        def filled_pixel
          "<b></b>"
        end

        def empty_pixel
          "<i></i>"
        end
        def render_canvas(canvas)
          output = "#{<<HTML_HEADER}#{super}#{<<HTMLL_FOOTER}"
  <!DOCTYPE html><html><head><title>Rendered Canvas</title>
  <style type='text/css'>
    .canvas {font-size: 1px;line-height: 1px;}
    .canvas * {display: inline-block;width: 10px;height: 10px;border-radius: 5px;}
    .canvas i {background-color: #eee;}
    .canvas b {background-color: #333;}
  </style></head><body><div class="canvas">
HTML_HEADER
            </div></body></html>
HTMLL_FOOTER
          end
        end
      end
    end

  end