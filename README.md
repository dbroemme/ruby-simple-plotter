# Ruby Simple Plotter

This is the first in a series of applications, libraries, and utilities written using Ruby and Gosu. 

NOTE: This will soon be published as a gem, but for now can be used as-is. This repo includes the application to run Simple Plotter as well as the libraries and widgets that can be incorporated into other applications.

NOTE: This is an early beta version, any and all feedback is welcome!

Follow me on Twitter at https://twitter.com/DarrenBroemmer for news and announcements about this project.

![alt Screenshot](https://github.com/dbroemme/ruby-simple-plotter/blob/main/media/SimplePlotScreenshot.png?raw=true)

## Installation

Simply clone the repo and use one of the run scripts to get started. There are a few samples you can use. Data can be plotted either from a csv file or through a custom defined function. Multiple data sets can be plotted on the same graph.

## Plotting data from a file

To get started, run the following script to see how Simple Plotter reads data from a file. You can also use the Open Data File button in the application to add other data files.

NOTE: Currently, the Simple Plotter open file dialog only looks for files in the /data subdirectory of the repo. You will find two example files there to get started.

```
./plot-example-file-diagonal
```

The run-simple-plotter script can be used directly, the sample scripts are provided for convenience and to get started quickly. Note the two command line parameters: the data file and a format string.
```
./run-simple-plotter -f ./data/example_diagonal.csv -c n,x,y
```

The format string (-c) tokens are as follows. Note that you would use either t for time, or x for numeric x-axis values.

```
t - time
n - name of data set
x - x value
y - y value
```

## Plotting data using a custom function
You can either specify a function on the command line or use the Define Function button in the application. The expression is of the form:
```
data_set_name = expression
```
where expression is a valid Ruby expression, that typically involves some function of x (i.e. the x-axis values)

See the plot-function-sin-wave for an example:
```
./run-simple-plotter -d "sin=Math.sin(x)+2"
```

The left-hand-side is an arbitrary name, and that name will be used as the data set name in the graph window.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dbroemme/simple-plot.
