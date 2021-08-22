require 'gosu'
require 'date'
require_relative 'widgets'
require_relative 'textinput'

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

    # GUI Modes
    MODE_PLOT = "Plot"
    MODE_HELP = "Help"
    MODE_DEFINE_FUNCTION = "Function"
    MODE_OPEN_FILE = "Open"
    MODE_ZOOM_BOX = "Zoom"

    COLOR_PEACH = Gosu::Color.argb(0xffe6b0aa)
    COLOR_LIGHT_PURPLE = Gosu::Color.argb(0xffd7bde2)
    COLOR_LIGHT_BLUE = Gosu::Color.argb(0xffa9cce3)
    COLOR_LIGHT_GREEN = Gosu::Color.argb(0xffa3e4d7)
    COLOR_LIGHT_YELLOW = Gosu::Color.argb(0xfff9e79f)
    COLOR_LIGHT_ORANGE = Gosu::Color.argb(0xffedbb99)
    COLOR_WHITE = Gosu::Color::WHITE
    COLOR_OFF_WHITE = Gosu::Color.argb(0xfff8f9f9)
    COLOR_PINK = Gosu::Color.argb(0xffe6b0aa)
    COLOR_LIME = Gosu::Color.argb(0xffDAF7A6)
    COLOR_YELLOW = Gosu::Color.argb(0xffFFC300)
    COLOR_MAROON = Gosu::Color.argb(0xffC70039)
    COLOR_GRAY = Gosu::Color::GRAY
    COLOR_OFF_GRAY = Gosu::Color.argb(0xffa2b3b9)
    COLOR_LIGHT_BLACK = Gosu::Color.argb(0xff111111)
    COLOR_LIGHT_RED = Gosu::Color.argb(0xffe6b0aa)
    COLOR_CYAN = Gosu::Color::CYAN
    COLOR_BLUE = Gosu::Color::BLUE
    COLOR_DARK_GRAY = Gosu::Color.argb(0xccf0f3f4)
    COLOR_RED = Gosu::Color::RED
    COLOR_BLACK = Gosu::Color::BLACK
    COLOR_FORM_BUTTON = Gosu::Color.argb(0xcc2e4053)

    DEFAULT_COLORS = [
        COLOR_PEACH,
        COLOR_LIGHT_PURPLE,
        COLOR_LIGHT_BLUE,
        COLOR_LIGHT_GREEN,
        COLOR_LIGHT_YELLOW,
        COLOR_LIGHT_ORANGE,
        COLOR_PINK,
        COLOR_LIME,
        COLOR_MAROON,
        COLOR_YELLOW,
        COLOR_WHITE,
        COLOR_GRAY,
        COLOR_LIGHT_RED
    ]

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
            if l < r
                @left_x = l 
                @right_x = r 
            else 
                @left_x = r 
                @right_x = l 
            end
            if b < t
                @bottom_y = b 
                @top_y = t 
            else 
                @bottom_y = t  
                @top_y = b 
            end
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
        attr_accessor :data_point_size
        attr_accessor :source_filename

        def initialize(name, data_points, color, is_time_based = false, data_point_size = 4) 
            @name = name 
            @color = color
            @data_points = data_points
            @is_time_based = is_time_based
            @data_point_size = data_point_size
            clear_rendered_points
            if data_points
                calculate_range
            end
        end

        def source_display 
            if @source_filename.nil?
                return "Unknown source"
            end 
            if @source_filename.start_with? "./data/"
                return @source_filename[7..-1]
            end
            @source_filename
        end 

        def derive_values(visible_range)
            # Base implementation is empty
            # Explicit data sets do not need to derive data
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

        def increase_size 
            @data_point_size = @data_point_size + 2
        end 

        def decrease_size 
            if @data_point_size > 2
                @data_point_size = @data_point_size - 2
            end
        end
    end 

    class DerivedDataSet < DataSet 
        attr_accessor :function_str 

        def initialize(name, rhs, range, color)
            super(name, nil, color)
            @data_points = []
            @function_str = rhs 
            @range = range
        end 

        def source_display 
            @function_str
        end 

        def derive_values(visible_range)
            @data_points = []
            x = visible_range.left_x
            while x < visible_range.right_x 
                y = eval(@function_str)
                #puts "#{y} = [#{x}] #{@function_str}"
                @data_points << DataPoint.new(x, y)
                x = x + 0.1    # TODO this should be based on range size
            end
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

    class DefineFunctionForm < Dialog 
        def initialize(window, font, x, y, width, height, data_set_names) 
            super(window, font, x, y, width, height, "Define a Custom Function to Plot", "y = x + 1")
            @data_set_names = data_set_names
        end

        def content 
            <<~HEREDOC
            The expression must be a valid Ruby assignment statement.
            The data set will be given the name on the left-hand side.
            Every expression must include the variable x. You define the y-axis value.
                data_set_name = math_expression_that_includes_x

            Examples:
                line = x + 1
                sin = Math.sin(x)

            HEREDOC
        end

        def handle_ok
            x = 1
            # TODO Add other data sets in the context for evaluation
            begin 
                y = eval(@textinput.text)
                # TODO it still might not contain the x variable
                #      which we need to have a plot
            rescue => e
                parts = e.to_s.partition("SimplePlot")
                add_error_message(parts[0][0..-8])
                return WidgetResult.new(false)
            end
            return WidgetResult.new(true, "ok", @textinput.text) 
        end
    end

    class OpenDataFileForm < Dialog 
        attr_accessor :selected_filename

        def initialize(window, font, x, y, width, height) 
            super(window, font, x, y, width, height, "Select a file from the data subdirectory", "n,x,y") 

            @file_table = SingleSelectTable.new(x + 370, y + 60, 400, 150, ["Filename"], @font, COLOR_CYAN, 4)
            files = Dir["./data/*"]
            files.each do |f|
                @file_table.add_row([f.to_s], COLOR_WHITE) 
            end
            add_child(@file_table) 

            @preview = Table.new(x + 5, y + 216, @width - 15, 90,
                                ["Data Preview"], @font, COLOR_CYAN, 3)
            add_child(@preview)
        end

        def content 
            <<~HEREDOC
            Enter the format of lines in the file.
            t - time
            n - name of data set
            x - x value
            y - y value
            HEREDOC
        end

        def handle_ok
            return WidgetResult.new(true, "ok", [@selected_filename, @textinput.text]) 
        end 

        def handle_up(mouse_x, mouse_y)
            @file_table.scroll_up
        end

        def handle_down(mouse_x, mouse_y)
            @file_table.scroll_down
        end

        def handle_mouse_click(mouse_x, mouse_y)
            if @file_table.contains_click(mouse_x, mouse_y)
                val = @file_table.set_selected_row(mouse_y, 0)
                if val.nil?
                    # nothing to do
                else 
                    @selected_filename = val
                    # Try to read this file and get preview content
                    if File.exist?(@selected_filename)
                        @preview.clear_rows
                        @preview.headers = @textinput.text.split(",")
                        File.readlines(@selected_filename).each do |line|
                            if @preview.number_of_rows < 2
                                @preview.add_row(line.split(","), COLOR_CYAN)
                            end 
                        end 
                    end
                end 
            end
        end

        def text_input_updated(text)
            @preview.headers = @textinput.text.split(",")
        end

        def render 
            super
            @preview.draw_border
            if @preview_content
                y = @preview.y + 40
                @preview_content.each do |line|
                    @font.draw_text(line, @preview.x + 7, y, 10, 1, 1, COLOR_WHITE)
                    y = y + 26
                end
            end
        end
    end

    class SimplePlot
        attr_accessor :widget_width
        attr_accessor :widget_height
        attr_accessor :axis_labels_color
        attr_accessor :data_point_size 
        attr_accessor :widgets
        attr_accessor :range_stack
        attr_accessor :gui_mode
        attr_accessor :overlay_widget
        attr_accessor :display_metadata

        def initialize(window, width, height, start_x = 0, start_y = 0)
            @window = window
            @gui_mode = MODE_PLOT
            @display_metadata = true
            ########################################
            # top left origin of widget on screen  #
            ########################################
            @start_x = start_x
            @start_y = start_y

            @data_set_hash = {}
            @range_stack = []

            @axis_labels_color = COLOR_CYAN
            @data_point_size = 4
            @font = Gosu::Font.new(32)
            @small_font = Gosu::Font.new(24)
            @display_grid = true
            @display_lines = false
            @margin_size = 200
            @window_width = width 
            @window_height = height

            @plot = Plot.new(x_pixel_to_screen(@margin_size), y_pixel_to_screen(0),
                             graph_width, graph_height, @font) 
            @axis_lines = AxisLines.new(x_pixel_to_screen(@margin_size), y_pixel_to_screen(0),
                                        graph_width, graph_height + 1, @axis_labels_color)
            @axis_labels = []
            @metadata = Table.new(x_pixel_to_screen(@margin_size), y_pixel_to_screen(graph_height + 64),
                                  graph_width - 200, 120,
                                  ["#", "Name", "Source"],
                                  @small_font, COLOR_GRAY, 3)
            @no_data_message_1 = Text.new('Click "Define Function"',
                                        x_pixel_to_screen(@margin_size + 32), y_pixel_to_screen(graph_height + 84),
                                        @small_font, COLOR_CYAN) 
            @no_data_message_2 = Text.new('or "Open Data File" to plot data',
                                        x_pixel_to_screen(@margin_size + 32), y_pixel_to_screen(graph_height + 108),
                                        @small_font, COLOR_CYAN) 
            @function_button = Button.new("Define Function",
                                          x_pixel_to_screen(10),
                                          y_pixel_to_screen(graph_height + 64),
                                          @small_font,
                                          180)
            @open_file_button = Button.new("Open Data File",
                                          x_pixel_to_screen(10),
                                          y_pixel_to_screen(graph_height + 94),
                                          @small_font,
                                          180)
            @help_button = Button.new("Help",
                                       x_pixel_to_screen(10),
                                       y_pixel_to_screen(graph_height + 124),
                                       @small_font,
                                       180)
            @quit_button = Button.new("Quit",
                                       x_pixel_to_screen(10),
                                       y_pixel_to_screen(graph_height + 154),
                                       @small_font,
                                       180)
            @cursor_readout = Widget.new(x_pixel_to_screen(@margin_size + graph_width - 190),
                                         y_pixel_to_screen(graph_height + 64),
                                         COLOR_GRAY)
            @cursor_readout.width = 270
            @cursor_readout.height = 120
        end

        def help_content
            <<~HEREDOC
              You can plot multiple data sets at once, using data from files
              or you can define your own function(s) to plot.

              Key Commands:
                arrow keys      scroll up, down, left, right
                <, >            zoom in or out
                d               define a custom function to plot
                a               decrease data point size
                s               increase data point size
                g               toggle grid lines
                l               toggle lines connecting points
                q               quit the program
            HEREDOC
        end
        
        def current_range 
            @range_stack.last
        end 

        def set_range_and_update_display(range = nil)
            # Maintain a stack of ranges so we can support undo zoom
            @range_stack.push(range) unless range.nil?
            calculate_axis_labels
            @plot.define_range(current_range)
            update_plot_data_sets
        end

        def undo_zoom 
            if @range_stack.size > 1
                @range_stack.pop 
                set_range_and_update_display
            end 
        end

        def clear_button 
            @function_button.is_pressed = false 
            @window.text_input = nil
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
                    c = DEFAULT_COLORS[new_data_sets.size]
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
                    data_set.source_filename = filename
                    new_data_sets[n] = data_set 
                end 
                
                if data_set.is_time_based
                    # %Y-%m-%dT%H:%M:%S
                    date_time = DateTime.parse(t).to_time
                    #puts "Adding time point: #{date_time}    #{date_time.to_i}, #{y.to_f}"
                    data_set.add_data_point(DataPoint.new(date_time.to_i, y.to_f))
                else
                    #puts "Adding data point: #{x.to_f}, #{y.to_f}"
                    data_set.add_data_point(DataPoint.new(x.to_f, y.to_f))
                end
            end

            new_data_sets.keys.each do |key|
                data_set = new_data_sets[key]
                data_set.calculate_range
                @data_set_hash[key] = data_set
            end
            set_range_and_update_display(determine_superset_range)
        end 

        def add_data_set(name, data, color = COLOR_LIGHT_PURPLE) 
            @data_set_hash[name] = DataSet.new(name, data, color) 
            @data_set_hash[name].source_filename = "Predefined"
            set_range_and_update_display(determine_superset_range)
        end

        def add_derived_data_set(function_str, color = nil) 
            parts = function_str.partition("=")
            name = parts[0]
            rhs = parts[2]
            if color == nil 
                color = DEFAULT_COLORS[@data_set_hash.size]
            end
            @data_set_hash[name] = DerivedDataSet.new(name, rhs, @plot.visible_range, color) 
            set_range_and_update_display(determine_superset_range)
        end

        def update_plot_data_sets 
            @metadata.clear_rows
            i = 1
            @data_set_hash.values.each do |data_set|
                @plot.add_data_set(data_set)
                @metadata.add_row([i.to_s, data_set.name, data_set.source_display], data_set.color)
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

        def determine_superset_range
            wip_range = @data_set_hash.values.first.range 
            @data_set_hash.values.each do |ds|
                wip_range = wip_range.plus(ds.range)
            end
            wip_range
        end 

        def calculate_axis_labels
            # TODO based on graph width and height, determine how many labels to show
            @x_axis_labels = []
            if current_range.is_time_based
                time_values = []
                time_values << Time.at(current_range.left_x)
                time_values << Time.at(current_range.left_x + (current_range.x_range * 0.25))
                time_values << Time.at(current_range.left_x + (current_range.x_range * 0.5))
                time_values << Time.at(current_range.left_x + (current_range.x_range * 0.75))
                time_values << Time.at(current_range.right_x)
                date_format_str = "%Y-%m-%d %H:%M:%S"
                # 3600 min, 86400 day
                if current_range.x_range < 86400
                    date_format_str = "%H:%M:%S"
                else 
                    date_format_str = "%Y-%m-%d"
                end
                time_values.each do |t|
                    @x_axis_labels << t.strftime(date_format_str)
                end
            else 
                @x_axis_labels << current_range.left_x.round(2)
                @x_axis_labels << (current_range.left_x + (current_range.x_range * 0.25)).round(2)
                @x_axis_labels << (current_range.left_x + (current_range.x_range * 0.5)).round(2)
                @x_axis_labels << (current_range.left_x + (current_range.x_range * 0.75)).round(2)
                @x_axis_labels << current_range.right_x.round(2)
            end
            @y_axis_labels = []
            @y_axis_labels << current_range.top_y.round(2)
            @y_axis_labels << (current_range.top_y - (current_range.y_range * 0.25)).round(2)
            @y_axis_labels << (current_range.top_y - (current_range.y_range * 0.5)).round(2)
            @y_axis_labels << (current_range.top_y - (current_range.y_range * 0.75)).round(2)
            @y_axis_labels << current_range.bottom_y.round(2)

            @axis_labels = []
            y = 0
            @y_axis_labels.each do |label|
                @axis_labels << VerticalAxisLabel.new(x_pixel_to_screen(@margin_size),
                                                      y_pixel_to_screen(y),
                                                      label, @small_font, @axis_labels_color) 
                y = y + 100
            end

            x = @margin_size
            @x_axis_labels.each do |label|
                @axis_labels <<  HorizontalAxisLabel.new(x_pixel_to_screen(x),
                                                         y_pixel_to_screen(graph_height),
                                                         label, @small_font, @axis_labels_color)
                x = x + 150
            end
        end 

        def render(mouse_x, mouse_y, update_count)
            @axis_lines.draw 
            @axis_labels.each do |label|
                label.draw 
            end
            @plot.draw
            if @gui_mode == MODE_ZOOM_BOX
                Gosu::draw_line @click_x, @click_y, COLOR_GRAY, mouse_x, @click_y, COLOR_GRAY, 12
                Gosu::draw_line @click_x, @click_y, COLOR_GRAY, @click_x, mouse_y, COLOR_GRAY, 12
                Gosu::draw_line @click_x, mouse_y, COLOR_GRAY, mouse_x, mouse_y, COLOR_GRAY, 12
                Gosu::draw_line mouse_x, @click_y, COLOR_GRAY, mouse_x, mouse_y, COLOR_GRAY, 12
            else
                draw_cursor_lines(mouse_x, mouse_y)
            end

            if @display_metadata
                @metadata.draw
                if @data_set_hash.empty?
                    @no_data_message_1.draw
                    @no_data_message_2.draw
                end
                @function_button.draw 
                @open_file_button.draw
                @help_button.draw 
                @quit_button.draw 
                if @overlay_widget
                    @overlay_widget.draw 
                end
                @cursor_readout.draw_border
                @small_font.draw_text("Cursor", @cursor_readout.x + 4, @cursor_readout.y, 1, 1, 1, COLOR_GRAY)
            end
        end

        def is_cursor_on_graph(mouse_x, mouse_y)
            mouse_x > x_pixel_to_screen(@margin_size) - 1 and mouse_x < x_pixel_to_screen(@margin_size) + graph_width and mouse_y > y_pixel_to_screen(0) and mouse_y < y_pixel_to_screen(0) + graph_height 
        end 
        
        def draw_cursor_lines(mouse_x, mouse_y)
            if is_cursor_on_graph(mouse_x, mouse_y) and @overlay_widget.nil?
                x_val, y_val = @plot.draw_cursor_lines(mouse_x, mouse_y)
                if @display_metadata
                    if current_range.is_time_based
                        x_str = Time.at(x_val).to_s
                    else
                        x_str = "x: #{x_val.round(2).to_s}"
                    end
                    @small_font.draw_text(x_str,
                                        x_pixel_to_screen(@margin_size + graph_width - 186),
                                        y_pixel_to_screen(graph_height + 94), 1, 1, 1, COLOR_GRAY) 
                    @small_font.draw_text("y: #{y_val.round(2).to_s}",
                                        x_pixel_to_screen(@margin_size + graph_width - 186),
                                        y_pixel_to_screen(graph_height + 124), 1, 1, 1, COLOR_GRAY) 
                end
            end
        end 

        def display_help 
            @gui_mode = MODE_HELP
            @overlay_widget = InfoBox.new("Simple Plot Help", help_content,
                                          x_pixel_to_screen(10), y_pixel_to_screen(10), @small_font,
                                          @window_width - 20, graph_height)
        end

        def display_define_function_form 
            @gui_mode = MODE_DEFINE_FUNCTION
            @overlay_widget = DefineFunctionForm.new(@window, @small_font,
                                                     x_pixel_to_screen(10), y_pixel_to_screen(10),
                                                     @window_width - 20, graph_height,
                                                     @data_set_hash.keys)
            @window.text_input = @overlay_widget.textinput
            @window.text_input.move_caret(1)
        end 

        def display_open_file_form 
            @gui_mode = MODE_OPEN_FILE
            @overlay_widget = OpenDataFileForm.new(@window, @small_font,
                                                   x_pixel_to_screen(10), y_pixel_to_screen(10),
                                                   @window_width - 20, graph_height)
            @window.text_input = @overlay_widget.textinput
            @window.text_input.move_caret(1)
        end 

        def button_up id, mouse_x, mouse_y
            if id == Gosu::MsLeft
                if @gui_mode == MODE_ZOOM_BOX
                    @gui_mode = MODE_PLOT
                    left_x = @plot.get_x_data_val(@click_x)
                    right_x = @plot.get_x_data_val(mouse_x)
                    bottom_y = @plot.get_y_data_val(mouse_y)
                    top_y = @plot.get_y_data_val(@click_y)
                    range = Range.new(left_x, right_x, bottom_y, top_y, current_range.is_time_based)
                    set_range_and_update_display(range)
                end
            elsif id == Gosu::MsRight 
                undo_zoom
            end
        end

        def button_down id, mouse_x, mouse_y
            if @overlay_widget
                result = @overlay_widget.button_down id, mouse_x, mouse_y
                if @gui_mode == MODE_DEFINE_FUNCTION
                    if result.action == "ok"
                        clear_button 
                        add_derived_data_set(result.form_data) 
                    end 
                elsif @gui_mode == MODE_OPEN_FILE 
                    if result.action == "ok"
                        clear_button 
                        filename_and_format_array = result.form_data
                        add_file_data(filename_and_format_array[0],
                                      filename_and_format_array[1])
                    end
                end
                if result.close_widget
                    @overlay_widget = nil 
                    @gui_mode = MODE_PLOT
                end
                return 
            end

            if id == Gosu::MsLeft
                if @function_button.contains_click(mouse_x, mouse_y)
                    display_define_function_form
                elsif @open_file_button.contains_click(mouse_x, mouse_y)
                    display_open_file_form 
                elsif @help_button.contains_click(mouse_x, mouse_y)
                    display_help 
                elsif @quit_button.contains_click(mouse_x, mouse_y)
                    return WidgetResult.new(true)
                elsif @gui_mode == MODE_PLOT and is_cursor_on_graph(mouse_x, mouse_y)
                    @click_x = mouse_x
                    @click_y = mouse_y
                    @gui_mode = MODE_ZOOM_BOX
                end
            end
            if @window.text_input.nil?
                if id == Gosu::KbH 
                    display_help
                elsif id == Gosu::KbO 
                    display_open_file_form
                elsif id == Gosu::KbD
                    display_define_function_form
                elsif id == Gosu::KbG 
                    @plot.display_grid = !@plot.display_grid
                elsif id == Gosu::KbL
                    @plot.display_lines = !@plot.display_lines
                elsif id == Gosu::KbS
                    @data_set_hash.values.each do |data_set|
                        data_set.increase_size 
                    end
                    @plot.increase_data_point_size
                elsif id == Gosu::KbA
                    @data_set_hash.values.each do |data_set|
                        data_set.decrease_size 
                    end
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
                    if @metadata.contains_click(mouse_x, mouse_y)
                        @metadata.scroll_up 
                    elsif @gui_mode == MODE_OPEN_FILE
                        @overlay_widget.button_down id, mouse_x, mouse_y
                    else
                        @plot.scroll_up
                        calculate_axis_labels
                        update_plot_data_sets 
                    end 
                elsif id == Gosu::KbDown
                    if @metadata.contains_click(mouse_x, mouse_y)
                        @metadata.scroll_down
                    elsif @gui_mode == MODE_OPEN_FILE
                        @overlay_widget.button_down id, mouse_x, mouse_y
                    else
                        @plot.scroll_down
                        calculate_axis_labels
                        update_plot_data_sets  
                    end 
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
            nil
        end
    end  
end
