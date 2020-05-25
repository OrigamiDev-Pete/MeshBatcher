# MeshBatcher
 A tool for batching MeshInstance nodes into a single MultiMeshInstance to improve performance.

## The power of MultiMesh meets the ease of single instances
- Provides a new MeshBatcher node for easy implimentation. Simply used the node as a container for MeshInstances.
- Place and edit individual MeshInstances for granular control
- Options to batch and unbatch MultiMeshInstances in editor
- MeshInstances inside the MeshBatcher node can automatically convert to a MultiMeshInstance at runtime so there's no need to batch and unbatch while you're working (unless you want to)!

## Roadmap
- Add collision meshes for static bodies
