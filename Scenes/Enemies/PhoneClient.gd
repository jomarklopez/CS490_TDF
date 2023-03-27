extends PathFollow2D

signal base_damage(damage)
var speed = 150
var process = 0
var base_damage = 21

var blocked = false
var request_processed = false
var dbquery_processed = false
var response_processed = false

onready var process_bar = $KinematicBody2D/HealthBar
onready var label = $Label
onready var impact_area = get_node("Impact")
var projectile_impact = preload("res://Scenes/SupportScenes/ProjectileImpact.tscn")

func _ready():
	process_bar.max_value = 100
	process_bar.value = process
	add_to_group("phoneclients")
	
func _physics_process(delta):
	var phoneclients = get_tree().get_nodes_in_group("phoneclients")
	# Checks collision between phones
	for i in range(phoneclients.size()):
		if phoneclients[i].position == position:
			var distance = phoneclients[i].position.distance_to(phoneclients[i-1].position)
			if distance < 40 and distance != 0: return
	
	if unit_offset > 0.4 and !request_processed:
		print("REQUEST NOT PROCESSED")
		label.text = "REQUEST NOT PROCESSED"
		return
		
	if unit_offset > 0.6 and !dbquery_processed:
		print("DB NOT PROCESSED")
		label.text = "DB NOT PROCESSED"
		return
	
	if unit_offset == 1.0 and process != 100:
		print("BASE DAMAGED")
		emit_signal("base_damage", base_damage)
		queue_free()
		
	# Checks collision with props
	if(!blocked):
		move(delta)
	
func move(delta):
	set_offset(get_offset() + speed * delta)

func on_hit(damage, component, max_process):
	impact()
	process += damage
	if component == "WebServerT1":
		label.text = "Processing request"
	
	if process < 100:
		blocked = true
		
	print(process, " last hit by ", component, " and process is ", max_process)
	process_bar.value = process
	
	if process == max_process:
		print("process_complete now resetting")
		label.text = "Done Processing"
		blocked = false
		if component == "WebServerT1":
			request_processed = true
		elif component == "DatabaseT1":
			dbquery_processed = true
		yield(get_tree().create_timer(0.5), "timeout")
		label.text = "Travelling"
		

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
