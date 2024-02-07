--!native
local RunS = game:GetService("RunService")
local AS = game:GetService("AssetService")

local JellyCube = {}

local Cubes = 0

local function MakeAttachment(Part : Part) : Attachment
	local Attachment = Instance.new("Attachment")
	Attachment.Parent = Part

	return Attachment
end

local function MakePrismaticConstraint(Part1: BasePart, Part2: BasePart)
	local Att1 = Instance.new("Attachment")
	Att1.Parent = Part1

	local Att2 = Instance.new("Attachment")
	Att2.Parent = Part2
	Att2.Position = (Part2.Position - Part1.Position).Unit

	local Prims = Instance.new("PrismaticConstraint") 
	Prims.Visible = false
	Prims.Attachment0 = Att1
	Prims.Attachment1 = Att2
    
	Prims.LimitsEnabled = true
	
	local DistanceBetween = (Part1.Position - Part2.Position).Magnitude
	
	Prims.UpperLimit = -DistanceBetween * 1.25
	Prims.LowerLimit = DistanceBetween * 0.25
	
	Att1.WorldCFrame = CFrame.new(Att1.WorldPosition, Att2.WorldPosition) * CFrame.Angles(0, -math.pi/2, 0)
	Att2.WorldOrientation = Att1.WorldOrientation

	Prims.Parent = Part1
end

local function MakeSpring(Part1 : Part,Part2 : Part,Stiffness,Damping)
	local DistanceBetween = (Part1.Position - Part2.Position).Magnitude
    
	local Attachment1,Attachment2 = Part1:FindFirstChildWhichIsA("Attachment"),Part2:FindFirstChildWhichIsA("Attachment")
	
	local Spring = Instance.new("SpringConstraint")
	Spring.Stiffness = Stiffness
	Spring.Attachment0 = Attachment1
	Spring.Attachment1 = Attachment2
	Spring.Damping = Damping
	Spring.FreeLength = DistanceBetween

	Spring.Parent = Part1
end

local function MakeDragDetector(Part : Part)
    local DragDetector = Instance.new("DragDetector")
	DragDetector.Parent = Part
	DragDetector.ReferenceInstance = Part
	DragDetector.ApplyAtCenterOfMass = true
	DragDetector.RunLocally = true
	
	DragDetector.MaxForce = 500
	DragDetector.MaxTorque = 300

	DragDetector.Responsiveness = 10
end

local function CalculateNormal(Vertex1 : Vector3,Vertex2 : Vector3,Vertex3 : Vector3) : Vector3
	return (Vertex2 - Vertex1):Cross(Vertex3 - Vertex1).Unit
end

local function ResizeEditableMesh(EditableMesh: EditableMesh, Scale: number)
	local Vertices = EditableMesh:GetVertices()

	for _, Vertex in Vertices do
		local Position = EditableMesh:GetPosition(Vertex)
		EditableMesh:SetPosition(Vertex, Position * Scale)
	end
end

local function GetEditableMeshSize(EditableMesh: EditableMesh) : Vector3
	local Vertices = EditableMesh:GetVertices()
	local p1 = EditableMesh:GetPosition(Vertices[1])

	local min_x, max_x = p1.X, p1.X
	local min_y, max_y = p1.Y, p1.Y
	local min_z, max_z = p1.Z, p1.Z

	for _, Vertex in Vertices do
		local Position = EditableMesh:GetPosition(Vertex)

		min_x, max_x = math.min(min_x, Position.X), math.max(max_x, Position.X)
		min_y, max_y = math.min(min_y, Position.Y), math.max(max_y, Position.Y)
		min_z, max_z = math.min(min_z, Position.Z), math.max(max_x, Position.Z)
	end

	return Vector3.new(
		max_x - min_x,
		max_y - min_y,
		max_z - min_z
	)
end

function JellyCube.Generate(Size : number,StartPosition : Vector3,Mesh : MeshPart) : MeshPart
	local newMeshPart = Instance.new("MeshPart")
   	
	if Mesh.TextureID ~= "" then
		local NewTexture = AS:CreateEditableImageAsync(Mesh.TextureID)
		NewTexture.Parent = newMeshPart
	end
	
	local newEditableMesh : EditableMesh = AS:CreateEditableMeshFromPartAsync(Mesh)
	newEditableMesh.Parent = newMeshPart
	
	print(Mesh.Size.Magnitude)
	
	local DefaultMeshSize = GetEditableMeshSize(newEditableMesh)
		
	if DefaultMeshSize.Magnitude < 10 then
		ResizeEditableMesh(newEditableMesh,10 / DefaultMeshSize.Magnitude)
	end
		
	local Model = Instance.new("Model")
		
	newMeshPart.Parent = workspace
	newMeshPart.Name = tostring(Cubes)
	
	Cubes += 1
	
	Model.Name = "Jelly "..Mesh.Name..Cubes
	
	newMeshPart.Size = Vector3.one
	newMeshPart.Anchored = true
	newMeshPart.Color = Color3.fromRGB(10, 255, 10)
    	
	local MeshVertices = newEditableMesh:GetVertices()
    
	local MiddlePart = Instance.new("Part")
	MiddlePart.Parent = Model
	MiddlePart.Position = Mesh.Position
	MiddlePart.Size = Vector3.one
	MiddlePart.Anchored = false
	MiddlePart.Transparency = 1

    MakeAttachment(MiddlePart)
	
	Model.PrimaryPart = MiddlePart
	
	local VertexToPart = {}
	local PositionToPart = {}
		
	for i = 1, #MeshVertices do
		local Vertex = MeshVertices[i]
		local Position = newEditableMesh:GetPosition(Vertex)
		
		if PositionToPart[Position] then
			VertexToPart[Vertex] = PositionToPart[Position]
			continue
		end
		
		local Part = Instance.new("Part")
		Part.Size = Vector3.one  / 5
		Part.Position = (Position + MiddlePart.Position)
		Part.Transparency = 1
		Part.Parent = Model
		
		--Part.Anchored = true
        
		local Distance = (Position - MiddlePart.Position).Magnitude
		
		local PartMass = Part:GetMass()
		
		MakePrismaticConstraint(MiddlePart, Part)
		MakeSpring(MiddlePart, Part,5000 * PartMass,1 * PartMass)
		MakeDragDetector(Part)

		VertexToPart[Vertex] = Part
		PositionToPart[Position] = Part
	end
	
	Model.Parent = workspace
	Model:PivotTo(CFrame.new(StartPosition))
	Model:ScaleTo(Size)
		
	RunS.Heartbeat:Connect(function()
		for VertexId, Part in VertexToPart do
			newEditableMesh:SetPosition(VertexId, Part.Position)
		end
	end)

	
	return newMeshPart
end

return JellyCube
