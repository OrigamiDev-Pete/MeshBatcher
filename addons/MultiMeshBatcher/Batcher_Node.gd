tool
extends MultiMeshInstance

export var batch_at_runtime : bool = true

#uses exported variables to store data when closing editor
export var _collision_ref : NodePath
export var _scene_name : String


func _ready() -> void:
	if Engine.editor_hint:
		return
	else:
		if batch_at_runtime:
			batch()


func get_material(mesh_instance:MeshInstance) -> Material:
	
	var material = mesh_instance.material_override
	
	if not material:
		material = mesh_instance.get_surface_material(0)

	return material

func batch() -> void:
	# Automatically batch meshes if they are not already batched for improved performance
	# while running the scene
	if multimesh:
		if Engine.editor_hint:
			push_warning("Already batched")
		return
	
	var meshes := get_children()
	var mesh_transforms : Array = []
	
	if verify_nodes(meshes):
		if verify_meshes(meshes):
			
			#store mesh instance transforms and delete them
			for i in meshes:
				mesh_transforms.append(i.transform)
				i.queue_free()
			
			#create the multi-mesh instance
			multimesh = MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.mesh = meshes[0].mesh
			multimesh.instance_count = mesh_transforms.size()

			# Set transforms to each mesh instance
			for i in multimesh.instance_count:
				multimesh.set_instance_transform(i, mesh_transforms[i])
				
			#apply material (null if material is in mesh)
			material_override = get_material(meshes[0])
				
			if Engine.editor_hint:
				#store scene name if scene
				_scene_name = meshes[0].filename
				print(str(multimesh.instance_count) + " instances were batched.")

func unbatch() -> void:

	if not multimesh:
		if Engine.editor_hint:
			push_warning("Cannot unbatch, not batched!")
		return
	
	# Get transforms from multimesh and set to each MeshInstance
	for i in multimesh.instance_count:
		var mesh
		
		if _scene_name:
			mesh = load(_scene_name).instance()
		else:
			mesh = MeshInstance.new()
			mesh.mesh = multimesh.mesh
			
			#restore material
			if material_override:
				mesh.material_override = material_override
			
		mesh.transform = multimesh.get_instance_transform(i)
		
		add_child(mesh)
		mesh.set_owner(get_tree().get_edited_scene_root())
		
		if _collision_ref and not _scene_name:
			reallocate_collision(mesh)

	print(str(multimesh.instance_count) + " instances were unbatched.")
	
	if _collision_ref:
		get_node(_collision_ref).queue_free()

	multimesh = null
	_collision_ref = ""
	_scene_name = ""


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
			if i.get_child_count() > 0 and i.get_child(0) is StaticBody:
				batch_with_collision(i.get_child(0), i)
			continue
		else:
			push_error("Only MeshInstances can be batched.")
			return false
	return true


func verify_meshes(meshes : Array) -> bool:
	if meshes != []:
		var mesh_test = meshes[0].mesh
		for i in meshes:
			if i.mesh == mesh_test:
				continue
			else:
				push_error("All meshes must be the same for batching.")
				return false
		return true
	else:
		push_warning("No child meshes found! You must add mesh as children of MeshBatcher node.")
		return false


func _get_configuration_warning() -> String:
	var children := get_children()
	for i in children.size():
		if children[i] is MeshInstance:
			continue
		if children[i] is Spatial and children[i].name == "Collisions":
			continue
		else:
			return "Only MeshInstances can be a child of this node.\n If you want to batch collisions be sure to make the StaticBody a child of the MeshInstance."
	return ""
