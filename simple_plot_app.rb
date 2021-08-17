require_relative "lib/simpleplot/app"
require 'tty-option'

class SimplePlotCommand 
    include TTY::Option

    usage do 
        program "run-simple-plotter"

        command ""

        example <<~EOS
        Run the simple plotter with the data file a.csv and columns x,y
          $ ./run-simple-plotter -f a.csv -c x,y
        EOS

    end

    flag :help do 
        short "-h"
        long "--help"
        desc "Print usage"
    end 

    flag :interactive do 
        short "-i"
        long "--interactive"
        desc "Run in interactive mode"
    end 

    option :input_file do 
        short "-f string"
        long "--input-file string"
        desc "Specify an input data file"
    end 

    option :columns do 
        short "-c string"
        long "--columns string"
        desc "Specify the order of columns in the input file"
    end

    def run 
        if params[:help]
            print help 
            exit 
        end 
        params.to_h 
    end
end 

SimplePlotterApp.new.parse_opts_and_run