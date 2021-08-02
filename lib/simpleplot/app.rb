require 'gosu'
require '../lib/simpleplot'

# This app allows you to quickly use the SimplePlot gem and also
# serves as a starting point for how you can use it in your own
# applications.
class SimplePlotterApp < Gosu::Window
    def initialize
        super(800, 600, false)
        self.caption = "Simple Plot App"
        @plotter = SimplePlot::SimplePlot.new
        @plotter.data = create_atan_wave
    end 

    def update 
        # Nothing to do 
    end 
    
    def draw 
        @plotter.render

        if is_cursor_on_graph 
            @plotter.draw_cursor_lines(mouse_x, mouse_y)
        end 
    end 

    def is_cursor_on_graph
        mouse_x > 199 and mouse_x < 801 and mouse_y > 0 and mouse_y < 400 
    end 

    def button_down id
        close if id == Gosu::KbEscape or id == Gosu::KbQ
        @plotter.button_down id, mouse_x, mouse_y
    end
end

def create_atan_wave
    data = []
    delta_x = 0.05
    x = 0
    while x < SimplePlot::DEG_180
        data << SimplePlot::PlotPoint.new(x, Math.atan(x * 3) * 0.694)
        x = x + delta_x 
    end
    data
end

def create_sin_wave(factor2, color)
    delta_x = 0.05
    x = 0
    first_y = (Math.cos(0) + 1) / factor2
    y_offset = 1 - first_y
    while x < DEG_180
        @data << Point.new(x, ((Math.cos(x * 2) + 1) / factor2) + y_offset, color)
        x = x + delta_x 
    end
end

def latest_test 
    x = 0
    delta_x = 0.01
    while x < DEG_90
        #cos_to_use = (DEG_90 - x).abs
        #factor2 = scale(x, DEG_90, 7) + 2 
        #factor2 = scale(x, DEG_90, 5) + 2
        #@data << Point.new(x, (Math.cos(cos_to_use * 1.5)) + 0.76)
        @data << Point.new(x, Math.atan(x * 3) * 0.694)
        @data << Point.new(x, Math.atan(x * 2) * 0.694, Gosu::Color::YELLOW)
        @data << Point.new(x, Math.atan(x * 1.5) * 0.694, Gosu::Color::RED)
        @data << Point.new(x, Math.atan(x) * 0.694, Gosu::Color::CYAN)
        @data << Point.new(x, Math.atan(x / 2), Gosu::Color::GRAY)
        @data << Point.new(x, Math.atan(x) / 2, Gosu::Color::WHITE)

        x = x + delta_x 
    end
end


def calc_x_y_line
    @data = []
    local_x = @left_x
    while local_x < @right_x
        local_y = @y_offset + (@slope * local_x)
        @data << Point.new(local_x, local_y, Gosu::Color::RED)
        local_x = local_x + 0.05
    end
end

########################################
# x, y line plotting                   #
########################################
#@y_offset = 0
#@slope = -DEG_135
