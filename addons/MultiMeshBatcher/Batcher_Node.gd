tool
extends Spatial

export var batch_at_runtime : bool = true

export var _transforms : Array = []
export var _batchedmmi : NodePath


func _ready() -> void:
	if Engine.editor_hint:
		return
	else:
		batch_on_run()

func batch_on_run() -> void:
	# Automatically batch meshes if they are not already batched for improved performance
	# while running the scene
	if _batchedmmi:
		return
	
	var meshes := get_children()
	var mesh_transforms : Array = []
	if verify_nodes(meshes):
		if verify_meshes(meshes):
			
			for i in meshes:
				mesh_transforms.append(i.transform)
				i.queue_free()
			
			var mm = MultiMesh.new()
			var mmi = MultiMeshInstance.new()
			mmi.name = "BatchedMultiMesh"
			add_child(mmi)
			
			mmi.multimesh = mm
			mm.mesh = meshes[0].mesh
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.instance_count = mesh_transforms.size()
			
			# Set transforms to each mesh instance
			for i in mm.instance_count:
				mm.set_instance_transform(i, mesh_transforms[i])


func batch() -> void:
	#Check if already baked
	if _batchedmmi:
		push_warning("Unbatch before rebatching.")
		return
	
	var meshes := get_children()
	var mesh_transforms : Array = []
	if verify_nodes(meshes):
		if verify_meshes(meshes):
			
			for i in meshes:
				mesh_transforms.append(i.transform)
				i.queue_free()
			
			var mm = MultiMesh.new()
			var mmi = MultiMeshInstance.new()
			mmi.name = "BatchedMultiMesh"
			add_child(mmi)
			mmi.set_owner(get_tree().get_edited_scene_root())
			
			mmi.multimesh = mm
			mm.mesh = meshes[0].mesh
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.instance_count = mesh_transforms.size()
			
			# Set transforms to each mesh instance
			for i in mm.instance_count:
				mm.set_instance_transform(i, mesh_transforms[i])
			_batchedmmi = mmi.get_path()
			_transforms = mesh_transforms # For faster unbatching
			print(str(mm.instance_count) + " instances were batched.")


func unbatch() -> void:
	if _batchedmmi == "":
#		push_warning("Nothing to unbatch.")
#		return
		
		#Check if there is a multimesh to unbatch
		var mmi := get_child(0)
		if mmi is MultiMeshInstance:
			var mm : MultiMesh = mmi.multimesh
			
			# Get transforms from multimesh and set to each MeshInstance
			for i in mm.instance_count:
				var mesh := MeshInstance.new()
				mesh.mesh = mm.mesh
				mesh.transform = mm.get_instance_transform(i)
				
				add_child(mesh)
				mesh.set_owner(get_tree().get_edited_scene_root())
			
			mmi.queue_free()
			print("Unbatched " + str(mmi) + " into " + str(mm.instance_count) + " instances.")
			
		else:
			push_warning("Nothing to unbatch. Make sure a MultiMeshInstance Node is the first child of the MeshBatcher")
			return
	else:
		var mmi = get_node(_batchedmmi)
		var mm : MultiMesh = mmi.multimesh
		
		# Get transforms from multimesh and set to each MeshInstance
		for i in mm.instance_count:
			var mesh := MeshInstance.new()
			mesh.mesh = mm.mesh
			mesh.transform = _transforms[i]
			
			add_child(mesh)
			mesh.set_owner(get_tree().get_edited_scene_root())
		
		mmi.queue_free()
		print("Unbatched " + str(mmi) + " into " + str(mm.instance_count) + " instances.")
	_transforms.clear()
	_batchedmmi = ""


func verify_nodes(nodes : Array) -> bool:
	for i in nodes:
		if i is MeshInstance:
			continue
		else:
			# TODO: Create a popup
			push_error("Only MeshInstances can be batched.")
			return false
	return true


func verify_meshes(meshes : Array) -> bool:
	var mesh_test = meshes[0].mesh
	for i in meshes:
		if i.mesh == mesh_test:
			continue
		else:
			push_error("All meshes must be the same for batching.")
			return false
	return true


func _get_configuration_warning() -> String:
	var children := get_children()
	for i in children.size():
		if children[i] is MeshInstance:
			continue
		if children[i] is MultiMeshInstance:
			continue
		else:
			return "Only MeshInstances and MultiMeshInstances can be a child of this node."
	return ""


func _get_property_list() -> Array:
	var properties = []
	properties.append({
		name = "Data",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	return properties
