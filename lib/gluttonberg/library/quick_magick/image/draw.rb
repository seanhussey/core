module Gluttonberg
  module Library
    module QuickMagick
      module Draw
        def self.included(klass)
          klass.class_eval do
            extend  ClassMethods
            include InstanceMethods
          end
        end

        module ClassMethods
        end #ClassMethods

        module InstanceMethods
          # The shape primitives are drawn in the color specified by the preceding -fill setting.
          # For unfilled shapes, use -fill none.
          # You can optionally control the stroke (the "outline" of a shape) with the -stroke and -strokewidth settings.

          # draws a point at the given location in pixels
          # A point primitive is specified by a single point in the pixel plane, that is, by an ordered pair
          # of integer coordinates, x,y.
          # (As it involves only a single pixel, a point primitive is not affected by -stroke or -strokewidth.)
          def draw_point(x, y, options={})
            _draw(options, "point #{x},#{y}")
          end

          # draws a line between the given two points
          # A line primitive requires a start point and end point.
          def draw_line(x0, y0, x1, y1, options={})
            _draw_4_points("line", x0, y0, x1, y1, options)
          end

          # draw a rectangle with the given two corners
          # A rectangle primitive is specified by the pair of points at the upper left and lower right corners.
          def draw_rectangle(x0, y0, x1, y1, options={})
            _draw_4_points("rectangle", x0, y0, x1, y1, options)
          end

          # draw a rounded rectangle with the given two corners
          # wc and hc are the width and height of the arc
          # A roundRectangle primitive takes the same corner points as a rectangle
          # followed by the width and height of the rounded corners to be removed.
          def draw_round_rectangle(x0, y0, x1, y1, wc, hc, options={})
            _draw_6_points("roundRectangle",  x0, y0, x1, y1, wc, hc, options)
          end

          # The arc primitive is used to inscribe an elliptical segment in to a given rectangle.
          # An arc requires the two corners used for rectangle (see above) followed by
          # the start and end angles of the arc of the segment segment (e.g. 130,30 200,100 45,90).
          # The start and end points produced are then joined with a line segment and the resulting segment of an ellipse is filled.
          def draw_arc(x0, y0, x1, y1, a0, a1, options={})
            _draw_6_points("arc",  x0, y0, x1, y1, a0, a1, options)
          end

          # Use ellipse to draw a partial (or whole) ellipse.
          # Give the center point, the horizontal and vertical "radii"
          # (the semi-axes of the ellipse) and start and end angles in degrees (e.g. 100,100 100,150 0,360).
          def draw_ellipse(x0, y0, rx, ry, a0, a1, options={})
            _draw_6_points("ellipse",  x0, y0, rx, ry, a0, a1, options)
          end

          # The circle primitive makes a disk (filled) or circle (unfilled). Give the center and any point on the perimeter (boundary).
          def draw_circle(x0, y0, x1, y1, options={})
            _draw_4_points("circle", x0, y0, x1, y1, options)
          end

          # The polyline primitive requires three or more points to define their perimeters.
          # A polyline is simply a polygon in which the final point is not stroked to the start point.
          # When unfilled, this is a polygonal line. If the -stroke setting is none (the default), then a polyline is identical to a polygon.
          #  points - A single array with each pair forming a coordinate in the form (x, y).
          # e.g. [0,0,100,100,100,0] will draw a polyline between points (0,0)-(100,100)-(100,0)
          def draw_polyline(points, options={})
            _draw(options, "polyline #{points_to_str(points)}")
          end

          # The polygon primitive requires three or more points to define their perimeters.
          # A polyline is simply a polygon in which the final point is not stroked to the start point.
          # When unfilled, this is a polygonal line. If the -stroke setting is none (the default), then a polyline is identical to a polygon.
          #  points - A single array with each pair forming a coordinate in the form (x, y).
          # e.g. [0,0,100,100,100,0] will draw a polygon between points (0,0)-(100,100)-(100,0)
          def draw_polygon(points, options={})
            _draw(options, "polygon #{points_to_str(points)}")
          end

          # The Bezier primitive creates a spline curve and requires three or points to define its shape.
          # The first and last points are the knots and these points are attained by the curve,
          # while any intermediate coordinates are control points.
          # If two control points are specified, the line between each end knot and its sequentially
          # respective control point determines the tangent direction of the curve at that end.
          # If one control point is specified, the lines from the end knots to the one control point
          # determines the tangent directions of the curve at each end.
          # If more than two control points are specified, then the additional control points
          # act in combination to determine the intermediate shape of the curve.
          # In order to draw complex curves, it is highly recommended either to use the path primitive
          # or to draw multiple four-point bezier segments with the start and end knots of each successive segment repeated.
          def draw_bezier(points, options={})
            _draw(options, "bezier #{points_to_str(points)}")
          end

          # A path represents an outline of an object, defined in terms of moveto
          # (set a new current point), lineto (draw a straight line), curveto (draw a Bezier curve),
          # arc (elliptical or circular arc) and closepath (close the current shape by drawing a
          # line to the last moveto) elements.
          # Compound paths (i.e., a path with subpaths, each consisting of a single moveto followed by
          # one or more line or curve operations) are possible to allow effects such as donut holes in objects.
          # (See http://www.w3.org/TR/SVG/paths.html)
          def draw_path(path_spec, options={})
            _draw(options, "path #{path_spec}")
          end

          # Use image to composite an image with another image. Follow the image keyword
          # with the composite operator, image location, image size, and filename
          # You can use 0,0 for the image size, which means to use the actual dimensions found in the image header.
          # Otherwise, it is scaled to the given dimensions. See -compose for a description of the composite operators.
          def draw_image(operator, x0, y0, w, h, image_filename, options={})
            _draw(options, "image #{operator} #{x0},#{y0} #{w},#{h} \"#{image_filename}\"")
          end

          # Use text to annotate an image with text. Follow the text coordinates with a string.
          def draw_text(x0, y0, text, options={})
            _draw(options, "text #{x0},#{y0} '#{text}'")
          end

          private
            def _draw(options, draw_command_postfix)
              append_to_operators("draw", "#{options_to_str(options)} #{draw_command_postfix}")
            end

            # draw_ellipse, draw_arc, draw_round_rectangle
            def _draw_6_points(shape,  x0, y0, rx, ry, a0, a1, options={})
              _draw(options, "#{shape} #{x0},#{y0} #{rx},#{ry} #{a0},#{a1}")
            end

            def _draw_4_points(shape, x0, y0, x1, y1, options={})
              _draw(options, "#{shape} #{x0},#{y0} #{x1},#{y1}")
            end
        end #InstanceMethods
      end #Draw
    end
  end
end