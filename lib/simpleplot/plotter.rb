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

    class Range
        attr_accessor :left_x
        attr_accessor :right_x
        attr_accessor :bottom_y
        attr_accessor :top_y
        attr_accessor :x_range
        attr_accessor :y_range

        def initialize(l, r, b, t)
            @left_x = l 
            @right_x = r 
            @bottom_y = b 
            @top_y = t 
            @x_range = @right_x - @left_x
            @y_range = @top_y - @bottom_y
        end
    end

    class DataSet 
        attr_accessor :name
        attr_accessor :color 
        attr_accessor :data_points 
        attr_accessor :is_time_based 
        attr_accessor :range 
        attr_accessor :rendered_points 

        def initialize(name, data_points, color, is_time_based = false) 
            @name = name 
            @color = color
            @data_points = data_points
            @is_time_based = is_time_based
            clear_rendered_points
            if data_points
                calculate_range
            end
        end

        def add_data_point(point)
            if @data_points.nil? 
                @data_points = []
            end 
            @data_points << point
        end

        def clear_rendered_points 
            @rendered_points = [] 
        end

        def add_rendered_point(point)
            @rendered_points << point 
        end

        def update_data(data)
            @data_points = data
            calculate_range
        end 

        def calculate_range
            left_x = 0.to_f
            right_x = 1.to_f
            bottom_y = 0.to_f
            top_y = 1.to_f

            @data_points.each do |point|
                if point.x < left_x 
                    left_x = point.x.floor 
                elsif point.x > right_x 
                    right_x = point.x.ceil
                end 

                if point.y < bottom_y 
                    bottom_y = point.y.floor 
                elsif point.y > top_y 
                    top_y = point.y.ceil
                end 
            end 

            x_range = right_x - left_x
            y_range = top_y - bottom_y 

            @range = Range.new(left_x, right_x, bottom_y, top_y)
        end
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
        attr_accessor :data_point_size 
        attr_accessor :widgets
        attr_accessor :range

        def initialize(width, height, start_x = 0, start_y = 0)
            ########################################
            # top left origin of widget on screen  #
            ########################################
            @start_x = start_x
            @start_y = start_y

            @data_set_hash = {}

            @axis_labels_color = Gosu::Color::CYAN
            @data_point_size = 4
            @font = Gosu::Font.new(32)
            @display_grid = true
            @display_lines = false
            @margin_size = 200
            @window_width = width 
            @window_height = height

            @plot = Plot.new(x_pixel_to_screen(@margin_size), y_pixel_to_screen(0),
                             graph_width, graph_height, @font) 
            @axis_lines = AxisLines.new(x_pixel_to_screen(@margin_size), y_pixel_to_screen(0),
                                        graph_width, graph_height, @axis_labels_color)
            @axis_labels = []
        end

        def translate_format(format_tokens, format_value, values)
            index = format_tokens.index(format_value)
            if index.nil? 
                return nil 
            end 
            values[index]
        end 

        # The format of fields in the csv
        # t - time  (special case of x)
        # x
        # y
        # n - name, or you can hardcode the name
        # 2021-08-12T08:41:16,Portfolio,232070
        #  
        def add_file_data(filename, format_str, color_map = {}) 
            format_tokens = format_str.split(",")
            new_data_sets = {} 
            File.readlines(filename).each do |line|
                line = line.chomp
                tokens = line.split(",")
                t = translate_format(format_tokens, "t", tokens)
                n = translate_format(format_tokens, "n", tokens)
                x = translate_format(format_tokens, "x", tokens)
                y = translate_format(format_tokens, "y", tokens)
                
                if n.nil?
                    n = "FileDataSet"
                end 
                c = color_map[n]
                if c.nil? 
                    c = Gosu::Color::GREEN 
                end

                # Determine what type of x we have (time or value)                
                if t.nil?
                    is_time_based = false
                else
                    is_time_based = true
                end

                data_set = new_data_sets[n]
                # Does the data set exist already? If not create
                if data_set.nil? 
                    puts "Creating data set #{n}. Time based: #{is_time_based}"
                    data_set = DataSet.new(n, nil, c, is_time_based) 
                    new_data_sets[n] = data_set 
                end 
                
                if data_set.is_time_based
                    # %Y-%m-%dT%H:%M:%S
                    date_time = DateTime.parse(t).to_time
                    puts "Adding time point: #{date_time.to_i}, #{y.to_f}"
                    data_set.add_data_point(DataPoint.new(date_time.to_i, y.to_f))
                else
                    puts "Adding data point: #{x.to_f}, #{y.to_f}"
                    data_set.add_data_point(DataPoint.new(x.to_f, y.to_f))
                end
            end

            new_data_sets.keys.each do |key|
                data_set = new_data_sets[key]
                data_set.calculate_range
                @data_set_hash[key] = data_set
            end
            calculate_axis_labels
            update_plot_data_sets  
        end 

        def add_data_set(name, data, color = Gosu::Color::GREEN) 
            @data_set_hash[name] = DataSet.new(name, data, color) 
            calculate_axis_labels
            update_plot_data_sets            
        end

        def update_plot_data_sets 
            @data_set_hash.values.each do |data_set|
                @plot.add_data_set(data_set)
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

        def calculate_axis_labels
            # TODO Be more sophisticated, and use a blend of all the data set ranges
            @range = @data_set_hash.values.first.range 

            # TODO based on graph width and height, determine how many labels to show
            @x_axis_labels = []
            @x_axis_labels << @range.left_x.round(2)
            @x_axis_labels << (@range.left_x + (@range.x_range * 0.25)).round(2)
            @x_axis_labels << (@range.left_x + (@range.x_range * 0.5)).round(2)
            @x_axis_labels << (@range.left_x + (@range.x_range * 0.75)).round(2)
            @x_axis_labels << @range.right_x.round(2)
            @y_axis_labels = []
            @y_axis_labels << @range.top_y.round(2)
            @y_axis_labels << (@range.top_y - (@range.y_range * 0.25)).round(2)
            @y_axis_labels << (@range.top_y - (@range.y_range * 0.5)).round(2)
            @y_axis_labels << (@range.top_y - (@range.y_range * 0.75)).round(2)
            @y_axis_labels << @range.bottom_y.round(2)

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

            @plot.visible_range = @range 
        end 

        def render(width, height, update_count)
            @axis_lines.draw 
            @axis_labels.each do |label|
                label.draw 
            end
            @plot.draw
        end

        def draw_cursor_lines(mouse_x, mouse_y)
            x_val, y_val = @plot.draw_cursor_lines(mouse_x, mouse_y)

            @font.draw_text("#{x_val.round(2).to_s}, #{y_val.round(2).to_s}", x_pixel_to_screen(10), y_pixel_to_screen(widget_height) - 32, 1, 1, 1, Gosu::Color::WHITE) 
            @font.draw_text("#{mouse_x}, #{mouse_y}", x_pixel_to_screen(400), y_pixel_to_screen(widget_height) - 32, 1, 1, 1, Gosu::Color::WHITE) 
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
