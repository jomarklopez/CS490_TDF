extends Node2D

var type
var category
var enemy_array = []
var built = false
var enemy
var ready = true
var process_complete = true
onready var label = $Label

func _ready():
	if built:
		self.get_node("Range/CollisionShape2D").get_shape().radius = 0.5 * GameData.component_data[type]["range"]

func _physics_process(delta):
	if enemy_array.size() != 0 and built:
		select_enemy()
		#if not get_node("AnimationPlayer").is_playing():
		#	turn()
		if ready and enemy.process < 100:
			if type == "WebServerT1" and !enemy.request_processed:
				fire(30)
			elif type == "DatabaseT1" and !enemy.dbquery_processed:
				fire(60)
	else:
		enemy = null
	
func turn():
	get_node("Turret").look_at(enemy.position)

func select_enemy():
	var enemy_progress_array = []
	for i in enemy_array:
		enemy_progress_array.append(i.offset)
		# track enemy closest to end of path
		var max_offset = enemy_progress_array.max()
		var enemy_index = enemy_progress_array.find(max_offset)
		enemy = enemy_array[enemy_index]

func fire(max_process):
	label.text = "pew"
	ready = false
	#if category == "Projectile":
	#	fire_gun()
	#elif category == "Missile":
	#	fire_missile()
		
	enemy.on_hit(GameData.component_data[type]["damage"], type, max_process)
	yield(get_tree().create_timer(GameData.component_data[type]["rof"]), "timeout")
	label.text = ""
	ready = true

func fire_gun():
	get_node("AnimationPlayer").play("Fire")

func fire_missile():
	pass
	
func _on_Range_body_entered(body):
	enemy_array.append(body.get_parent())

func _on_Range_body_exited(body):
	enemy_array.erase(body.get_parent())

