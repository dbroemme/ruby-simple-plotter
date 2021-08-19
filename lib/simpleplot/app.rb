require 'gosu'
require_relative 'plotter'

# This app allows you to quickly use the SimplePlot gem and also
# serves as a starting point for how you can use it in your own
# applications.
class SimplePlotterApp < Gosu::Window
    attr_accessor :plotter
    def initialize
        super(900, 700, {:resizable => true})
        self.caption = "Simple Plot App"
        @widget_start_x = 0
        @widget_start_y = 100
        @plotter = SimplePlot::SimplePlot.new(self, 800, 600, @widget_start_x, @widget_start_y) 
        @font = Gosu::Font.new(32)
        @update_count = 0
        @pause = false
    end 

    def parse_opts_and_run 
        # Make help the default output if no args are specified
        if ARGV.length == 0
            ARGV[0] = "-h"
        end

        spa = SimplePlotterApp.new

        opts = SimplePlotCommand.new.parse.run
        if opts[:input_file]
            file_name = opts[:input_file]
            file_format = opts[:columns]
            if file_format.nil?
                file_format = "x,y"
            end 
            spa.plotter.add_file_data(file_name, file_format)

        elsif opts[:interactive]
            spa.plotter.range = SimplePlot::Range.new(0, 10, 0, 10)
            spa.plotter.calculate_axis_labels
            spa.plotter.apply_visible_range
        end

        spa.show
    end

    def update 
        if not @pause
            @update_count = @update_count + 1
        end 
    end 
    
    def draw 
        @plotter.render(width, height, @update_count)

        if is_cursor_on_graph and @plotter.overlay_widget.nil?
            @plotter.draw_cursor_lines(mouse_x, mouse_y)
        end 
    end 

    def is_cursor_on_graph
        mouse_x > @widget_start_x + 199 and mouse_x < width and mouse_y > @widget_start_y and mouse_y < height - 200 
    end 

    def button_down id
        if id == Gosu::KbEscape
            # Escape key will not be 'eaten' by text fields; use for deselecting.
            if self.text_input
                @plotter.clear_button
            elsif @plotter.overlay_widget
                @plotter.overlay_widget = nil
            else
                close
            end
        else
            close if id == Gosu::KbQ and self.text_input.nil? and @plotter.overlay_widget.nil?
            result = @plotter.button_down id, mouse_x, mouse_y
            if not result.nil?
                if result.close_widget
                    close 
                end
            end
        end
    end
end



