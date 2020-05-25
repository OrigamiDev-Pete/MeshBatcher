tool
extends Spatial

export var batch_at_runtime : bool = true

export var _transforms : Array = []
export var _batchedmmi : NodePath
export var _collision_ref : NodePath


func _ready() -> void:
	if Engine.editor_hint:
		return
	else:
		if batch_at_runtime:
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
				reallocate_collision(mesh)
			
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
			reallocate_collision(mesh)
		
		mmi.queue_free()
		print("Unbatched " + str(mmi) + " into " + str(mm.instance_count) + " instances.")
	_transforms.clear()
	get_node(_collision_ref).queue_free()
	_collision_ref = ""
	_batchedmmi = ""


func batch_with_collision(staticbody : StaticBody, parent : MeshInstance) -> void:
	if !has_node(_collision_ref):
		var container := Spatial.new()
		container.name = "Collisions"
		add_child(container)
		if Engine.editor_hint:
			container.set_owner(get_tree().get_edited_scene_root())
		_collision_ref = get_path_to(container)
		
	parent.remove_child(staticbody)
	get_node(_collision_ref).add_child(staticbody)
	staticbody.transform = parent.transform
	
	if Engine.editor_hint:
		staticbody.set_owner(get_tree().get_edited_scene_root())
		staticbody.get_child(0).set_owner(get_tree().get_edited_scene_root())


func reallocate_collision(mesh : MeshInstance):
	var staticbody := get_node(_collision_ref).get_child(0)
	get_node(_collision_ref).remove_child(staticbody)
	mesh.add_child(staticbody)
	staticbody.transform = Transform.IDENTITY
	staticbody.set_owner(get_tree().get_edited_scene_root())
	staticbody.get_child(0).set_owner(get_tree().get_edited_scene_root())
	


func verify_nodes(nodes : Array) -> bool:
	for i in nodes:
		if i is MeshInstance:
			if i.get_child(0) is StaticBody:
				batch_with_collision(i.get_child(0), i)
			continue
		else:
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
		if children[i] is Spatial:
			continue
		else:
			return "Only MeshInstances or MultiMeshInstances can be a child of this node.\n If you want to batch collisions be sure to make the StaticBody a child of the MeshInstance."
	return ""
