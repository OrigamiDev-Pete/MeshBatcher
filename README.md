# MeshBatcher
 A tool for batching MeshInstance nodes into a single MultiMeshInstance to improve performance.

## The power of MultiMesh meets the ease of single instances
- Provides a new MeshBatcher node for easy implimentation. Simply used the node as a container for MeshInstances.
- Place and edit individual MeshInstances for granular control
- Options to batch and unbatch MultiMeshInstances in editor
- MeshInstances inside the MeshBatcher node can automatically convert to a MultiMeshInstance at runtime so there's no need to batch and unbatch while you're working (unless you want to)!

## Version 2.0
- Huge thank you to [Yogoda](https://github.com/Yogoda) for their significant contributions to this version of MeshBatcher.
- Much of the code is refactored and now uses MultiMeshInstance as its base class to allow for a simpler and more robust implementation.
- Material Overrides are kept and propogate to all meshes within the MeshBatcher node.
- Multiple bugs and errors have been cleaned up.

## Version 1.1 - Compatible with StaticBodies
- MeshBatcher will now detect if MeshInstances have StaticBodies allowing for collisions with a MultiMeshInstance.
