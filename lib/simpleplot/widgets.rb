module SimplePlot
    class Widget 
        attr_accessor :x
        attr_accessor :y 
        attr_accessor :color 
        attr_accessor :width
        attr_accessor :height 
        attr_accessor :visible 
        attr_accessor :children 

        def initialize(x, y, color = Gosu::Color::GREEN) 
            @x = x 
            @y = y 
            @color = color
            @width = 1 
            @height = 1
            @visible = true 
            @children = []
        end

        def add_child(child) 
            @children << child 
        end

        def draw 
            if @visible 
                #puts "About to render #{self.class.name}"
                render
                @children.each do |child| 
                    child.draw 
                end 
            end 
        end
    end 

    class PlotPoint < Widget
        attr_accessor :data_point_size 

        def initialize(x, y, size = 4, color = Gosu::Color::GREEN) 
            super x, y, color 
            @data_point_size = size
            @half_size = @data_point_size / 2
        end

        def render 
            Gosu::draw_rect(@x - @half_size, @y - @half_size,
                            @data_point_size, @data_point_size,
                            @color, 2) 
        end 

        def to_display 
            "#{@x}, #{@y}"
        end
    end 

    class AxisLines < Widget
        def initialize(x, y, width, height, color = Gosu::Color::GREEN) 
            super x, y, color 
            @width = width 
            @height = height
        end

        def render
            Gosu::draw_line @x, @y, @color, @x, @y + @height, @color
            Gosu::draw_line @x, @y + @height, @color, @x + @width, @y + @height, @color
        end
    end
    
    class Line < Widget
        attr_accessor :x2
        attr_accessor :y2

        def initialize(x, y, x2, y2, color = Gosu::Color::GREEN) 
            super x, y, color 
            @x2 = x2 
            @y2 = y2
        end

        def render
            Gosu::draw_line x, y, @color, x2, y2, @color
        end
    end 

    class VerticalAxisLabel < Widget
        attr_accessor :label

        def initialize(x, y, label, font, color = Gosu::Color::GREEN) 
            super x, y, color 
            @label = label 
            @font = font
        end

        def render
            text_pixel_width = @font.text_width(@label)
            Gosu::draw_line @x - 20, @y, @color,
                            @x, @y, @color
            
            @font.draw_text(@label, @x - text_pixel_width - 28, @y - 16, 1, 1, 1, @color)
        end
    end 

    class HorizontalAxisLabel < Widget
        attr_accessor :label

        def initialize(x, y, label, font, color = Gosu::Color::GREEN) 
            super x, y, color 
            @label = label 
            @font = font
        end

        def render
            text_pixel_width = @font.text_width(@label)
            Gosu::draw_line @x, @y, @color, @x, @y + 20, @color
            @font.draw_text(@label, @x - (text_pixel_width / 2), @y + 26, 1, 1, 1, @color)
        end
    end 

    class Plot < Widget
        attr_accessor :points
        attr_accessor :left_x
        attr_accessor :right_x
        attr_accessor :bottom_y
        attr_accessor :top_y
        attr_accessor :x_range
        attr_accessor :y_range
        attr_accessor :display_grid

        def initialize(x, y, width, height) 
            super x, y, color 
            @width = width 
            @height = height
            @display_grid = false
        end

        def set_range(l, r, b, t) 
            @left_x = l 
            @right_x = r 
            @bottom_y = b 
            @top_y = t 
            @x_range = @right_x - @left_x
            @y_range = @top_y - @bottom_y
        end 

        def range_set?
            not @left_x.nil?
        end 

        def is_on_screen(point) 
            point.x >= @left_x and point.x <= @right_x and point.y >= @bottom_y and point.y <= @top_y
        end 

        def add_data(data_points, color)
            if range_set?
                data_points.each do |point|
                    if is_on_screen(point) 
                        add_child PlotPoint.new(draw_x(point.x), draw_y(point.y))
                    end
                end
            else
                puts "ERROR: range not set, cannot add data"
            end
        end 

        def x_val_to_pixel(val)
            x_pct = (@right_x - val) / @x_range 
            @width - (@width.to_f * x_pct).round
        end 

        def y_val_to_pixel(val)
            y_pct = (@top_y - val) / @y_range 
            (@height.to_f * y_pct).round
        end

        def x_pixel_to_screen(x)
            @x + x
        end

        def y_pixel_to_screen(y)
            @y + y
        end

        def draw_x(x)
            x_pixel_to_screen(x_val_to_pixel(x)) 
        end 

        def draw_y(y)
            y_pixel_to_screen(y_val_to_pixel(y)) 
        end 

        def render
            # This children are the points, so nothing to do here
        end

        def display_grid
            if @display_grid 
                grid_widgets = []

                grid_x = @left_x
                grid_y = @bottom_y + 1
                while grid_y < @top_y
                    dx = draw_x(grid_x)
                    dy = draw_y(grid_y)
                    last_x = draw_x(@right_x)
                    color = @grid_line_color
                    if grid_y == 0 and grid_y != @bottom_y.to_i
                        color = @zero_line_color
                    end
                    grid_widgets << Line.new(dx, dy, last_x, dy, color) 
                    grid_y = grid_y + 1
                end
                grid_x = @left_x + 1
                grid_y = @bottom_y
                while grid_x < @right_x
                    dx = draw_x(grid_x)
                    dy = draw_y(grid_y)
                    last_y = draw_y(@top_y)
                    color = @grid_line_color
                    if grid_x == 0 and grid_x != @left_x.to_i
                        color = @zero_line_color 
                    end
                    grid_widgets << Line.new(dx, dy, dx, last_y, color) 
                    grid_x = grid_x + 1
                end

                grid_widgets.each do |gw| 
                    gw.draw 
                end
            end
        end
    end 
end