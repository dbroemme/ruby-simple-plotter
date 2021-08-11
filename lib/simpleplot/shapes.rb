module SimplePlot
    class PlotPoint
        attr_accessor :x
        attr_accessor :y 
        attr_accessor :pixel_x
        attr_accessor :pixel_y 
        attr_accessor :color 

        def initialize(x, y, color = Gosu::Color::GREEN) 
            @x = x 
            @y = y 
            @color = color
        end

        def to_display 
            "#{@x}, #{@y}"
        end
    end 
end