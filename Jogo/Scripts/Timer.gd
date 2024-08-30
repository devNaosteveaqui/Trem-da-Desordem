extends Label

class_name GameTimer

signal game_time_end

var time_left : int
var count_time

func _ready():
	reset_time()
	updateTimer()

func _process(delta):
	if Game.RUNNING:
		if time_left > 0 and count_time > 1:
			count_time -= 1
			time_left -= 1
			updateTimer()
		count_time += delta
		if time_left == 0:
			time_left = -1
			emit_signal("game_time_end")

func updateTimer():
	text = str(time_left/60) + " : " + str(time_left%60)

func reset_time():
	time_left = 30#*60
	count_time = 0
