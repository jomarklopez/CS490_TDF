extends PanelContainer

signal level_selected
var mainmenu_node 
func _ready():
	mainmenu_node = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()

func _on_LevelBox_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		mainmenu_node.queue_free()
		var game_scene = load("res://Scenes/MainScenes/GameScene.tscn").instance()
		game_scene.connect("game_finished", self, "unload_game")
		get_tree().add_child(game_scene)
		game_scene.current_lvl = 1
		emit_signal("level_selected", name)
