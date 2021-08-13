module SimplePlot
    class Widget 
        attr_accessor :x
        attr_accessor :y 
        attr_accessor :color 
        attr_accessor :width
        attr_accessor :height 
        attr_accessor :visible 

        def initialize(x, y, color = Gosu::Color::GREEN) 
            @x = x 
            @y = y 
            @color = color
            @width = 1 
            @height = 1
            @visible = true
        end

        def draw 
            if @visible 
                #puts "About to render #{self.class.name}"
                render 
            end 
        end
    end 

    class PlotPoint < Widget
        attr_accessor :data_point_size 

        def initialize(x, y, size = 4, color = Gosu::Color::GREEN) 
            super x, y, color 
            @data_point_size = size
            @half_size = @data_point_size / 2
        end

        def render 
            Gosu::draw_rect(@x - @half_size, @y - @half_size,
                            @data_point_size, @data_point_size,
                            @color, 2) 
        end 

        def to_display 
            "#{@x}, #{@y}"
        end
    end 

    class AxisLines < Widget
        def initialize(x, y, width, height, color = Gosu::Color::GREEN) 
            super x, y, color 
            @width = width 
            @height = height
        end

        def render
            Gosu::draw_line @x, @y, @color, @x, @y + @height, @color
            Gosu::draw_line @x, @y + @height, @color, @x + @width, @y + @height, @color
        end
    end
    
    class Line < Widget
        attr_accessor :x2
        attr_accessor :y2

        def initialize(x, y, x2, y2, color = Gosu::Color::GREEN) 
            super x, y, color 
            @x2 = x2 
            @y2 = y2
        end

        def render
            Gosu::draw_line x, y, @color, x2, y2, @color
        end
    end 
end