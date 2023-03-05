extends Node2D

signal game_finished(result)

var map_node

var build_mode = false
var build_valid = false
var build_tile
var build_location
var build_type

var current_wave = 0
var enemies_in_wave = 0

var base_health = 50

var _last_mouse_position

enum PopupIds {
	popup_upcomp,
	popup_destcomp
}

onready var _pm = $UI/HUD/PopupMenu
var componentsmenu = PopupMenu.new()

func _ready():
	map_node = get_node("Map1") ## Turn this into variable based on selected map
	
	componentsmenu.set_name("SubmenuComponents")
	componentsmenu.add_item("Gateway")
	_pm.add_child(componentsmenu)
	_pm.add_submenu_item("Add New Components ", "SubmenuComponents")
	_pm.add_item("Upgrade Component", PopupIds.popup_upcomp)
	_pm.add_item("Destroy Component", PopupIds.popup_destcomp)

	_pm.connect("id_pressed", self, "_on_PopupMenu_id_pressed")
	componentsmenu.connect("id_pressed", self, "_on_ComponentsMenu_id_pressed")

func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT:
		_last_mouse_position = get_global_mouse_position()
		_pm.popup(Rect2(_last_mouse_position.x, _last_mouse_position.y, _pm.rect_size.x, _pm.rect_size.y))
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT and build_mode == true:
		cancel_build_mode()
		_pm.hide()
		
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT and build_mode == true:
		verify_and_build()
		cancel_build_mode()

func _unhandled_input(event):
	if not event is InputEventMouseButton:
		return
	if event.button_index != BUTTON_LEFT or not event.pressed:
		return

func _on_PopupMenu_id_pressed(id):
	match id:
		PopupIds.popup_upcomp:
			print("Upgrade Component pressed")
		PopupIds.popup_destcomp:
			print("Destroy Component pressed")

func _on_ComponentsMenu_id_pressed(id):
	match id:
		PopupIds.popup_upcomp:
			if build_mode == false:
				initiate_build_mode("Gateway")
		PopupIds.popup_destcomp:
			print(id)
			
func _process(delta):
	if build_mode:
		update_tower_preview()
		
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
		wave_data.append(["PhoneClient", rng.randf_range(0.00, 1.00)])
	
	current_wave += 1
	enemies_in_wave = wave_data.size()
	return wave_data
	
func spawn_enemies(wave_data):
	for i in wave_data:
		var new_enemy = load("res://Scenes/Enemies/" + i[0] + ".tscn").instance()
		#new_enemy.connect("base_damage", self, "on_base_damage")
		map_node.get_node("Path").add_child(new_enemy, true) 
		yield(get_tree().create_timer(i[1]), "timeout")

##
##	Building Functions
##
func initiate_build_mode(tower_type):
	if build_mode:
		cancel_build_mode()
		
	build_type = tower_type + "T1"
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
		new_tower.category = GameData.tower_data[build_type]["category"]
		map_node.get_node("Components").add_child(new_tower, true) 
		map_node.get_node("Props").set_cellv(build_tile, 5)
		map_node.get_node("Path").curve.add_point(build_location)
		## deduct cash 
		## update cash label

func on_base_damage(damage):
	base_health -= damage
	if base_health <= 0:
		emit_signal("game_finished", false)
	else:
		get_node("UI").update_health_bar(base_health)

