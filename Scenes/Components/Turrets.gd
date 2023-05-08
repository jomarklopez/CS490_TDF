extends Node2D

var type
var enemy_array = []
var built = false
var enemy
var ready = true
var dragging = false
var map_node:Node2D

var queue:Array
onready var queue_container = get_node("QueueContainer")
const QUEUE_CAPACITY = 3
var blocked_enemies:Array
onready var label = $Label

onready var timer := Timer.new()
var time_start = 0
var time_now = 0
var time_processed = 1
var is_timeout = false
var load_balancer_idx = 0

var destination_connected = false
var source_pathname
var destination_pathname
var loadbalancer_connection = false

func _ready():
	if name == "FileGreen":
		built = true
		type = "FileGreen"
		destination_connected = true
	elif name == "Gateway":
		built = true
		type = "Gateway"
		
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
		if ready and queue.size() < QUEUE_CAPACITY:
			enqueue_enemy()
	else:
		enemy = null
	
	# dequeue build
	if queue.size() != 0 and ready and timer.is_stopped() and !is_timeout:
		time_start = OS.get_unix_time()
		timer.start()

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
	
	label.text = "Processing..."
	if time_elapsed == time_processed:
		var current_enemy = queue.pop_front()
		map_node.get_node(current_enemy[1]).add_child(current_enemy[0])
		current_enemy[0].set_offset(10)
		queue_container.remove_child(queue_container.get_child(1))
		is_timeout = true
		
		timer.stop()
		time_start = OS.get_unix_time()
		is_timeout = false
		
		
		if blocked_enemies.size() > 0:
			if queue.size() == 0:
				for e in blocked_enemies:
					e.blocked = false
				blocked_enemies = []
			else:
				var blocked_enemy = blocked_enemies.pop_front()
				blocked_enemy.blocked = false
		
		label.text = ""
	ready = true
func enqueue_enemy():
	ready = false
	if type == "Gateway" and destination_pathname:
		if enemy.reverse and !enemy.gateway_backward_prop:
			map_node.get_node(path_builder(enemy.source_component, "Gateway")).remove_child(enemy)
			map_node.get_node("EndPath").add_child(enemy)
			enemy.set_offset(0)
			enemy.gateway_backward_prop = true
		else:
			map_node.get_node("InitPath").remove_child(enemy)
			map_node.get_node(destination_pathname).add_child(enemy)
			enemy.set_offset(40)
	elif type == "WebServerT1":
		var servers_size = get_tree().get_nodes_in_group("Database").size()
		if !enemy.lb_forward_prop:
			label.text = "Directing request to a server..."
			map_node.get_node(path_builder(enemy.source_component, "WebServerT1")).remove_child(enemy)
			if load_balancer_idx == servers_size:
				load_balancer_idx = 1
			else:
				load_balancer_idx += 1
			var db_num = load_balancer_idx
			var lb_path:String = path_builder(name, "DatabaseT" + str(db_num))
			if map_node.get_node(lb_path) == null:
				return
				
			map_node.get_node(lb_path).add_child(enemy)
			enemy.lb_forward_prop = true
			enemy.blocked = false
			enemy.set_offset(0)
			
		elif enemy.reverse and !enemy.lb_backward_prop:
			label.text = "Sending back to client..."
			map_node.get_node(path_builder(enemy.source_component, name)).remove_child(enemy)
			map_node.get_node(path_builder(name, "Gateway")).add_child(enemy)
			enemy.lb_backward_prop = true
			enemy.blocked = false
			enemy.set_offset(0)
	elif type == "DatabaseT1":
		if !enemy.server_forward_prop:
			map_node.get_node(path_builder(enemy.source_component, name)).remove_child(enemy)
			
			var queue_nodeview = queue_container.get_node("QueuedEnemy").duplicate()
			queue_container.add_child(queue_nodeview)
			queue_nodeview.visible = true
			
			enemy.server_forward_prop = true
			queue.append([enemy, path_builder(name, "FileGreen")])
		elif enemy.reverse and !enemy.server_backward_prop:
			label.text = "Sending back request..."
			
			map_node.get_node(path_builder(enemy.source_component, name)).remove_child(enemy)
			
			var queue_nodeview = queue_container.get_node("QueuedEnemy").duplicate()
			queue_container.add_child(queue_nodeview)
			queue_nodeview.visible = true
			
			enemy.server_backward_prop = true
			if loadbalancer_connection:
				queue.append([enemy, path_builder(name, "WebServerT1")])
			else:
				queue.append([enemy, path_builder(name, "Gateway")])
			
	elif type == "FileGreen":
		if enemy.data_read_en and !enemy.data_read:
			label.text = "File read success"
			
			map_node.get_node(path_builder(enemy.source_component, "FileGreen")).remove_child(enemy)
			map_node.get_node(path_builder("FileGreen", enemy.source_component)).add_child(enemy)
			
			enemy.data_read = true
			enemy.reverse = true
			enemy.set_offset(0)
		elif !enemy.data_read_en:
			label.text = "File write success"
			enemy.data_write = true
	
	enemy.source_component = name
	ready = true

func path_builder(source, destination):
	return source + "_" + destination + "_Path2D"
	
func _on_Range_body_entered(body):
	enemy_array.append(body.get_parent())

func _on_Range_body_exited(body):
	enemy_array.erase(body.get_parent())

func _on_Edges_body_entered(body):
	if queue.size() >= QUEUE_CAPACITY:
		blocked_enemies.append(body.get_parent())
		body.get_parent().blocked = true
