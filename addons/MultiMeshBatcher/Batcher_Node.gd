tool
extends Spatial


func batch():
	var meshes := get_children()
	var mesh_transforms : Array = []
	for i in meshes:
		if i is MeshInstance:
			continue
		else:
			# Create a popup
			print("Only MeshInstances can be batched.")
		
		mesh_transforms.append(i.transform)
		i.queue_free()
	
	var mm = MultiMesh.new()
	var mmi = MultiMeshInstance.new()
	mmi.name = "BatchedMesh"
	add_child(mmi)
	mmi.set_owner(get_tree().get_edited_scene_root())
	
	mmi.multimesh = mm
	mm.mesh = meshes[0].mesh
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = mesh_transforms.size()
	
	for i in mm.instance_count:
		mm.set_instance_transform(i, mesh_transforms[i])


func unbatch():
	pass


func _get_configuration_warning() -> String:
	var children := get_children()
	for i in children.size():
		print(children[i])
		if children[i] is MeshInstance:
			continue
		if children[i] is MultiMeshInstance:
			continue
		else:
			return "Only MeshInstances and MultiMeshInstances can be a child of this node"
	return ""
