require 'gosu'
require 'date'
require 'ripper'
require 'set'
require_relative 'data_sets'
require 'wads'

include Wads 

module SimplePlot

    # GUI Modes
    MODE_PLOT = "Plot"
    MODE_HELP = "Help"
    MODE_DEFINE_FUNCTION = "Function"
    MODE_OPEN_FILE = "Open"
    MODE_ZOOM_BOX = "Zoom"
    MODE_DERIVED_FUNCTION_GRAPH = "Graph"
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

    class DataSet 
        attr_accessor :name
        attr_accessor :color 
        attr_accessor :data_points 
        attr_accessor :is_time_based 
        attr_accessor :range 
        attr_accessor :data_point_size
        attr_accessor :source_filename
        attr_accessor :visible

        def initialize(name, data_points, color, is_time_based = false, data_point_size = 4) 
            @name = name 
            @color = color
            @data_points = data_points
            @is_time_based = is_time_based
            @data_point_size = data_point_size
            @visible = true
            if data_points
                calculate_range
            end
        end

        def toggle_visibility 
            @visible = !@visible
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

        def add_data_point(point)
            if @data_points.nil? 
                @data_points = []
            end 
            @data_points << point
        end

        def get_value_at_x(x, accuracy = 0.01)
            if @data_points.nil?
                return nil 
            end 
            @data_points.each do |dp|
                if dp.x == x 
                    # TODO accuracy
                    return dp.y 
                end 
            end
            nil
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

            @range = VisibleRange.new(left_x, right_x, bottom_y, top_y, @is_time_based)
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
        attr_accessor :referenced_data_sets 

        def initialize(name, rhs, range, color)
            super(name.strip, nil, color)
            @data_points = []
            @function_str = rhs 
            @range = range
            @referenced_data_sets = determine_referenced_data_sets
        end 

        def determine_referenced_data_sets
            begin 
                result = Ripper.sexp(@function_str)   # this returns an array
                #pp result
                idents = find_all_idents(result)
                return idents.to_a
            rescue => e
                puts "Got an exception: #{e}"
            end
            Set.new
        end

        def find_all_idents(parse_tree, ident_set = Set.new)
            if parse_tree.kind_of?(Array)
                if parse_tree.length > 1 and parse_tree[0] == :@ident
                    ident_set.add(parse_tree[1])
                end 
                if parse_tree.length > 1 and parse_tree[0] == :call
                    # Skipp the call subtree so we don't confuse method name idents
                    # with data set names
                else
                    parse_tree.each do |pt|
                        find_all_idents(pt, ident_set)
                    end
                end
            end
            ident_set
        end

        def source_display 
            @function_str
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
            code = ""
            # Verify it is an equation
            if not @textinput.text.include? "="
                add_error_message("The function must include an assignment (=) with a left and right side")
                return WidgetResult.new(false)
            end 

            # Verify we are not redefining an existing data set
            parts = @textinput.text.partition("=")
            lhs = parts[0].strip
            if @data_set_names.include? lhs 
                add_error_message("The data set #{lhs} is already defined.")
                return WidgetResult.new(false)
            end 
            if lhs == "x"
                add_error_message("You cannot redefine the x-axis variable.")
                return WidgetResult.new(false)
            end 

            # Add other data sets in the context for evaluation
            @data_set_names.each do |dsn| 
                code = "#{code}\n#{dsn} = 1"
            end
            code = "#{code}\n#{@textinput.text}"
            begin 
                y = eval(code)
            rescue => e
                parts = e.to_s.partition("SimplePlot")
                add_error_message(parts[0][0..-8])
                return WidgetResult.new(false)
            end
            return WidgetResult.new(true, EVENT_OK, @textinput.text) 
        end

        def render 
            super 
            draw_background(Z_ORDER_BACKGROUND) 
        end

        def handle_key_press id, mouse_x, mouse_y
            if id == Gosu::KbReturn
                #return WidgetResult.new(true, EVENT_OK, @textinput.text)
                return handle_ok
            end
        end
    end

    class OpenDataFileForm < Dialog 
        attr_accessor :selected_filename

        def initialize(window, font, x, y, width, height) 
            super(window, font, x, y, width, height,
                  "Select a file from the data subdirectory", "n,x,y") 

            @file_table = add_single_select_table(370, 60, 400, 150, ["Filename"], COLOR_CYAN, 4)
            files = Dir["./data/*"]
            files.each do |f|
                @file_table.add_row([f.to_s], COLOR_WHITE) 
            end

            @preview = add_table(5, 216, width - 15, 90, ["Data Preview"], COLOR_CYAN, 3)
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
            return WidgetResult.new(true, EVENT_OK, [@selected_filename, @textinput.text]) 
        end 

        def handle_key_press id, mouse_x, mouse_y
            if id == Gosu::KbUp
                @file_table.scroll_up
            elsif id == Gosu::KbDown
                @file_table.scroll_down
            end
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

        def intercept_widget_event(result)
            if result.action == EVENT_TEXT_INPUT
                @preview.headers = result.form_data[0].split(",")
            end
        end

        def render 
            super
            draw_background(Z_ORDER_BACKGROUND)
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

    class DerivedFunctionGraphDisplay < InfoBox
        def initialize(x, y, font, width, height, graph)
            super("Derived Function Dependencies", "This graph below shows dependencies between data sets",
                  x, y, font, width, height)
            @base_z = 10
            set_background(COLOR_BLACK)
            @graph = graph
            @graph_display = add_graph_display(5, 160, 770, 200, @graph)
            @graph_display.set_tree_display
            root_nodes = @graph.root_nodes 
            if root_nodes.empty? or root_nodes.size == 1
                @graph_display.set_center_node(@graph.find_node("x"), 5)
            else 
                @graph_display.set_center_node(root_nodes[1], 5)
            end
        end 

        def render 
            super 
            draw_background(Z_ORDER_BACKGROUND)
        end
    end 

    class SimplePlot < Widget
        attr_accessor :axis_labels_color
        attr_accessor :data_point_size 
        attr_accessor :widgets
        attr_accessor :range_stack
        attr_accessor :gui_mode
        attr_accessor :display_metadata
        attr_accessor :derived_function_graph

        def initialize(window, x, y, width, height, font)
            super(x, y, COLOR_HEADER_BRIGHT_BLUE)
            set_dimensions(width, height)
            set_font(font)
            @window = window
            @gui_mode = MODE_PLOT
            @display_metadata = true

            @data_set_hash = {}
            @derived_function_graph = Graph.new
            @derived_function_graph.add_node(create_graph_node("x"))  # The only implied data set
            @range_stack = []

            @axis_labels_color = COLOR_HEADER_BRIGHT_BLUE
            @data_point_size = 4
            @display_grid = true
            @display_lines = false
            @margin_size = 200

            @plot = add_plot(@margin_size, 0, graph_width, graph_height)
            add_axis_lines(@margin_size, 0, graph_width, graph_height + 1, @axis_labels_color)
            @axis_labels = []
            @metadata = add_multi_select_table(@margin_size, graph_height + 64,
                                  graph_width - 200, 120,
                                  ["#", "Name", "Source"],
                                  COLOR_GRAY, 3)
            @metadata.can_delete_rows = true
            @no_data_message_1 = Text.new('Click "Define Function"',
                                        x_pixel_to_screen(@margin_size + 32), y_pixel_to_screen(graph_height + 84),
                                        @font, COLOR_HEADER_BRIGHT_BLUE) 
            @no_data_message_2 = Text.new('or "Open Data File" to plot data',
                                        x_pixel_to_screen(@margin_size + 32), y_pixel_to_screen(graph_height + 108),
                                        @font, COLOR_HEADER_BRIGHT_BLUE) 
            add_button("Define Function", 10, graph_height + 64, 180) do
                @gui_mode = MODE_DEFINE_FUNCTION
                add_overlay(DefineFunctionForm.new(@window, @font,
                                                   x_pixel_to_screen(10), y_pixel_to_screen(10),
                                                   @width - 20, graph_height,
                                                   @data_set_hash.keys))
                @window.text_input = @overlay_widget.textinput
                @window.text_input.move_caret(1)
            end

            add_button("Open Data File", 10, graph_height + 94, 180) do 
                @gui_mode = MODE_OPEN_FILE
                add_overlay(OpenDataFileForm.new(@window, @font,
                                                 x_pixel_to_screen(10), y_pixel_to_screen(10),
                                                 @width - 20, graph_height))
                @window.text_input = @overlay_widget.textinput
                @window.text_input.move_caret(1)
            end

            add_button("Help", 10, graph_height + 124, 180) do 
                @gui_mode = MODE_HELP
                add_overlay(InfoBox.new("Simple Plot Help", help_content,
                                        x_pixel_to_screen(10), y_pixel_to_screen(10), @font,
                                        @width - 20, graph_height))
            end

            add_button("Quit", 10, graph_height + 154, 180) do
                WidgetResult.new(true)
            end

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
                @derived_function_graph.add_node(create_graph_node(key))
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
            name = parts[0].strip
            rhs = parts[2].strip
            if color == nil 
                color = DEFAULT_COLORS[@data_set_hash.size]
            end
            @data_set_hash[name] = DerivedDataSet.new(name, rhs, @plot.visible_range, color) 
            # Update the derived function graph
            # The dependent data sets should already exist
            # Here we are adding the new data set name (lhs) and edges to the referenced data sets
            lhs_node = create_graph_node(name)
            @derived_function_graph.add_node(lhs_node)
            @data_set_hash[name].referenced_data_sets.each do |ref_data_set_name|
                #puts "Adding an edge from #{name} to #{ref_data_set_name}"
                referenced_node = @derived_function_graph.find_node(ref_data_set_name)
                if referenced_node.nil?
                    puts "ERROR: Cannot find referenced data set #{ref_data_set_name} in dependency graph"
                else 
                    lhs_node.add_output_node(referenced_node)
                end 
            end
            set_range_and_update_display(determine_superset_range)
        end

        def create_graph_node(name)
            tags = {}
            tags["color"] = COLOR_WHITE
            Node.new(name, "", tags)
        end

        def update_plot_data_sets 
            @metadata.clear_rows
            i = 1

            # Do all the regular data sets first
            regular_data_sets = []
            derived_data_sets = []
            @data_set_hash.values.each do |data_set|
                if data_set.is_a? DerivedDataSet 
                    derived_data_sets << data_set 
                else 
                    regular_data_sets << data_set
                end 
            end

            hh = HashOfHashes.new

            regular_data_sets.each do |data_set|
                data_set.data_points.each do |dp|
                    hh.set(data_set.name, dp.x, dp.y)
                end
                # TODO This will end up changing the order of data sets in the table
                # because we are using a different order here than what the user entered
                add_data_set_to_plot(data_set.data_points, data_set, i)
                i = i + 1
            end

            order_of_calculation = GraphReverseIterator.new(@derived_function_graph).output

            order_of_calculation.each do |node|
                if node.id == "x"
                    # skip, x is implied
                elsif regular_data_sets.select {|ds| ds.name == node.id }.size == 1
                    # regular datasets do not need to be derived
                else
                    data_set = @data_set_hash[node.id]
                    if data_set.nil?
                        puts "ERROR did not find data set #{node.id}"
                        exit 
                    end
                    #puts "Calculating derived data set #{data_set.name}"
                    calc = DerivedFunctionCalculator.new(data_set)
                    the_data_points = calc.derive_values(data_set.name,
                                                        data_set.determine_referenced_data_sets,
                                                        @plot.visible_range,
                                                        hh)
                    add_data_set_to_plot(the_data_points, data_set, i)
                    i = i + 1
                end
            end
        end

        def add_data_set_to_plot(the_data_points, data_set, i)
            rendered_points = []
            the_data_points.each do |point|
                pp = PlotPoint.new(@plot.draw_x(point.x),
                                    @plot.draw_y(point.y),
                                    point.x,
                                    point.y,
                                    data_set.color,
                                    data_set.data_point_size)
                if @plot.is_on_screen(pp)
                    rendered_points << pp
                end
            end
            @plot.add_data_set(data_set.name, rendered_points)
            @metadata.add_row([i.to_s, data_set.name, data_set.source_display], data_set.color)
        end

        def graph_width 
            @width - @margin_size
        end 
        
        def graph_height 
            @height - @margin_size
        end

        def x_pixel_to_screen(x)
            @x + x
        end

        def y_pixel_to_screen(y)
            @y + y
        end

        def determine_superset_range
            wip_range = @data_set_hash.values.first.range 
            @data_set_hash.values.each do |ds|
                wip_range = wip_range.plus(ds.range)
            end
            wip_range
        end 

        def calculate_axis_labels
            @x_axis_labels = []
            current_range.clear_cache
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

        def render
            @axis_labels.each do |label|
                label.draw 
            end
            draw_cursor_lines
            draw_zoom_box

            if @display_metadata
                if @data_set_hash.empty?
                    @no_data_message_1.draw
                    @no_data_message_2.draw
                end
                @cursor_readout.draw_border
                @font.draw_text("Cursor", @cursor_readout.x + 4, @cursor_readout.y, 1, 1, 1, COLOR_GRAY)
            end
        end

        def is_cursor_on_graph(mouse_x, mouse_y)
            mouse_x > x_pixel_to_screen(@margin_size) - 1 and mouse_x < x_pixel_to_screen(@margin_size) + graph_width and mouse_y > y_pixel_to_screen(0) and mouse_y < y_pixel_to_screen(0) + graph_height 
        end 

        def draw_zoom_box 
            if @gui_mode == MODE_ZOOM_BOX
                Gosu::draw_line @click_x, @click_y, COLOR_GRAY, @last_mouse_x, @click_y, COLOR_GRAY, 12
                Gosu::draw_line @click_x, @click_y, COLOR_GRAY, @click_x, @last_mouse_y, COLOR_GRAY, 12
                Gosu::draw_line @click_x, @last_mouse_y, COLOR_GRAY, @last_mouse_x, @last_mouse_y, COLOR_GRAY, 12
                Gosu::draw_line @last_mouse_x, @click_y, COLOR_GRAY, @last_mouse_x, @last_mouse_y, COLOR_GRAY, 12
            end
        end
        
        def draw_cursor_lines
            if @last_mouse_x and @last_mouse_y
                if @gui_mode == MODE_PLOT
                    x_val, y_val = @plot.draw_cursor_lines(@last_mouse_x, @last_mouse_y)
                else 
                    x_val = @plot.get_x_data_val(@last_mouse_x)
                    y_val = @plot.get_y_data_val(@last_mouse_y)
                end
                if @display_metadata
                    if current_range.is_time_based
                        x_str = Time.at(x_val).to_s
                    else
                        x_str = "x: #{x_val.round(2).to_s}"
                    end
                    @font.draw_text(x_str,
                                    x_pixel_to_screen(@margin_size + graph_width - 186),
                                    y_pixel_to_screen(graph_height + 94), 1, 1, 1, COLOR_GRAY) 
                    @font.draw_text("y: #{y_val.round(2).to_s}",
                                     x_pixel_to_screen(@margin_size + graph_width - 186),
                                    y_pixel_to_screen(graph_height + 124), 1, 1, 1, COLOR_GRAY) 
                end
            end
        end 

        def handle_update update_count, mouse_x, mouse_y
            if is_cursor_on_graph(mouse_x, mouse_y) and @overlay_widget.nil?
                @last_mouse_x = mouse_x
                @last_mouse_y = mouse_y 
            else
                @last_mouse_x = nil
                @last_mouse_y = nil
            end
        end

        def handle_key_press id, mouse_x, mouse_y
            if @window.text_input.nil?
                if id == Gosu::KbF
                    @gui_mode = MODE_DERIVED_FUNCTION_GRAPH
                    add_overlay(DerivedFunctionGraphDisplay.new(x_pixel_to_screen(10), y_pixel_to_screen(10),
                                                               @font,
                                                               @width - 20, graph_height,
                                                               @derived_function_graph))
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
        end

        def handle_mouse_up mouse_x, mouse_y
            if @gui_mode == MODE_ZOOM_BOX
                @gui_mode = MODE_PLOT
                left_x = @plot.get_x_data_val(@click_x)
                right_x = @plot.get_x_data_val(mouse_x)
                bottom_y = @plot.get_y_data_val(mouse_y)
                top_y = @plot.get_y_data_val(@click_y)
                range = VisibleRange.new(left_x, right_x, bottom_y, top_y, current_range.is_time_based)
                set_range_and_update_display(range)
            end
        end

        def handle_right_mouse mouse_x, mouse_y
            if is_cursor_on_graph(mouse_x, mouse_y)
                undo_zoom
            end
        end

        def intercept_widget_event(result)
            #puts "Plotter intercept event #{result.inspect}"
            if @gui_mode == MODE_OPEN_FILE 
                if result.action == EVENT_OK
                    @gui_mode = MODE_PLOT
                    filename_and_format_array = result.form_data
                    if filename_and_format_array[0]
                        add_file_data(filename_and_format_array[0],
                                      filename_and_format_array[1])
                    end
                end
            elsif @gui_mode == MODE_DEFINE_FUNCTION
                if result.action == EVENT_OK
                    @gui_mode = MODE_PLOT
                    add_derived_data_set(result.form_data) 
                    clear_button
                end 
            elsif not result.action.nil? and (result.action == EVENT_TABLE_SELECT or result.action == EVENT_TABLE_UNSELECT)
                data_set_name = result.form_data[1]
                @data_set_hash[data_set_name].toggle_visibility
                @plot.toggle_visibility(data_set_name)
            elsif not result.action.nil? and result.action == EVENT_TABLE_ROW_DELETE
                data_set_to_remove = result.form_data[0]
                @data_set_hash.delete(data_set_to_remove)
                @plot.remove_data_set(data_set_to_remove)
                @derived_function_graph.delete(data_set_to_remove)
                update_plot_data_sets
            end
        end

        def handle_mouse_down mouse_x, mouse_y
            if @gui_mode == MODE_PLOT and is_cursor_on_graph(mouse_x, mouse_y)
                @click_x = mouse_x
                @click_y = mouse_y
                @gui_mode = MODE_ZOOM_BOX
                return WidgetResult.new(false)
            end
        end
    end  
end
