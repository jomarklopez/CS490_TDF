extends Node2D

var type
var category
var enemy_array = []
var built = false
var enemy
var ready = true
var process_complete = true
var server_db_connected = false

var dragging = false
var map_node:Node2D

var queue:Array
onready var queue_container = get_node("QueueContainer")
onready var label = $Label
onready var timer := Timer.new()
var time_start = 0
var time_now = 0
var time_processed = 2
var is_timeout = false

func _ready():
	if name == "FileGreen":
		built = true
		type = "FileGreen"
		
	if built:
		map_node = get_parent().get_parent()
		self.get_node("Range/CollisionShape2D").get_shape().radius = 0.5 * GameData.component_data[type]["range"]
		
	time_start = OS.get_unix_time()
	add_child(timer)
	timer.connect("timeout", self, "_on_Timer_timeout")
	timer.set_wait_time(1.0)
	timer.set_one_shot(false) # Make sure it loops

func _physics_process(delta):
	# waiting area build
	if enemy_array.size() != 0 and built:
		select_enemy()
		if ready and queue.size() < 3:
			enqueue_enemy()
	else:
		enemy = null
	
	# dequeue build
	if queue.size() != 0 and ready and timer.is_stopped() and !is_timeout:
		print("timer start")
		time_start = OS.get_unix_time()
		timer.start()
	
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
		
func _on_Timer_timeout():
	ready = false
	
	time_now = OS.get_unix_time()
	var time_elapsed = time_now - time_start
	
	label.text = "Processing..." + str(time_processed-time_elapsed+1)
	
	#print("Processing ", current_enemy[0].name, " time remaining", time_elapsed)
	if time_elapsed == time_processed:
		var current_enemy = queue.pop_front()
		map_node.get_node(current_enemy[1]).add_child(current_enemy[0])
		current_enemy[0].set_offset(10)
		current_enemy[0].server_forward_prop = true
		queue_container.remove_child(queue_container.get_child(1))
		#label.text = "Released, " + current_enemy[0].name
		is_timeout = true
		
		timer.stop()
		time_start = OS.get_unix_time()
		is_timeout = false
	ready = true
	
func enqueue_enemy():
	ready = false
	#if category == "Projectile":
	#	fire_gun()
	#elif category == "Missile":
	#	fire_missile()
		
	#enemy.on_hit(GameData.component_data[type]["damage"], type, max_process)
	if type == "WebServerT1":
		if !enemy.lb_forward_prop:
			label.text = "Assigning task to a server..."
			map_node.get_node("InitPath").remove_child(enemy)
			
			# TODO Code to decide which path to transfer this request to
			# ROUND ROBIN VS LEAST CONNECTIONS
			# change db num to randomize number of db
			var db_num = randi()%get_tree().get_nodes_in_group("Database").size()+1
			print("choosing between ", str(get_tree().get_nodes_in_group("Database").size()+1), " dbs")
			var lb_path:String = "WebServerT1_DatabaseT" + str(db_num) + "_Path2D"
			map_node.get_node(lb_path).add_child(enemy)
			
			enemy.lb_forward_prop = true
			enemy.firewall_blocked = false
			enemy.set_offset(0)
		elif enemy.reverse and !enemy.lb_backward_prop:
			label.text = "Sending back to client..."
			map_node.get_node("DatabaseT1_WebServerT1_Path2D").remove_child(enemy)
			map_node.get_node("EndPath").add_child(enemy)
			enemy.lb_backward_prop = true
			enemy.firewall_blocked = false
			enemy.set_offset(0)
			
	elif type == "DatabaseT1":
		if !enemy.server_forward_prop:
			#label.text = "Processing request..."
			
			map_node.get_node("WebServerT1_DatabaseT1_Path2D").remove_child(enemy)
			
			var queue_nodeview = queue_container.get_node("QueuedEnemy").duplicate()
			queue_container.add_child(queue_nodeview)
			queue_nodeview.visible = true
			# put to queue
			#yield(get_tree().create_timer(5), "timeout")
			var path = "DatabaseT1_FileGreen_Path2D"
			queue.append([enemy, path])
		elif enemy.reverse and !enemy.server_backward_prop:
			label.text = "Sending back request..."
			map_node.get_node("FileGreen_DatabaseT1_Path2D").remove_child(enemy)
			map_node.get_node("DatabaseT1_WebServerT1_Path2D").add_child(enemy)
			enemy.set_offset(0)
			enemy.server_backward_prop = true
			
	elif type == "FileGreen":
		if enemy.data_write_en and !enemy.data_write:
			label.text = "File write success"
			map_node.get_node("DatabaseT1_FileGreen_Path2D").remove_child(enemy)
			map_node.get_node("FileGreen_DatabaseT1_Path2D").add_child(enemy)
			
			enemy.data_write = true
			enemy.reverse = true
			enemy.set_offset(0)
	ready = true

func fire_gun():
	get_node("AnimationPlayer").play("Fire")

func fire_missile():
	pass
			
func _on_Range_body_entered(body):
	enemy_array.append(body.get_parent())

func _on_Range_body_exited(body):
	enemy_array.erase(body.get_parent())
