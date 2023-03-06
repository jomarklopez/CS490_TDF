extends PathFollow2D

signal base_damage(damage)
var speed = 150
var hp = 1000
var base_damage = 21
onready var health_bar = $KinematicBody2D/HealthBar
onready var impact_area = get_node("Impact")
var projectile_impact = preload("res://Scenes/SupportScenes/ProjectileImpact.tscn")

func _ready():
	health_bar.max_value= hp
	health_bar.value = hp
	add_to_group("phoneclients")
	
func _physics_process(delta):
	var phoneclients = get_tree().get_nodes_in_group("phoneclients")
	for i in range(phoneclients.size()):
		if phoneclients[i].position == position:
			var distance = phoneclients[i].position.distance_to(phoneclients[i-1].position)
			if distance < 40 and distance != 0: return
				
	move(delta)
	
func move(delta):
	set_offset(get_offset() + speed * delta)

func on_hit(damage):
	impact()
	hp -= damage
	health_bar.value = hp
	if hp <= 0:
		print("u dead")

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
