extends CanvasLayer

onready var hp_bar = get_node("HUD/InfoBar/H/HP")
onready var hp_bar_tween = get_node("HUD/InfoBar/H/HP/Tween")
onready var money_label = get_node("HUD/InfoBar/H/Money")
onready var score_label = get_node("HUD/HBoxContainer/Label")
onready var pauseplay_button:TextureButton = get_node("HUD/GameControls/PausePlay")

func set_tower_preview(tower_type, mouse_position):
	var drag_tower = load("res://Scenes/Components/" + tower_type + ".tscn").instance()
	drag_tower.set_name("DragTower")
	drag_tower.modulate = Color("ad54ff3c")
	
#	var range_texture = Sprite.new()
#	range_texture.position = Vector2(0,0)
#	var scaling = GameData.component_data[tower_type]["range"] / 600.0
#	range_texture.scale = Vector2(scaling, scaling)
#	var texture = load("res://Assets/UI/range_overlay.png")
#	range_texture.texture = texture
#	range_texture.modulate = Color("ad54ff3c")

	var control = Control.new()
	control.add_child(drag_tower, true)
#	control.add_child(range_texture, true)
	control.rect_position = mouse_position
	control.set_name("TowerPreview")
	add_child(control, true)
	move_child(get_node("TowerPreview"), 0)

func update_tower_preview(new_position, color):
	get_node("TowerPreview").rect_position = new_position
	if get_node("TowerPreview/DragTower").modulate != Color(color):
		get_node("TowerPreview/DragTower").modulate = Color(color)
		#get_node("TowerPreview/Sprite").modulate = Color(color)

##
## Game Control Functions
##
func _on_PausePlay_pressed():
	if get_parent().build_mode:
		get_parent().cancel_build_mode()
		
	if get_tree().is_paused():
		get_tree().paused = false
	elif get_tree().get_nodes_in_group("phoneclients").size() == 0 and !get_parent().wave_start:
		print("STARTING WAVE")
		get_parent().wave_start = true
		get_parent().start_next_wave()
	else:
		get_tree().paused = true

func _on_RestartLevel_pressed():
	# TODO change to repeat level instead
	get_parent().reload_level()
	get_parent().wave_start = false
	
func update_health_bar(base_health):
	hp_bar_tween.interpolate_property(hp_bar, 'value', hp_bar.value, base_health, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	hp_bar_tween.start( )
	if base_health >= 60:
		hp_bar.set_tint_progress("4eff15") #Green 
	elif base_health <= 60 and base_health >= 25:
		hp_bar.set_tint_progress("elbe32") #0range
	else:
		hp_bar.set_tint_progress("ellele") #Red

func update_points_label(score):
	score_label.text = str(score)

func update_money_label(money):
	money_label.text = str(money)


