extends PathFollow2D

signal score_modify(score)

var speed = 150
var process = 0

var blocked = false
var waiting = false
var lb_forward_prop = false
var lb_backward_prop = false
var server_forward_prop = false
var server_backward_prop = false
var gateway_backward_prop = false
var data_read_en = false
var data_read = false
var data_write = false
var reverse = false
var operation = ""
var source_component

onready var process_bar = $KinematicBody2D/HealthBar
onready var label = $Label
onready var sprite = $KinematicBody2D/Sprite
onready var impact_area = get_node("Impact")
var projectile_impact = preload("res://Scenes/SupportScenes/ProjectileImpact.tscn")

onready var timer := Timer.new()
var time_start = 0
var time_now = 0
var timeout = 3
var is_timeout = false

var main_node
var timeout_texture = preload("res://Assets/Enemies/barrelBlack_top.png")
onready var op_icon = get_node("OperationIcon")

func _ready():
	
	process_bar.max_value = 100
	process_bar.value = process
	
	time_start = OS.get_unix_time()
	add_child(timer)
	timer.connect("timeout", self, "_on_Timer_timeout")
	timer.set_wait_time(1.0)
	timer.set_one_shot(false) # Make sure it loops
	
	
	
func _on_Timer_timeout():
	time_now = OS.get_unix_time()
	var time_elapsed = time_now - time_start - 1
	#print(timeout-time_elapsed, " for ", main_node.name)
	label.text = str(timeout-time_elapsed)
	print("blocked ", name, " ", waiting, blocked)
	if timeout-time_elapsed == 0:
		is_timeout = true
		sprite.set_texture(timeout_texture)
		timer.stop()
		time_start = OS.get_unix_time()
	
func _physics_process(delta):
	
	if data_read_en:
		#operation = "READ" 
		op_icon.flip_v = true
	else:
		op_icon.flip_v = false
		#operation = "WRITE"
		
	var phoneclients = get_tree().get_nodes_in_group("phoneclients")
	
	# Checks collision between phones
	for i in range(phoneclients.size()):
		if phoneclients[i].position == position:
			main_node = phoneclients[i]
			if i == 0: 
				waiting = false
				continue
				
			var distance = phoneclients[i].position.distance_to(phoneclients[i-1].position)
			if distance < 40 and distance != 0:
				if reverse == phoneclients[i-1].reverse:
					waiting = true
			else:
				waiting = false

	if data_read and gateway_backward_prop and unit_offset == 1.0:
		on_destroy()
		remove_from_group("phoneclients")
		emit_signal("score_modify", 1)
		
	if data_write: 
		on_destroy()
		remove_from_group("phoneclients")
		emit_signal("score_modify", 1)
		
	if !blocked and !waiting:
		timer.stop()
		time_start = OS.get_unix_time()
		label.text = operation
		move(delta)
		
	if (waiting or blocked) and timer.is_stopped() and !is_timeout:
		timer.start()
	
func move(delta):
	set_offset(get_offset() + speed * delta)

func on_hit(damage, component, max_process):
	impact()
	process += damage
	if component == "WebServerT1":
		label.text = "Processing request"
	
	if process < 100:
		print("Setting blocked to tru form on hit")
		
	process_bar.value = process

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
	queue_free()
