extends Control

@onready var chart: Chart = $VBoxContainer/Chart
# This Chart will plot 3 different functions
var f1: Function
var Counter : int = 0;
var Arr : Array[float] = []
@export var color : Color

var x : Array
var y : Array

func _ready():
	# Let's create our @x values
	x = range(0,2)
	#var x : Array[int] = [0, 1] 
	# And our y values. It can be an n-size array of arrays.
	# NOTE: `x.size() == y.size()` or `x.size() == y[n].size()`
	y = ArrayOperations.multiply_int(ArrayOperations.sin(x), 2)
	#var y : Array[float] = [1.0, 1.0]
	
	# Let's customize the chart properties, which specify how the chart
	# should look, plus some additional elements like labels, the scale, etc...
	var cp: ChartProperties = ChartProperties.new()
	cp.colors.frame = Color("#161a1d")
	cp.colors.background = Color.TRANSPARENT
	cp.colors.grid = Color("#283442")
	cp.colors.ticks = Color("#283442")
	cp.colors.text = Color.WHITE_SMOKE
	cp.draw_bounding_box = false
	cp.title = "Air Quality Monitoring"
	cp.x_label = "Time"
	cp.y_label = "Sensor values"
	cp.x_scale = 10
	cp.y_scale = 10
	cp.interactive = true # false by default, it allows the chart to create a tooltip to show point values
	# and interecept clicks on the plot
	
	# Let's add values to our functions
	f1 = Function.new(
		x, y, "Pressure", # This will create a function with x and y values taken by the Arrays 
						# we have created previously. This function will also be named "Pressure"
						# as it contains 'pressure' values.
						# If set, the name of a function will be used both in the Legend
						# (if enabled thourgh ChartProperties) and on the Tooltip (if enabled).
		# Let's also provide a dictionary of configuration parameters for this specific function.
		{ 
			color = color, 		# The color associated to this function
			marker = Function.Marker.CIRCLE, 	# The marker that will be displayed for each drawn point (x,y)
											# since it is `NONE`, no marker will be shown.
			type = Function.Type.LINE, 		# This defines what kind of plotting will be used, 
											# in this case it will be a Linear Chart.
			interpolation = Function.Interpolation.LINEAR	# Interpolation mode, only used for 
															# Line Charts and Area Charts.
		}
	)
	
	# Now let's plot our data
	chart.plot([f1], cp)
	for v : int in x.size()-1:
		f1.remove_point(0)
	add_Point(0)
	f1.remove_point(0)
	# Uncommenting this line will show how real time data plotting works
	set_process(false)


var new_val: float = 4.5

func _process(delta: float):
	pass
	## This function updates the values of a function and then updates the plot
	#new_val += 5
	#
	## we can use the `Function.add_point(x, y)` method to update a function
	#f1.add_point(new_val, cos(new_val) * 20)
	#f1.remove_point(0)
	#chart.queue_redraw() # This will force the Chart to be updated


func add_Point(val : float):
	f1.add_point(Counter, val)
	Counter += 1
	chart.queue_redraw()

func clear_Points():
	for v : int in Counter-1:
		f1.remove_point(0)
	add_Point(0)
	f1.remove_point(0)
	Counter = 2

func set_Counter(val : int) -> void:
	Counter = val
