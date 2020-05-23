tool
extends Spatial

var _batchedmmi : MultiMeshInstance = null

func batch_on_run():
	# Automatically batch meshes if they are not already batched for improved performance
	# while running the scene
	pass


func batch():
	#Check if already baked
	if _batchedmmi:
		print("Unbatch before rebatching.")
		return

	var meshes := get_children()
	var mesh_transforms : Array = []
	for i in meshes:
		if i is MeshInstance:
			continue
		else:
			# Create a popup
			print("Only MeshInstances can be batched.")
			return
	
	for i in meshes:
		mesh_transforms.append(i.transform)
		i.queue_free()
	
	var mm = MultiMesh.new()
	var mmi = MultiMeshInstance.new()
	mmi.name = "BatchedMultiMesh"
	add_child(mmi)
	mmi.set_owner(get_tree().get_edited_scene_root())
	
	mmi.multimesh = mm
	mm.mesh = meshes[0].mesh # TODO: Throw error if meshes are not the same
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = mesh_transforms.size()
	
	# Set transforms to each mesh instance
	for i in mm.instance_count:
		mm.set_instance_transform(i, mesh_transforms[i])
	_batchedmmi = mmi


func unbatch():
	if _batchedmmi == null:
		print("Nothing to unbatch.")
		return
	
	var mm : MultiMesh = _batchedmmi.multimesh
	
	# Get transforms from multimesh and set to each MeshInstance
	for i in mm.instance_count:
		var mesh := MeshInstance.new()
		mesh.mesh = mm.mesh
		mesh.transform = mm.get_instance_transform(i)
		
		add_child(mesh)
		mesh.set_owner(get_tree().get_edited_scene_root())
		
	_batchedmmi.queue_free()
	_batchedmmi = null


func _get_configuration_warning() -> String:
	var children := get_children()
	for i in children.size():
		if children[i] is MeshInstance:
			continue
		if children[i] is MultiMeshInstance:
			continue
		else:
			return "Only MeshInstances and MultiMeshInstances can be a child of this node"
	return ""
