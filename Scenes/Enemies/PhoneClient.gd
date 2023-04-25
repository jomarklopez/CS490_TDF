extends PathFollow2D

signal base_damage(damage)
signal time_out()

var speed = 150
var process = 0
var base_damage = 21

var firewall_blocked = false
var waiting = false
var lb_forward_prop = false
var lb_backward_prop = false
var server_forward_prop = false
var server_backward_prop = false
var data_write_en = true
var data_write = false
var reverse = false
#var hit_blocked = false
#var request_processed = false
#var dbquery_processed = false
#var response_processed = false

onready var process_bar = $KinematicBody2D/HealthBar
onready var label = $Label
onready var sprite = $KinematicBody2D/Sprite
onready var impact_area = get_node("Impact")
var projectile_impact = preload("res://Scenes/SupportScenes/ProjectileImpact.tscn")

onready var timer := Timer.new()
var time_start = 0
var time_now = 0
var timeout = 7
var is_timeout = false

var main_node
var timeout_texture = preload("res://Assets/Enemies/barrelBlack_top.png")

func _ready():
	process_bar.max_value = 100
	process_bar.value = process
	add_to_group("phoneclients")
	
	time_start = OS.get_unix_time()
	add_child(timer)
	timer.connect("timeout", self, "_on_Timer_timeout")
	timer.set_wait_time(1.0)
	timer.set_one_shot(false) # Make sure it loops
	# TODO START TIMER WHEN ITS IDLING IN WITHIN RANGE OF COMPONENT
	
func _on_Timer_timeout():
	time_now = OS.get_unix_time()
	var time_elapsed = time_now - time_start - 1
	#print(timeout-time_elapsed, " for ", main_node.name)
	label.text = str(timeout-time_elapsed)
	print("blocked ", name, " ", waiting, firewall_blocked)
	if timeout-time_elapsed == 0:
		is_timeout = true
		sprite.set_texture(timeout_texture)
		timer.stop()
		time_start = OS.get_unix_time()
	
func _physics_process(delta):
	var phoneclients = get_tree().get_nodes_in_group("phoneclients")
	
	# Checks collision between phones
	for i in range(phoneclients.size()):
		if phoneclients[i].position == position:
			main_node = phoneclients[i]
			if i == 0: waiting = false
				
			var distance = phoneclients[i].position.distance_to(phoneclients[i-1].position)
			if distance < 40 and distance != 0 and !data_write and !phoneclients[i-1].reverse: 
				waiting = true
			else:
				waiting = false
	
#	if unit_offset > 0.4 and !request_processed:
#		print("REQUEST NOT PROCESSED")
#		label.text = "REQUEST NOT PROCESSED"
#		return
#
#	if unit_offset > 0.6 and !dbquery_processed:
#		print("DB NOT PROCESSED")
#		label.text = "DB NOT PROCESSED"
#		return
	
#	if unit_offset == 1.0 and process != 100:
#		print("BASE DAMAGED")
#		emit_signal("base_damage", base_damage)
#		queue_free()
	#print(self.name, " is waiting? ", waiting)
	#print(self.name, " is firewalblocked? ", firewall_blocked)
	if !firewall_blocked and !waiting:
		timer.stop()
		time_start = OS.get_unix_time()
		label.text = "Travelling"
		move(delta)
		
	if (waiting or firewall_blocked) and timer.is_stopped() and !is_timeout:
		#print("starting timer for ", main_node.name)
		timer.start()
		
	# if timeout then change texture and emit signal
	
func move(delta):
	set_offset(get_offset() + speed * delta)

func on_hit(damage, component, max_process):
	impact()
	process += damage
	if component == "WebServerT1":
		label.text = "Processing request"
	
	if process < 100:
		print("Setting blocked to tru form on hit")
		
	#print(process, " last hit by ", component, " and process is ", max_process)
	process_bar.value = process
#	
#	if process == max_process:
#		print("process_complete now resetting")
#		label.text = "Done Processing"
#		hit_blocked = false
#		if component == "WebServerT1":
#			request_processed = true
#		elif component == "DatabaseT1":
#			dbquery_processed = true
#		yield(get_tree().create_timer(0.5), "timeout")
#		label.text = "Travelling"
		

func impact():
	randomize()
	var x_pos = randi() % 31
	randomize()
	var y_pos = randi() % 31
	var impact_location = Vector2(x_pos, y_pos)
	var new_impact = projectile_impact.instance()
	new_impact.position = impact_location
	impact_area.add_child(new_impact)

func on_destroy():
	get_node("KinematicBody2D").queue_free()
	yield(get_tree().create_timer(0.2), "timeout")
	self.queue_free()
