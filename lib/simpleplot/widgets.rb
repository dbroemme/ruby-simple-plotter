module SimplePlot
    class Widget 
        attr_accessor :x
        attr_accessor :y 
        attr_accessor :color 
        attr_accessor :width
        attr_accessor :height 
        attr_accessor :visible 
        attr_accessor :children
        attr_accessor :background_color
        attr_accessor :border_color
        attr_accessor :font

        def initialize(x, y, color = COLOR_CYAN) 
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

        def clear_children 
            @children = [] 
        end

        def set_background(bgcolor)
            @background_color = bgcolor 
        end

        def set_border(bcolor)
            @border_color = bcolor 
        end

        def set_font(font)
            @font = font 
        end

        def set_dimensions(width, height)
            @width = width
            @height = height 
        end

        def right_edge
            @x + @width - 1
        end
        
        def bottom_edge
            @y + @height - 1
        end

        def center_x
            @x + ((right_edge - @x) / 2)
        end 

        def draw 
            if @visible 
                render
                if @background_color
                    Gosu::draw_rect(@x + 1, @y + 1, @width - 1, @height - 1, @background_color, 2) 
                end
                if @border_color 
                    draw_border(@border_color)
                end
                @children.each do |child| 
                    child.draw 
                end 
            end 
        end

        def render 
            # Base implementation is empty
            # Note that the draw method invoked by clients stills renders any added children
            # render is for specific drawing done by the widget
        end 

        def draw_border(color = nil)
            if color.nil? 
                color = @color 
            end
            Gosu::draw_line @x, @y, color, right_edge, @y, color, 12
            Gosu::draw_line @x, @y, color, @x, bottom_edge, color, 12
            Gosu::draw_line @x,bottom_edge, color, right_edge, bottom_edge, color, 12
            Gosu::draw_line right_edge, @y, color, right_edge, bottom_edge, color, 12
        end

        def contains_click(mouse_x, mouse_y)
            mouse_x >= @x and mouse_x <= right_edge and mouse_y >= @y and mouse_y <= bottom_edge
        end
    end 

    class Text < Widget
        attr_accessor :str
        def initialize(str, x, y, font, color = COLOR_WHITE) 
            super(x, y, color) 
            set_font(font)
            @str = str
        end
        def render 
            @font.draw_text(@str, @x, @y, 10, 1, 1, @color)
        end
    end 

    class ErrorMessage < Text
        attr_accessor :str
        def initialize(str, x, y, font) 
            super("ERROR: #{str}", x, y, font, COLOR_RED) 
            set_dimensions(@font.text_width(@str) + 4, 36)
            set_background(COLOR_BLACK)
        end
    end 

    class PlotPoint < Widget
        attr_accessor :data_point_size 

        def initialize(x, y, color = COLOR_MAROON, size = 4) 
            super(x, y, color) 
            @data_point_size = size
        end

        def render 
            @half_size = @data_point_size / 2
            Gosu::draw_rect(@x - @half_size, @y - @half_size,
                            @data_point_size, @data_point_size,
                            @color, 2) 
        end 

        def to_display 
            "#{@x}, #{@y}"
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

    class Button < Widget
        attr_accessor :label
        attr_accessor :is_pressed

        def initialize(label, x, y, font, width = nil, color = COLOR_DARK_GRAY) 
            super(x, y, color) 
            set_font(font)
            @label = label
            @text_pixel_width = @font.text_width(@label)
            if width.nil?
                @width = @text_pixel_width + 10
            else 
                @width = width 
            end
            @height = 26
            @is_pressed = false
        end

        def render 
            draw_border(COLOR_WHITE)
            text_x = center_x - (@text_pixel_width / 2)
            @font.draw_text(@label, text_x, @y, 10, 1, 1, COLOR_CYAN)
        end 
    end 

    class Document < Widget
        attr_accessor :lines

        def initialize(content, x, y, width, height, font) 
            super(x, y, COLOR_GRAY) 
            set_font(font)
            set_dimensions(width, height)
            @lines = content.split("\n")
        end

        def render 
            y = @y + 4
            @lines.each do |line|
                @font.draw_text(line, @x + 5, y, 10, 1, 1, COLOR_WHITE)
                y = y + 26
            end
        end 
    end 

    class InfoBox < Widget 
        def initialize(title, content, x, y, font, width, height) 
            super(x, y) 
            set_font(font)
            set_dimensions(width, height)
            set_border(COLOR_WHITE)
            @title = title
            add_child(Text.new(title, x + 5, y + 5, Gosu::Font.new(32)))
            add_child(Document.new(content, x + 5, y + 52, width, height, font))
            @ok_button = Button.new("OK", center_x - 50, bottom_edge - 26, @font, 100, COLOR_FORM_BUTTON)
            add_child(@ok_button) 
            set_background(COLOR_GRAY)
        end

        def button_down id, mouse_x, mouse_y
            if id == Gosu::KbEscape
                return WidgetResult.new(true) 
            elsif id == Gosu::MsLeft
                if @ok_button.contains_click(mouse_x, mouse_y)
                    return WidgetResult.new(true) 
                end
            end
            WidgetResult.new(false)
        end
    end

    class Dialog < Widget
        attr_accessor :textinput

        def initialize(window, font, x, y, width, height, title, text_input_default) 
            super(x, y) 
            @window = window
            set_font(font)
            set_dimensions(width, height)
            set_background(COLOR_GRAY)
            set_border(COLOR_WHITE)
            @error_message = nil

            add_child(Text.new(title, x + 5, y + 5, @font))
            # Forms automatically have some explanatory content
            add_child(Document.new(content, x, y + 56, width, height, font))

            # Forms automatically get a text input widget
            @textinput = TextField.new(@window, @font, x + 10, bottom_edge - 80, text_input_default, 600)
            add_child(@textinput)

            # Forms automatically get OK and Cancel buttons
            @ok_button = Button.new("OK", center_x - 100, bottom_edge - 26, @font, 100, COLOR_FORM_BUTTON)
            @cancel_button = Button.new("Cancel", center_x + 50, bottom_edge - 26, @font, 100, COLOR_FORM_BUTTON)
            add_child(@ok_button) 
            add_child(@cancel_button)
        end

        def content 
            <<~HEREDOC
            Override the content method to
            put your info here.
            HEREDOC
        end

        def add_error_message(msg) 
            @error_message = ErrorMessage.new(msg, x + 10, y + 94, @font)
        end 

        def render 
            if @error_message
                @error_message.draw 
            end 
        end

        def handle_ok
            # Default behavior is to do nothing except tell the caller to 
            # close the dialog
            return WidgetResult.new(true) 
        end

        def handle_cancel
            # Default behavior is to do nothing except tell the caller to 
            # close the dialog
            return WidgetResult.new(true) 
        end

        def handle_up(mouse_x, mouse_y)
            # empty implementation of up arrow
        end

        def handle_down(mouse_x, mouse_y)
            # empty implementation of down arrow
        end

        def handle_mouse_click(mouse_x, mouse_y)
            # empty implementation of mouse click outside
            # of standard form elements in this dialog
        end

        def button_down id, mouse_x, mouse_y
            if id == Gosu::KbEscape
                return WidgetResult.new(true) 
            elsif id == Gosu::KbUp
                handle_up(mouse_x, mouse_y)
            elsif id == Gosu::KbDown
                handle_down(mouse_x, mouse_y)
            elsif id == Gosu::MsLeft
                if @ok_button.contains_click(mouse_x, mouse_y)
                    return handle_ok
                elsif @cancel_button.contains_click(mouse_x, mouse_y)
                    return handle_cancel 
                else 
                    # Mouse click: Select text field based on mouse position.
                    @window.text_input = [@textinput].find { |tf| tf.under_point?(mouse_x, mouse_y) }
                    # Advanced: Move caret to clicked position
                    @window.text_input.move_caret(mouse_x) unless @window.text_input.nil?

                    handle_mouse_click(mouse_x, mouse_y)
                end
            end
            WidgetResult.new(false)
        end
    end 

    class WidgetResult 
        attr_accessor :close_widget
        attr_accessor :action
        attr_accessor :form_data

        def initialize(close_widget = false, action = "none", form_data = nil)
            @close_widget = close_widget 
            @action = action 
            @form_data = form_data
        end
    end

    class Line < Widget
        attr_accessor :x2
        attr_accessor :y2

        def initialize(x, y, x2, y2, color = COLOR_CYAN) 
            super x, y, color 
            @x2 = x2 
            @y2 = y2
        end

        def render
            Gosu::draw_line x, y, @color, x2, y2, @color
        end
    end 

    class AxisLines < Widget
        def initialize(x, y, width, height, color = COLOR_CYAN) 
            super x, y, color 
            @width = width 
            @height = height
        end

        def render
            add_child(Line.new(@x, @y, @x, bottom_edge, @color))
            add_child(Line.new(@x, bottom_edge, right_edge, bottom_edge, @color))
        end
    end

    class VerticalAxisLabel < Widget
        attr_accessor :label

        def initialize(x, y, label, font, color = COLOR_CYAN) 
            super x, y, color 
            set_font(font)
            @label = label 
        end

        def render
            text_pixel_width = @font.text_width(@label)
            Gosu::draw_line @x - 20, @y, @color,
                            @x, @y, @color
            
            @font.draw_text(@label, @x - text_pixel_width - 28, @y - 12, 1, 1, 1, @color)
        end
    end 

    class HorizontalAxisLabel < Widget
        attr_accessor :label

        def initialize(x, y, label, font, color = COLOR_CYAN) 
            super x, y, color 
            set_font(font)
            @label = label 
        end

        def render
            text_pixel_width = @font.text_width(@label)
            Gosu::draw_line @x, @y, @color, @x, @y + 20, @color
            @font.draw_text(@label, @x - (text_pixel_width / 2), @y + 26, 1, 1, 1, @color)
        end
    end 

    class Table < Widget
        attr_accessor :data_rows 
        attr_accessor :row_colors
        attr_accessor :selected_row
        attr_accessor :headers
        attr_accessor :max_visible_rows
        attr_accessor :current_row

        def initialize(x, y, width, height, headers, font, color = COLOR_GRAY, max_visible_rows = 10) 
            super(x, y, color) 
            set_font(font) 
            set_dimensions(width, height)
            @headers = headers
            @current_row = 0
            @max_visible_rows = max_visible_rows
            clear_rows            
        end

        def scroll_up 
            if @current_row > 0
                @current_row = @current_row - @max_visible_rows 
            end 
        end 

        def scroll_down
            if @current_row < @data_rows.size - 1
                @current_row = @current_row + @max_visible_rows 
            end 
        end 

        def set_selected_row(mouse_y, column_number)
            relative_y = mouse_y - @y
            row_number = (relative_y / 30).floor - 1
            if row_number < 0 or row_number > data_rows.size - 1
                return nil 
            end 
            @selected_row = @current_row + row_number
            @data_rows[@selected_row][column_number]
        end

        def clear_rows 
            @data_rows = []
            @row_colors = []
        end 

        def add_row(data_row, color)
            @data_rows << data_row
            @row_colors << color
        end

        def render
            draw_border
            number_of_rows = @data_rows.size
            return unless number_of_rows > 0

            column_widths = []
            number_of_columns = @data_rows[0].size 
            (0..number_of_columns-1).each do |c| 
                max_length = @font.text_width(headers[c])
                (0..number_of_rows-1).each do |r|
                    text_pixel_width = @font.text_width(@data_rows[r][c])
                    if text_pixel_width > max_length 
                        max_length = text_pixel_width
                    end 
                end 
                column_widths[c] = max_length
            end

            x = @x + 10
            if number_of_columns > 1
                (0..number_of_columns-2).each do |c| 
                    x = x + column_widths[c] + 20
                    Gosu::draw_line x, @y, @color, x, @y + @height, @color, 20
                end 
            end

            y = @y             
            x = @x + 20
            (0..number_of_columns-1).each do |c| 
                @font.draw_text(@headers[c], x, y, 20, 1, 1, @color)
                x = x + column_widths[c] + 20
            end
            y = y + 30

            count = 0
            @data_rows.each do |row|
                if count < @current_row
                    # skip
                elsif count < @current_row + @max_visible_rows
                    x = @x + 20
                    (0..number_of_columns-1).each do |c| 
                        @font.draw_text(row[c], x, y, 20, 1, 1, @row_colors[count])
                        x = x + column_widths[c] + 20
                    end
                    if @selected_row 
                        if count == @selected_row 
                            Gosu::draw_rect(@x + 20, y, @width - 30, 28, COLOR_BLACK, 19) 
                        end 
                    end
                    y = y + 30
                end
                count = count + 1
            end
        end
    end

    class Plot < Widget
        attr_accessor :points
        attr_accessor :visible_range
        attr_accessor :display_grid
        attr_accessor :display_lines
        attr_accessor :zoom_level

        def initialize(x, y, width, height, font) 
            super x, y, color 
            set_font(font)
            set_dimensions(width, height)
            @display_grid = false
            @display_lines = true
            @data_set_hash = {}
            @grid_line_color = COLOR_CYAN
            @cursor_line_color = COLOR_DARK_GRAY 
            @zero_line_color = COLOR_BLUE 
            @zoom_level = 1
        end

        def increase_data_point_size 
            @data_set_hash.keys.each do |key|
                data_set = @data_set_hash[key]
                data_set.rendered_points.each do |point| 
                    point.increase_size 
                end
            end
        end 

        def decrease_data_point_size 
            @data_set_hash.keys.each do |key|
                data_set = @data_set_hash[key]
                data_set.rendered_points.each do |point| 
                    point.decrease_size 
                end
            end
        end

        def zoom_out 
            @zoom_level = @zoom_level + 0.1
            visible_range.scale(@zoom_level)
        end 

        def zoom_in
            if @zoom_level > 0.11
                @zoom_level = @zoom_level - 0.1
            end
            visible_range.scale(@zoom_level)
        end 

        def scroll_up 
            visible_range.scroll_up
        end

        def scroll_down
            visible_range.scroll_down
        end

        def scroll_right
            visible_range.scroll_right
        end

        def scroll_left
            visible_range.scroll_left
        end

        def define_range(range)
            @visible_range = range
            @zoom_level = 1
            @data_set_hash.keys.each do |key|
                data_set = @data_set_hash[key]
                puts "Calling derive values on #{key}"
                data_set.derive_values(range)
            end
        end 

        def range_set?
            not @visible_range.nil?
        end 

        def is_on_screen(point) 
            point.x >= @visible_range.left_x and point.x <= @visible_range.right_x and point.y >= @visible_range.bottom_y and point.y <= @visible_range.top_y
        end 

        def add_data_set(data_set)
            if range_set?
                @data_set_hash[data_set.name] = data_set
                data_set.clear_rendered_points
                data_set.derive_values(@visible_range)
                data_set.data_points.each do |point|
                    if is_on_screen(point) 
                        #puts "Adding render point at x #{point.x}, #{Time.at(point.x)}"
                        #puts "Visible range: #{Time.at(@visible_range.left_x)}  #{Time.at(@visible_range.right_x)}"
                        data_set.add_rendered_point PlotPoint.new(draw_x(point.x), draw_y(point.y), data_set.color, data_set.data_point_size)
                    end
                end
            else
                puts "ERROR: range not set, cannot add data"
            end
        end 

        def x_val_to_pixel(val)
            x_pct = (@visible_range.right_x - val).to_f / @visible_range.x_range 
            @width - (@width.to_f * x_pct).round
        end 

        def y_val_to_pixel(val)
            y_pct = (@visible_range.top_y - val).to_f / @visible_range.y_range 
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
            @data_set_hash.keys.each do |key|
                data_set = @data_set_hash[key]
                data_set.rendered_points.each do |point| 
                    point.draw 
                end 
                if @display_lines 
                    display_lines_for_point_set(data_set.rendered_points) 
                end
            end
            if @display_grid and range_set?
                display_grid_lines
            end
        end

        def display_lines_for_point_set(points) 
            if points.length > 1
                points.inject(points[0]) do |last, the_next|
                    Gosu::draw_line last.x, last.y, last.color,
                                    the_next.x, the_next.y, last.color, 2
                    the_next
                end
            end
        end

        def display_grid_lines
            # TODO this is broken. With axis 0-2, 0-4, it was only drawing
            # lines on the edges
            # also, it doesn't work for large values because the increment is 1
            # we can't draw hundreds of thousands of lines
            grid_widgets = []

            grid_x = @visible_range.left_x
            grid_y = @visible_range.bottom_y + 1
            while grid_y < @visible_range.top_y
                dx = draw_x(grid_x)
                dy = draw_y(grid_y)
                last_x = draw_x(@visible_range.right_x)
                color = @grid_line_color
                if grid_y == 0 and grid_y != @visible_range.bottom_y.to_i
                    color = @zero_line_color
                end
                grid_widgets << Line.new(dx, dy, last_x, dy, color) 
                grid_y = grid_y + 1
            end
            grid_x = @visible_range.left_x + 1
            grid_y = @visible_range.bottom_y
            while grid_x < @visible_range.right_x
                dx = draw_x(grid_x)
                dy = draw_y(grid_y)
                last_y = draw_y(@visible_range.top_y)
                color = @grid_line_color
                if grid_x == 0 and grid_x != @visible_range.left_x.to_i
                    color = @zero_line_color 
                end
                grid_widgets << Line.new(dx, dy, dx, last_y, color) 
                grid_x = grid_x + 1
            end

            grid_widgets.each do |gw| 
                gw.draw 
            end
        end

        def draw_cursor_lines(mouse_x, mouse_y)
            Gosu::draw_line mouse_x, y_pixel_to_screen(0), @cursor_line_color, mouse_x, y_pixel_to_screen(@height), @cursor_line_color
            Gosu::draw_line x_pixel_to_screen(0), mouse_y, @cursor_line_color, x_pixel_to_screen(@width), mouse_y, @cursor_line_color
            
            graph_x = mouse_x - @x
            graph_y = mouse_y - @y
            x_pct = (@width - graph_x).to_f / @width.to_f
            x_val = @visible_range.right_x - (x_pct * @visible_range.x_range)
            y_pct = graph_y.to_f / @height.to_f
            y_val = @visible_range.top_y - (y_pct * @visible_range.y_range)

            # Return the data values at this point, so the plotter can display them
            [x_val, y_val]
        end 
    end 
end