require 'gosu'
require 'date'
require_relative 'widgets'
require_relative 'textinput'

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
        attr_accessor :is_time_based

        def initialize(l, r, b, t, is_time_based = false)
            @left_x = l 
            @right_x = r 
            @bottom_y = b 
            @top_y = t 
            @x_range = @right_x - @left_x
            @y_range = @top_y - @bottom_y
            @is_time_based = is_time_based

            @orig_left_x = @left_x
            @orig_right_x = @right_x
            @orig_bottom_y = @bottom_y
            @orig_top_y = @top_y
            @orig_range_x = @x_range
            @orig_range_y = @y_range
        end

        def plus(other_range)
            l = @left_x < other_range.left_x ? @left_x : other_range.left_x
            r = @right_x > other_range.right_x ? @right_x : other_range.right_x
            b = @bottom_y < other_range.bottom_y ? @bottom_y : other_range.bottom_y
            t = @top_y > other_range.top_y ? @top_y : other_range.top_y
            Range.new(l, r, b, t, (@is_time_based or other_range.is_time_based))
        end

        def x_ten_percent 
            @x_range.to_f / 10
        end 

        def y_ten_percent 
            @y_range.to_f / 10
        end 

        def scale(zoom_level)
            x_mid_point = @orig_left_x + (@orig_range_x.to_f / 2)
            x_extension = (@orig_range_x.to_f * zoom_level) / 2
            @left_x = x_mid_point - x_extension
            @right_x = x_mid_point + x_extension

            y_mid_point = @orig_bottom_y + (@orig_range_y.to_f / 2)
            y_extension = (@orig_range_y.to_f * zoom_level) / 2
            @bottom_y = y_mid_point - y_extension
            @top_y = y_mid_point + y_extension

            @x_range = @right_x - @left_x
            @y_range = @top_y - @bottom_y
        end 

        def scroll_up 
            @bottom_y = @bottom_y + x_ten_percent
            @top_y = @top_y + x_ten_percent
            @y_range = @top_y - @bottom_y
        end

        def scroll_down
            @bottom_y = @bottom_y - x_ten_percent
            @top_y = @top_y - x_ten_percent
            @y_range = @top_y - @bottom_y
        end

        def scroll_right
            @left_x = @left_x + x_ten_percent
            @right_x = @right_x + x_ten_percent
            @x_range = @right_x - @left_x
        end

        def scroll_left
            @left_x = @left_x - x_ten_percent
            @right_x = @right_x - x_ten_percent
            @x_range = @right_x - @left_x
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

        def calculate_range(zero_based = false)
            if zero_based
                left_x = 0.to_f
                right_x = 1.to_f
                bottom_y = 0.to_f
                top_y = 1.to_f
            else 
                left_x = nil
                right_x = nil
                bottom_y = nil
                top_y = nil
            end

            @data_points.each do |point|
                if left_x.nil?
                    left_x = point.x.floor 
                end 
                if right_x.nil? 
                    right_x = point.x.ceil
                end 
                if point.x < left_x 
                    left_x = point.x.floor 
                elsif point.x > right_x 
                    right_x = point.x.ceil
                end 

                if bottom_y.nil? 
                    bottom_y = point.y.floor 
                end 
                if top_y.nil? 
                    top_y = point.y.ceil
                end
                if point.y < bottom_y 
                    bottom_y = point.y.floor 
                elsif point.y > top_y 
                    top_y = point.y.ceil
                end 
            end 

            x_range = right_x - left_x
            y_range = top_y - bottom_y 

            extension = 0
            if x_range == 0
                if left_x == 0
                    extension = 1
                else
                    if @is_time_based
                        extension = 3600
                    else
                        extension = left_x * 0.1
                    end
                end
            else 
                if @is_time_based
                    if x_range < 86400 
                        extension = 60
                    else 
                        extension = 500
                    end
                else
                    extension = left_x * 0.1
                end
            end
            left_x = left_x - extension
            right_x = right_x + extension

            extension = 0
            if y_range == 0
                if bottom_y == 0
                    extension = 1
                else
                    extension = bottom_y * 0.01
                end
            else 
                extension = bottom_y * 0.1
            end
            bottom_y = bottom_y - extension
            top_y = top_y + extension

            @range = Range.new(left_x, right_x, bottom_y, top_y, @is_time_based)
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

        def initialize(window, width, height, start_x = 0, start_y = 0)
            @window = window
            
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
            @metadata = Table.new(x_pixel_to_screen(@margin_size), y_pixel_to_screen(graph_height + 64),
                                  graph_width, 100, Gosu::Color::GRAY)
            @textinput = TextField.new(@window, @font,
                           x_pixel_to_screen(10), y_pixel_to_screen(graph_height + 64))
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
        # n - name (TODO ability to hardcode the name)
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
                    puts "Adding time point: #{date_time}    #{date_time.to_i}, #{y.to_f}"
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
            set_range_as_superset
            calculate_axis_labels
            apply_visible_range
        end 

        def add_data_set(name, data, color = Gosu::Color::GREEN) 
            @data_set_hash[name] = DataSet.new(name, data, color) 
            set_range_as_superset 
            calculate_axis_labels
            apply_visible_range
        end

        def update_plot_data_sets 
            @metadata.clear_rows
            i = 1
            @data_set_hash.values.each do |data_set|
                @plot.add_data_set(data_set)
                @metadata.add_row([i.to_s, data_set.name], data_set.color)
                i = i + 1
            end
        end

        def widget_width 
            @window_width
        end 

        def widget_height
            @window_height
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

        def set_range_as_superset 
            wip_range = @data_set_hash.values.first.range 
            @data_set_hash.values.each do |ds|
                wip_range = wip_range.plus(ds.range)
            end
            @range = wip_range
        end 

        def apply_visible_range
            @plot.define_range(@range) 
            update_plot_data_sets 
        end

        def calculate_axis_labels
            # TODO based on graph width and height, determine how many labels to show
            @x_axis_labels = []
            if @range.is_time_based
                time_values = []
                time_values << Time.at(@range.left_x)
                time_values << Time.at(@range.left_x + (@range.x_range * 0.25))
                time_values << Time.at(@range.left_x + (@range.x_range * 0.5))
                time_values << Time.at(@range.left_x + (@range.x_range * 0.75))
                time_values << Time.at(@range.right_x)
                date_format_str = "%Y-%m-%d %H:%M:%S"
                # 3600 min, 86400 day
                if @range.x_range < 86400
                    date_format_str = "%H:%M:%S"
                else 
                    date_format_str = "%Y-%m-%d"
                end
                time_values.each do |t|
                    @x_axis_labels << t.strftime(date_format_str)
                end
            else 
                @x_axis_labels << @range.left_x.round(2)
                @x_axis_labels << (@range.left_x + (@range.x_range * 0.25)).round(2)
                @x_axis_labels << (@range.left_x + (@range.x_range * 0.5)).round(2)
                @x_axis_labels << (@range.left_x + (@range.x_range * 0.75)).round(2)
                @x_axis_labels << @range.right_x.round(2)
            end
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
        end 

        def render(width, height, update_count)
            @axis_lines.draw 
            @axis_labels.each do |label|
                label.draw 
            end
            @plot.draw
            @metadata.draw
            @textinput.draw
        end

        def draw_cursor_lines(mouse_x, mouse_y)
            x_val, y_val = @plot.draw_cursor_lines(mouse_x, mouse_y)

            @font.draw_text("#{x_val.round(2).to_s}, #{y_val.round(2).to_s}", x_pixel_to_screen(10), y_pixel_to_screen(widget_height) - 32, 1, 1, 1, Gosu::Color::WHITE) 
            @font.draw_text("#{mouse_x}, #{mouse_y}", x_pixel_to_screen(400), y_pixel_to_screen(widget_height) - 32, 1, 1, 1, Gosu::Color::WHITE) 
        end 

        def button_down id, mouse_x, mouse_y
            if id == Gosu::MsLeft
                # Mouse click: Select text field based on mouse position.
                @window.text_input = [@textinput].find { |tf| tf.under_point?(mouse_x, mouse_y) }
                # Advanced: Move caret to clicked position
                @window.text_input.move_caret(mouse_x) unless @window.text_input.nil?
            end
            if @window.text_input.nil?
                if id == Gosu::KbA 
                    puts "Going to add function: #{@textinput.text}"
                elsif id == Gosu::KbG 
                    @plot.display_grid = !@plot.display_grid
                elsif id == Gosu::KbL
                    @plot.display_lines = !@plot.display_lines
                elsif id == Gosu::KbF
                    @plot.increase_data_point_size
                elsif id == Gosu::KbD
                    @plot.decrease_data_point_size
                elsif id == Gosu::KB_COMMA
                    @plot.zoom_in
                    calculate_axis_labels
                    update_plot_data_sets  
                elsif id == Gosu::KB_PERIOD
                    @plot.zoom_out
                    calculate_axis_labels
                    update_plot_data_sets  
                elsif id == Gosu::KbUp
                    @plot.scroll_up
                    calculate_axis_labels
                    update_plot_data_sets  
                elsif id == Gosu::KbDown
                    @plot.scroll_down
                    calculate_axis_labels
                    update_plot_data_sets  
                elsif id == Gosu::KbRight
                    @plot.scroll_right
                    calculate_axis_labels
                    update_plot_data_sets  
                elsif id == Gosu::KbLeft
                    @plot.scroll_left
                    calculate_axis_labels
                    update_plot_data_sets  
                end
            end
        end
    end  
end
