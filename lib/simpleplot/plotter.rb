require 'gosu'
require 'date'
require_relative 'widgets'

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

    class DataPoint 
        attr_accessor :x
        attr_accessor :y 

        def initialize(x, y) 
            @x = x 
            @y = y 
        end
    end 

    class SimplePlot
        attr_accessor :widget_width
        attr_accessor :widget_height
        attr_accessor :axis_labels_color
        attr_accessor :zero_line_color
        attr_accessor :cursor_line_color
        attr_accessor :data_point_size 
        attr_accessor :widgets

        def initialize(width, height, start_x = 0, start_y = 0)
            ########################################
            # top left origin of widget on screen  #
            ########################################
            @start_x = start_x
            @start_y = start_y

            # The data is a number of named data sets
            @data_hash = {}
            @color_hash = {}
            # TODO populate this in update and the just iterate through in draw
            @widgets = []

            @axis_labels_color = Gosu::Color::CYAN
            @zero_line_color = Gosu::Color::BLUE
            @cursor_line_color = Gosu::Color::GREEN
            @data_point_size = 4
            @font = Gosu::Font.new(32)
            @display_grid = true
            @display_lines = false
            @margin_size = 200
            @window_width = width 
            @window_height = height

            @plot = Plot.new(x_pixel_to_screen(@margin_size), y_pixel_to_screen(0),
                             graph_width, graph_height) 
            @axis_lines = AxisLines.new(x_pixel_to_screen(@margin_size), y_pixel_to_screen(0), graph_width, graph_height, @axis_labels_color)
            @axis_labels = []
        end

        def add_data(name, data, color = Gosu::Color::GREEN) 
            @color_hash[name] = color
            @data_hash[name] = data 
            calculate_axis_labels(true)

            @data_hash.keys.each do |key|
                data = @data_hash[key]
                color = @color_hash[key]
                @plot.add_data(key, data, color)
            end
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

        def x_pixel_to_screen(x)
            @start_x + x
        end

        def y_pixel_to_screen(y)
            @start_y + y
        end

        def calculate_axis_labels(adjust_for_data = true, left_x = 0, right_x = 1, bottom_y = 0, top_y = 1)
            @left_x = left_x.to_f
            @right_x = right_x.to_f
            @bottom_y = bottom_y.to_f
            @top_y = top_y.to_f

            if adjust_for_data
                @data_hash.keys.each do |key|
                    data = @data_hash[key]
                    data.each do |point|
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

            @axis_labels = []
            y = 0
            @y_axis_labels.each do |label|
                @axis_labels << VerticalAxisLabel.new(x_pixel_to_screen(@margin_size),
                                                      y_pixel_to_screen(y),
                                                      label, @font, @axis_labels_color) 
                y = y + 100
            end

            x = @margin_size
            @x_axis_labels.each do |label|
                @axis_labels <<  HorizontalAxisLabel.new(x_pixel_to_screen(x),
                                                         y_pixel_to_screen(graph_height),
                                                         label, @font, @axis_labels_color)
                x = x + 150
            end

            @plot.set_range(@left_x, @right_x, @bottom_y, @top_y) 
        end 

        def render(width, height, update_count)
            @axis_lines.draw 
            @axis_labels.each do |label|
                label.draw 
            end
            @plot.draw
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
                @plot.display_grid = !@plot.display_grid
            elsif id == Gosu::KbL
                @plot.display_lines = !@plot.display_lines
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
