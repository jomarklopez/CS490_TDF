extends Node2D


enum PopupIds {
	SHOW_LAST_MOUSE_POSITION = 100,
	SAY_HI
}

var _last_mouse_position

onready var _pm = $PopupMenu
#var componentsmenu = PopupMenu.new()

func _ready():

	#componentsmenu.set_name("SubmenuComponents")
	#componentsmenu.add_item("Gateway")
	#_pm.add_child(componentsmenu)
	#_pm.add_submenu_item("Add New Components ", "SubmenuComponents")
	_pm.add_item("show last mouse position", PopupIds.SHOW_LAST_MOUSE_POSITION)
	_pm.add_item("say hi", PopupIds.SAY_HI)
	
	_pm.connect("id_pressed", self, "_on_PopupMenu_id_pressed")
	_pm.connect("index_pressed", self, "_on_PopupMenu_index_pressed")
	#componentsmenu.connect("id_pressed", self, "_on_ComponentsMenu_id_pressed")

func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT:
		_last_mouse_position = get_global_mouse_position()
		_pm.popup(Rect2(_last_mouse_position.x, _last_mouse_position.y, _pm.rect_size.x, _pm.rect_size.y))
		
func _on_PopupMenu_id_pressed(id):
	print_debug(id)


func _on_PopupMenu_index_pressed(index):
	print_debug(index)
