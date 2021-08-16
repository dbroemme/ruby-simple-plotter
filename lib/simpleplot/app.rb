require 'gosu'
require_relative 'plotter'

# This app allows you to quickly use the SimplePlot gem and also
# serves as a starting point for how you can use it in your own
# applications.
class SimplePlotterApp < Gosu::Window
    def initialize
        super(900, 700, {:resizable => true})
        self.caption = "Simple Plot App"
        @widget_start_x = 0
        @widget_start_y = 100
        @plotter = SimplePlot::SimplePlot.new(self, 800, 600, @widget_start_x, @widget_start_y)
        
        @plotter.add_data_set("atan", create_atan_wave)
        #@plotter.add_data_set("sin", create_sin_wave, Gosu::Color::BLUE)
        #@plotter.add_file_data("./data/diagonal.csv", "n,x,y", {"line" => Gosu::Color::RED})
        #@plotter.add_file_data("./data/portfolio2.csv", "t,n,y", {"Portfolio" => Gosu::Color::RED})
        color_map = 
            {"BTC" => Gosu::Color::GREEN,
             "ETH" => Gosu::Color::BLUE,
             "AAVE" => Gosu::Color::WHITE,
             "MATIC" => Gosu::Color::CYAN,
             "ENJ" => Gosu::Color::YELLOW,
             "MANA" => Gosu::Color::FUCHSIA,
             "DOGE" => Gosu::Color::RED,
             "ADA" => Gosu::Color::GRAY
            }
        #@plotter.add_file_data("./data/prices.csv", "t,n,y", color_map)
        @font = Gosu::Font.new(32)
        @update_count = 0
        @pause = false
    end 

    def update 
        if not @pause
            @update_count = @update_count + 1
        end 
    end 
    
    def draw 
        #draw_rect(0, 0, 100, 1000, Gosu::Color::RED)
        #draw_rect(0, 0, 1000, 100, Gosu::Color::RED)
        @plotter.render(width, height, @update_count)

        if is_cursor_on_graph 
            @plotter.draw_cursor_lines(mouse_x, mouse_y)
        end 

        @font.draw_text("#{width}, #{height}", @widget_start_x + 600, height - 32, 1, 1, 1, Gosu::Color::WHITE) 
        if button_down?(Gosu::KbLeft)
            @plotter.button_down Gosu::KbLeft, mouse_x, mouse_y
        elsif button_down?(Gosu::KbRight)
            @plotter.button_down Gosu::KbRight, mouse_x, mouse_y
        elsif button_down?(Gosu::KbUp)
            @plotter.button_down Gosu::KbUp, mouse_x, mouse_y
        elsif button_down?(Gosu::KbDown)
            @plotter.button_down Gosu::KbDown, mouse_x, mouse_y
        end
    end 

    def is_cursor_on_graph
        mouse_x > @widget_start_x + 199 and mouse_x < width and mouse_y > @widget_start_y and mouse_y < height - 200 
    end 

    def button_down id
        if id == Gosu::KbEscape then
            # Escape key will not be 'eaten' by text fields; use for deselecting.
            if self.text_input
                self.text_input = nil
            else
                close
            end
        else
            close if id == Gosu::KbQ
            @plotter.button_down id, mouse_x, mouse_y
        end
    end
end

def create_atan_wave
    data = []
    delta_x = 0.05
    x = 0
    while x < SimplePlot::DEG_180
        data << SimplePlot::DataPoint.new(x, Math.atan(x * 3) * 0.694)
        x = x + delta_x 
    end
    data
end

def create_sin_wave
    data = []
    delta_x = 0.05
    x = 0
    while x < SimplePlot::DEG_180
        data << SimplePlot::DataPoint.new(x, Math.sin(x))
        x = x + delta_x 
    end
    data
end


########################################
# x, y line plotting                   #
########################################
#@y_offset = 0
#@slope = -DEG_135
