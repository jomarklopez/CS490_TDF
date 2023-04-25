extends Node2D

signal game_finished(result)

var map_node:Node2D

var build_mode = false
var connect_mode = false
var build_valid = false
var build_tile
var build_location
var build_type
var tower_type

var connect_linepreview:Line2D
var current_wave = 0
var enemies_in_wave = 0
var pointer_normal = load("res://Assets/UI/cursor_pointer3D_shadow.png")
var pointer_connect = load("res://Assets/UI/blue_boxTick.png")

var base_health = 100

var component_hovered:TextureButton
var tooltip_label:Label
var tooltip_bg:ColorRect
var _last_mouse_position

enum PopupIds {
	popup_upcomp,
	popup_destcomp
}

var paths = []

var components_group
onready var _pm = $UI/HUD/PopupMenu
var componentsmenu = PopupMenu.new()
var components = ["Load Balancer", "Server"]

func _ready():
	map_node = get_node("Map1") ## Turn this into variable based on selected map
	map_node.get_node("Components").get_node("FileGreen").add_to_group("components_group")
	components_group = get_tree().get_nodes_in_group("components_group")
	
	var	path_node:Path2D = map_node.get_node("InitPath")
	var	line_node:Line2D = map_node.get_node("Line2D")
	line_node.points = path_node.curve.get_baked_points()
	line_node.set_default_color(Color("ffffff"))
	
	for i in get_tree().get_nodes_in_group("build_buttons"):
		i.connect("pressed", self, "initiate_build_mode", [i.get_name()])
	
	componentsmenu.set_name("SubmenuComponents")
	for comp in components: 
		componentsmenu.add_item(comp)
	_pm.add_child(componentsmenu)
	_pm.add_submenu_item("Add New Components ", "SubmenuComponents")
	_pm.add_item("Connect Component", PopupIds.popup_upcomp)

	_pm.connect("id_pressed", self, "_on_PopupMenu_id_pressed")
	componentsmenu.connect("id_pressed", self, "_on_ComponentsMenu_id_pressed")
	# Create a Line2D node
	connect_linepreview = Line2D.new()
	connect_linepreview.width = 10
	connect_linepreview.default_color = (Color("ffffff"))
	connect_linepreview.z_index = 1
	get_tree().get_root().add_child(connect_linepreview)
	
func _input(event):
	if event is InputEventMouseMotion:
		_last_mouse_position = get_viewport().get_mouse_position()
		
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT and connect_mode == true:
		cancel_connect_mode()
		_pm.hide()
	elif event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT:
		print("Initiating Connect mode")
		_last_mouse_position = get_global_mouse_position()
		connect_mode = true
		initiate_connect_mode()
		# right click menu
#		_last_mouse_position = get_global_mouse_position()
#		_pm.popup(Rect2(_last_mouse_position.x, _last_mouse_position.y, _pm.rect_size.x, _pm.rect_size.y))
		
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT and build_mode == true:
		cancel_build_mode()
		_pm.hide()
		
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT and build_mode == true:
		verify_and_build()
		cancel_build_mode()
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT and connect_mode == true:
		_last_mouse_position = get_global_mouse_position()
		verify_and_connect()
	
		

func _unhandled_input(event):
	if not event is InputEventMouseButton:
		return
	if event.button_index != BUTTON_LEFT or not event.pressed:
		return

func _on_PopupMenu_id_pressed(id):
	match id:
		PopupIds.popup_upcomp:
			print("Connect Component pressed")
			_last_mouse_position = get_global_mouse_position()
			connect_mode = true
			initiate_connect_mode()

func _on_ComponentsMenu_id_pressed(id):
	if build_mode == false:
		initiate_build_mode(components[id].replace(" ", ""))


	

func _process(delta):
	if build_mode:
		update_tower_preview()
	if connect_source and connect_linepreview:
		# Update the Line2D node
		connect_linepreview.points = [connect_source.global_position, _last_mouse_position]
		if connect_source.name == "FileGreen":
			connect_linepreview.default_color = (Color("7dbaf2"))
	
	if component_hovered:
		tooltip_label.rect_position = get_viewport().get_mouse_position() + Vector2(20, 30)	
		tooltip_bg.rect_size = tooltip_label.get_minimum_size() + Vector2(10, 10) # Add some padding to the size of the container
		tooltip_bg.rect_position = tooltip_label.get_position() - Vector2(5, 2.5) # Position the container behind the label
	
	components_group = get_tree().get_nodes_in_group("components_group")
##
##	Wave Functions
##
func start_next_wave():
	var wave_data = retrieve_wave_data()
	yield(get_tree().create_timer(0.2), "timeout") ## padding between waves to they don't start instantly 
	spawn_enemies(wave_data)
	
func retrieve_wave_data():
	var rng = RandomNumberGenerator.new()
	var wave_data = []
	for i in range(5):
		wave_data.append(["PhoneClient", rng.randf_range(0.10, 0.80)])

	current_wave += 1
	enemies_in_wave = wave_data.size()
	return wave_data
	
func spawn_enemies(wave_data):
	for enemy_data in wave_data:
		var new_enemy = load("res://Scenes/Enemies/" + enemy_data[0] + ".tscn").instance()
		new_enemy.connect("base_damage", self, 'on_base_damage')
		map_node.get_node("InitPath").add_child(new_enemy, true) 
		new_enemy.set_z_index(2)
		yield(get_tree().create_timer(enemy_data[1]), "timeout")

