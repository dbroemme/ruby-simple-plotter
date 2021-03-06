require 'gosu'
require_relative 'plotter'
require_relative 'version'

# This app allows you to quickly use the SimplePlot gem and also
# serves as a starting point for how you can use it in your own
# applications.
class SimplePlotterApp < Gosu::Window
    attr_accessor :plotter
    def initialize
        super(900, 700, {:resizable => true})
        self.caption = "Simple Plot App"
        @font = Gosu::Font.new(32)
        @title_font = Gosu::Font.new(38)
        @version_font = Gosu::Font.new(22)
        @plotter = SimplePlot::SimplePlot.new(self, 0, 100, 800, 600, @version_font) 
        @banner_image = Gosu::Image.new("./media/Banner.png")
        @update_count = 0
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
        else
            spa.plotter.set_range_and_update_display(Wads::VisibleRange.new(0, 10, 0, 10))
        end

        if opts[:define_function]
            spa.plotter.add_derived_data_set(opts[:define_function]) 
        end

        spa.show
    end

    def update 
        @plotter.update(@update_count, mouse_x, mouse_y)
        @update_count = @update_count + 1
    end 
    
    def draw 
        draw_banner
        @plotter.draw
    end 

    def draw_banner 
        @banner_image.draw(1,1,1,0.9,0.9)
        @title_font.draw_text("Ruby Simple Plotter", 10, 20, 2, 1, 1, Gosu::Color::WHITE)
        @version_font.draw_text("Version #{SimplePlot::VERSION}", 13, 54, 2, 1, 1, Gosu::Color::WHITE)
    end

    def button_up id
        @plotter.button_up id, mouse_x, mouse_y
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
            if not result.nil? and result.is_a? WidgetResult
                if result.close_widget
                    close 
                end
            end
        end
    end
end



