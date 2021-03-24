tool
extends EditorPlugin

const MeshBatcher = preload("res://addons/MultiMeshBatcher/Batcher_Node.gd")
const Icon = preload("res://addons/MultiMeshBatcher/MultiMesh.svg")

enum Menu {BATCH, UNBATCH}

var _toolbar : HBoxContainer = null
var _node : MeshBatcher = null

func _enter_tree() -> void:
	add_custom_type("MeshBatcher", "MultiMeshInstance", MeshBatcher, Icon)
	
	# Editor UI
	_toolbar = HBoxContainer.new()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _toolbar)
	_toolbar.hide()
	
	var functions := ["Batch", "Unbatch"]
	var menu := MenuButton.new()
	menu.set_text("Batcher")
	menu.get_popup().add_item(functions[Menu.BATCH], Menu.BATCH)
	menu.get_popup().add_item(functions[Menu.UNBATCH], Menu.UNBATCH)
	menu.get_popup().connect("id_pressed", self, "_menu_item_pressed")
	_toolbar.add_child(menu)


func _exit_tree() -> void:
	_toolbar.queue_free()
	remove_custom_type("MeshBatcher")
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _toolbar)



func handles(object: Object) -> bool:
	if object is MeshBatcher:
		_node = object
		return true
	else:
		return false


func make_visible(visible: bool) -> void:
	_toolbar.set_visible(visible)


func _menu_item_pressed(id : int):
	match id:
		Menu.BATCH:
			_node.batch()
			get_editor_interface().get_inspector().refresh()
		
		Menu.UNBATCH:
			_node.unbatch()
			get_editor_interface().get_inspector().refresh()

