require 'gosu'
require 'date'
require_relative 'shapes'

module SimplePlot
    VERSION = "0.1.0"

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

    class SimplePlot
        attr_accessor :data
        attr_accessor :widget_width
        attr_accessor :widget_height
        attr_accessor :axis_labels_color
        attr_accessor :grid_line_color
        attr_accessor :zero_line_color
        attr_accessor :cursor_line_color
        attr_accessor :data_point_size

        def initialize(width, height, start_x = 0, start_y = 0)
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
            @data_point_size = 4
            @font = Gosu::Font.new(32)
            @display_grid = true
            @display_lines = false
            @margin_size = 200
            @window_width = width 
            @window_height = height
        end

        def widget_width 
            @window_width - @start_x
        end 

        def widget_height
            @window_height - @start_y
        end 

        def graph_width 
            widget_width - @margin_size
        end 
        
        def graph_height 
            widget_height - @margin_size
        end

        def x_val_to_pixel(val)
            x_pct = (@right_x - val) / @x_range 
            widget_width - (graph_width.to_f * x_pct).round
        end 

        def y_val_to_pixel(val)
            y_pct = (@top_y - val) / @y_range 
            (graph_height.to_f * y_pct).round
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

        def calculate_axis_labels(adjust_for_data = true, left_x = 0, right_x = 1, bottom_y = 0, top_y = 1)
            @left_x = left_x.to_f
            @right_x = right_x.to_f
            @bottom_y = bottom_y.to_f
            @top_y = top_y.to_f

            if adjust_for_data
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
            end

            @x_range = @right_x - @left_x
            @y_range = @top_y - @bottom_y

            # TODO based on graph width and height, determine how many labels to show
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

        def is_on_screen(point) 
            point.x >= @left_x and point.x <= @right_x and point.y >= @bottom_y and point.y <= @top_y
        end 

        def render(width, height, update_count)
            Gosu::draw_line x_pixel_to_screen(@margin_size), y_pixel_to_screen(0), @axis_labels_color,
                            x_pixel_to_screen(@margin_size), y_pixel_to_screen(graph_height), @axis_labels_color
            Gosu::draw_line x_pixel_to_screen(@margin_size), y_pixel_to_screen(graph_height), @axis_labels_color,
                            x_pixel_to_screen(@margin_size + graph_width), y_pixel_to_screen(graph_height), @axis_labels_color

            y = 0
            @y_axis_labels.each do |label|
                Gosu::draw_line x_pixel_to_screen(@margin_size - 20), y_pixel_to_screen(y), @axis_labels_color,
                                x_pixel_to_screen(@margin_size), y_pixel_to_screen(y), @axis_labels_color
                @font.draw_text(label,
                                x_pixel_to_screen(36),
                                (y == 0 ? y_pixel_to_screen(0) : y_pixel_to_screen(y - 16)),
                                1, 1, 1, @axis_labels_color)
                y = y + 100
            end

            x = @margin_size
            @x_axis_labels.each do |label|
                Gosu::draw_line x_pixel_to_screen(x), y_pixel_to_screen(graph_height), @axis_labels_color,
                                x_pixel_to_screen(x), y_pixel_to_screen(graph_height) + 20, @axis_labels_color
                @font.draw_text(label,
                                (x > 700 ? x_pixel_to_screen(780) : x_pixel_to_screen(x - 18)),
                                y_pixel_to_screen(426),
                                1, 1, 1, @axis_labels_color)
                x = x + 150
            end

            # Draw the data points
            half_size = @data_point_size / 2
            @data.each do |point|
                if is_on_screen(point) 
                    point.pixel_x = draw_x(point.x)
                    point.pixel_y = draw_y(point.y)
                    Gosu::draw_rect(point.pixel_x - half_size, point.pixel_y - half_size,
                                    @data_point_size, @data_point_size,
                                    point.color, 2) 
                else 
                    point.pixel_x = nil
                    point.pixel_y = nil
                end
            end

            # Optionally draw the line connecting data points
            if @data.length > 1 and @display_lines
                @data.inject(@data[0]) do |last, the_next|
                    if the_next.pixel_x and the_next.pixel_y and last.pixel_x and last.pixel_y
                        Gosu::draw_line last.pixel_x, last.pixel_y, last.color,
                                the_next.pixel_x, the_next.pixel_y, last.color, 2
                        the_next
                    end
                end
            end

            if @display_grid 
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
                    Gosu::draw_line dx, dy, color, last_x, dy, color, 12
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
                    Gosu::draw_line dx, dy, color, dx, last_y, color, 12
                    grid_x = grid_x + 1
                end
            end
        end

        def draw_cursor_lines(width, height, mouse_x, mouse_y)
            Gosu::draw_line mouse_x, y_pixel_to_screen(0), @cursor_line_color, mouse_x, y_pixel_to_screen(399), @cursor_line_color
            Gosu::draw_line x_pixel_to_screen(201), mouse_y, @cursor_line_color, x_pixel_to_screen(799), mouse_y, @cursor_line_color
            
            graph_x = mouse_x - @start_x - @margin_size
            graph_y = mouse_y - @start_y
            x_pct = (graph_width - graph_x).to_f / graph_width.to_f
            x_val = @right_x - (x_pct * @x_range)
            y_pct = graph_y.to_f / graph_height.to_f
            y_val = @top_y - (y_pct * @y_range)

            @font.draw_text("#{x_val.round(2).to_s}, #{y_val.round(2).to_s}", x_pixel_to_screen(10), height - 32, 1, 1, 1, Gosu::Color::WHITE) 
            @font.draw_text("#{mouse_x}, #{mouse_y}", x_pixel_to_screen(400), height - 32, 1, 1, 1, Gosu::Color::WHITE) 
        end 

        def button_down id, mouse_x, mouse_y
            if id == Gosu::KbG 
                @display_grid = !@display_grid
            elsif id == Gosu::KbL
                @display_lines = !@display_lines
            elsif id == Gosu::KbF
                @data_point_size = @data_point_size + 2
            elsif id == Gosu::KbD
                if @data_point_size > 2
                    @data_point_size = @data_point_size - 2
                end
            elsif id == Gosu::KbUp
                calculate_axis_labels(false, @left_x, @right_x, @bottom_y + 1, @top_y + 1)
            elsif id == Gosu::KbDown
                calculate_axis_labels(false, @left_x, @right_x, @bottom_y - 1, @top_y - 1)
            elsif id == Gosu::KbRight
                calculate_axis_labels(false, @left_x + 1, @right_x + 1, @bottom_y, @top_y)
            elsif id == Gosu::KbLeft
                calculate_axis_labels(false, @left_x - 1, @right_x - 1, @bottom_y, @top_y)
            end
        end
    end  
end
