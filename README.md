# JellyMesh
Funny module i made to turn any mesh into soft body 

# Note
Performance is pretty bad on this module cause editable meshes are pretty heavy right now due to them being a beta feature + roblox's built in physics constraints are slow in general.
I tried to optimize it a bit but it does lag pretty bad with meshes with vertex counts higher than 1000~.

## API

JellyMesh.Generate(Size : number,StartPosition : Vector3, Mesh : MeshPart)
