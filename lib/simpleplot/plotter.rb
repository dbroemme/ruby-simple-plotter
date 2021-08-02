require 'gosu'
require 'date'

module SimplePlot
    # Common constants that convert degrees to radians
    DEG_0 = 0
    DEG_45 = Math::PI * 0.25
    DEG_90 = Math::PI * 0.5
    DEG_135 = Math::PI * 0.75 
    DEG_180 = Math::PI
    DEG_225 = Math::PI * 1.25 
    DEG_270 = Math::PI * 1.5
    DEG_315 = Math::PI * 1.75
    DEG_360 = Math::PI * 2

    def scale(val, max_value, scaled_max) 
        pct = val.to_f / max_value.to_f 
        scaled_max.to_f * pct
    end

    class PlotPoint
        attr_accessor :x
        attr_accessor :y 
        attr_accessor :pixel_x
        attr_accessor :pixel_y 
        attr_accessor :color 

        def initialize(x, y, color = Gosu::Color::GREEN) 
            @x = x 
            @y = y 
            @color = color
        end

        def to_display 
            "#{@x}, #{@y}"
        end

        def distance_x(other_point)
            other_point.x - @x
        end 

        def distance_y(other_point)
            other_point.y - @y
        end 

        def abs_distance(other_point)
            (other_point.x - @x).abs + (other_point.y - @y).abs
        end 

        def abs_distance_x(other_point)
            (other_point.x - @x).abs
        end 

        def abs_distance_y(other_point)
            (other_point.y - @y).abs
        end 
    end 

    class SimplePlot
        attr_accessor :data
        attr_accessor :widget_width
        attr_accessor :widget_height
        attr_accessor :axis_labels_color
        attr_accessor :grid_line_color
        attr_accessor :zero_line_color
        attr_accessor :cursor_line_color

        def initialize(start_x = 0, start_y = 0)
            ########################################
            # top left origin of widget on screen  #
            ########################################
            @start_x = start_x
            @start_y = start_y

            @data = []

            @axis_labels_color = Gosu::Color::CYAN
            @grid_line_color = Gosu::Color::GRAY
            @zero_line_color = Gosu::Color::BLUE
            @cursor_line_color = Gosu::Color::GREEN
            @font = Gosu::Font.new(32)
            @display_grid = true
            @display_lines = false

            @widget_width = 800
            @widget_height = 600
            @graph_width = @widget_width - 200
            @graph_height = @widget_height - 200
        end
    
        def x_val_to_pixel(val)
            x_pct = (@right_x - val) / @x_range 
            @widget_width - (@graph_width.to_f * x_pct).round
        end 

        def y_val_to_pixel(val)
            y_pct = (@top_y - val) / @y_range 
            (@graph_height.to_f * y_pct).round
        end

        def x_pixel_to_screen(x)
            @start_x + x
        end

        def y_pixel_to_screen(y)
            @start_y + y
        end

        def draw_x(x)
            x_pixel_to_screen(x_val_to_pixel(x)) 
        end 

        def draw_y(y)
            y_pixel_to_screen(y_val_to_pixel(y)) 
        end 

        def calculate_pixels_and_labels 
            @top_y = 1.to_f
            @bottom_y = 0.to_f
            @right_x = 1.to_f
            @left_x = 0.to_f

            @data.each do |point|
                if point.x < @left_x 
                    @left_x = point.x.floor 
                elsif point.x > @right_x 
                    @right_x = point.x.ceil
                end 

                if point.y < @bottom_y 
                    @bottom_y = point.y.floor 
                elsif point.x > @right_x 
                    @top_y = point.y.ceil
                end 
            end 

            @x_range = @right_x - @left_x
            @y_range = @top_y - @bottom_y

            @x_axis_labels = []
            @x_axis_labels << @left_x.round(2)
            @x_axis_labels << (@left_x + (@x_range * 0.25)).round(2)
            @x_axis_labels << (@left_x + (@x_range * 0.5)).round(2)
            @x_axis_labels << (@left_x + (@x_range * 0.75)).round(2)
            @x_axis_labels << @right_x.round(2)
            @y_axis_labels = []
            @y_axis_labels << @top_y.round(2)
            @y_axis_labels << (@top_y - (@y_range * 0.25)).round(2)
            @y_axis_labels << (@top_y - (@y_range * 0.5)).round(2)
            @y_axis_labels << (@top_y - (@y_range * 0.75)).round(2)
            @y_axis_labels << @bottom_y.round(2)
        end 

        def render
            calculate_pixels_and_labels

            Gosu::draw_line x_pixel_to_screen(200), y_pixel_to_screen(0), @axis_labels_color,
                            x_pixel_to_screen(200), y_pixel_to_screen(@graph_height), @axis_labels_color
            Gosu::draw_line x_pixel_to_screen(200), y_pixel_to_screen(@graph_height), @axis_labels_color,
                            x_pixel_to_screen(200 + @graph_width), y_pixel_to_screen(@graph_height), @axis_labels_color

            y = 0
            @y_axis_labels.each do |label|
                Gosu::draw_line 180, y, @axis_labels_color, 200, y, @axis_labels_color
                @font.draw_text(label, 36, (y == 0 ? 0 : y - 16), 1, 1, 1, @axis_labels_color)
                y = y + 100
            end

            x = 200
            @x_axis_labels.each do |label|
                Gosu::draw_line x, 400, @axis_labels_color, x, 420, @axis_labels_color
                @font.draw_text(label, (x > 700 ? 760 : x - 18), 426, 1, 1, 1, @axis_labels_color)
                x = x + 150
            end

            # Draw the data points
            @data.each do |point|
                point.pixel_x = draw_x(point.x)
                point.pixel_y = draw_y(point.y)
                Gosu::draw_rect(point.pixel_x - 2, point.pixel_y - 2, 4, 4, point.color, 2) 
            end

            # Optionally draw the line connecting data points
            if @data.length > 1 and @display_lines
                @data.inject(@data[0]) do |last, the_next|
                    Gosu::draw_line last.pixel_x, last.pixel_y, last.color,
                            the_next.pixel_x, the_next.pixel_y, last.color, 2
                    the_next
                end
            end

            if @display_grid 
                grid_x = @left_x + 1
                grid_y = @bottom_y + 1
                while grid_y < @top_y
                    adj_x = x_val_to_pixel(grid_x)
                    adj_y = y_val_to_pixel(grid_y)
                    last_x = x_val_to_pixel(@right_x)
                    color = @grid_line_color
                    if grid_y == 0 and grid_y != @bottom_y.to_i
                        color = @zero_line_color
                    end
                    Gosu::draw_line adj_x, adj_y, color, last_x, adj_y, color, 12
                    grid_y = grid_y + 1
                end
                grid_y = @bottom_y
                while grid_x < @right_x
                    adj_x = x_val_to_pixel(grid_x)
                    adj_y = y_val_to_pixel(grid_y)
                    last_y = y_val_to_pixel(@top_y)
                    color = @grid_line_color
                    if grid_x == 0 and grid_x != @left_x.to_i
                        puts "Compared #{grid_x} to #{left_x}"
                        color = @zero_line_color 
                    end
                    Gosu::draw_line adj_x, adj_y, color, adj_x, last_y, color, 12
                    grid_x = grid_x + 1
                end
            end
        end

        def draw_cursor_lines(mouse_x, mouse_y)
            Gosu::draw_line mouse_x, 0, @cursor_line_color, mouse_x, 399, @cursor_line_color
            Gosu::draw_line 201, mouse_y, @cursor_line_color, 799, mouse_y, @cursor_line_color
                
            x_pct = (800 - mouse_x).to_f / 600.to_f
            x_val = @right_x - (x_pct * @x_range)
            y_pct = mouse_y.to_f / 400.to_f
            y_val = @top_y - (y_pct * @y_range)

            @font.draw_text("#{x_val.round(2).to_s}, #{y_val.round(2).to_s}", 10, 568, 1, 1, 1, Gosu::Color::WHITE) 
        end 

        def button_down id, mouse_x, mouse_y
            if id == Gosu::KbG 
                @display_grid = !@display_grid
            elsif id == Gosu::KbL
                @display_lines = !@display_lines
            end
        end
    end  
end