##
##	Building Functions
##
func initiate_build_mode(type):
	if build_mode:
		cancel_build_mode()
	tower_type = type
	build_type = type + "T1"
	build_mode = true
	get_node("UI").set_tower_preview(build_type, get_global_mouse_position())

func update_tower_preview():
	var mouse_position = get_global_mouse_position()
	# checks what tile is loaded in the tower exclusion map node
	var current_tile = map_node.get_node("Props").world_to_map(mouse_position)
	var tile_position = map_node.get_node("Props").map_to_world(current_tile)
	
	if map_node.get_node("Props").get_cellv(current_tile) == -1: 
		get_node("UI").update_tower_preview(tile_position,"ad54ff3c")
		build_valid = true
		build_location = tile_position
		build_tile = current_tile
	else:
		get_node("UI").update_tower_preview(tile_position, "adff4545")
		build_valid = false

func cancel_build_mode():
	build_mode = false
	build_valid = false
	get_node("UI/TowerPreview").free()
	
	
func verify_and_build():
	if build_valid:
		## Test to verify player has enough cash
		var new_tower = load( "res://Scenes/Components/" + build_type + ".tscn").instance()
		new_tower.position = build_location
		new_tower.built = true
		new_tower.type = build_type
		new_tower.category = GameData.component_data[build_type]["category"]
		new_tower.add_to_group(tower_type)
		print(" added ", tower_type, " to group. Total built: ", get_tree().get_nodes_in_group(tower_type).size()+1)
		new_tower.add_to_group("components_group")
		map_node.get_node("Components").add_child(new_tower, true) 
		map_node.get_node("Props").set_cellv(build_tile, 5)
		## deduct cash 
		## update cash label

##
##	CONNECT FUNCTIONS
##

func initiate_connect_mode():
	Input.set_custom_mouse_cursor(pointer_connect, Input.CURSOR_ARROW, Vector2(18,18))

var connect_source:Node2D
var connect_destination:Node2D
func verify_and_connect():
	# collect two points with 2 left clicks
	# first left click on source
	var closest_component:Node2D
	var min_component = 999999
	for i in range(components_group.size()):
		var distance = _last_mouse_position.distance_to(components_group[i].position)
		if distance < min_component:
			min_component = distance
			if distance < 50:
				closest_component = components_group[i]

	print("clicked on ", closest_component)
	if not connect_source:
		connect_source = closest_component
		# build line
	else:
		connect_destination = closest_component
		build_path2d(connect_source, connect_destination)
		build_path2d(connect_destination, connect_source)
		cancel_connect_mode()
	# second left click for destination and then verify connection
	
	
func build_path2d(source:Node2D, destination:Node2D):
	if destination == null:
		cancel_connect_mode()
		return
		
	# Create a new Path2D node
	var new_path = Path2D.new()
	var path_name:String = source.name + "_" + destination.name + "_Path2D"
	new_path.set_name(path_name)
	
	var new_line = Line2D.new()
	var line_name:String = source.name + "_" + destination.name + "_Line2D"
	new_line.set_name(line_name)
	new_line.set_default_color(Color("ffffff"))
	
	# Add the two points to the Path2D node
	new_path.curve.add_point(source.position)
	new_path.curve.add_point(destination.position)
	# Set the points of the Line2D node to the baked points of the Path2D node
	new_line.points = new_path.curve.get_baked_points()

	# Add the Line2D node to the scene
	map_node.add_child(new_line)
	new_line.set_z_index(1)
	# Add the Path2D node to the scene
	map_node.add_child(new_path)
	
	print("Connected ", source.name, " to ", destination.name)
	paths.append([source.name, destination.name])
	print("Existing paths are ")
	for i in range(len(paths)):
		print("SOURCE:", paths[i][0], " DESTINATION: ",  paths[i][1])
	
	
func cancel_connect_mode():
	connect_mode = false
	connect_source = null
	connect_destination = null
	Input.set_custom_mouse_cursor(pointer_normal)
	# Remove the Line2D node
	if connect_linepreview:
		connect_linepreview.points = []

func on_base_damage(damage):
	base_health -= damage
	if base_health <= 0:
		emit_signal("game_finished", false)
	else:
		get_node("UI").update_health_bar(base_health)

func show_tooltip(text):
	component_hovered = get_node("UI/HUD/BuildBar/WebServer")
	tooltip_label = get_node("UI/HUD/Tooltip/Label")
	tooltip_label.text = text
	tooltip_label.visible = true
	tooltip_label.rect_position = Vector2(0, 0)
	tooltip_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tooltip_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	tooltip_bg = get_node("UI/HUD/Tooltip/ColorRect")
	tooltip_bg.visible = true
	
func hide_tooltip():
	component_hovered = null
	tooltip_label.visible = false
	tooltip_bg.visible = false

func _on_WebServer_mouse_entered():
	show_tooltip("Load Balancer - Directs traffic to available servers")
	
func _on_WebServer_mouse_exited():
	hide_tooltip()


func _on_Database_mouse_entered():
	show_tooltip("Server - Directs traffic to files/database")


func _on_Database_mouse_exited():
	hide_tooltip()
