local Version = "Alpha v2.1.3"
if _G.Version ~= Version then
	warn("Wrong version, newest is: " .. Version)
	return
end

warn("Running test script. Version: " .. Version)

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = Player:GetMouse()
local CamlockEnabled, TriggerbotEnabled = false, false
local Target = nil
local CrewPath, KOPath
local TriggerbotTime = os.clock()
local TriggerbotHitboxDetected = false
local TriggerbotCooldown = false
local Tabbed = true

local function GetPath(Interchangeable : Instance, Names : {string}) : string
	local Found_Object = nil

	for _, Object in Interchangeable:GetDescendants() do
		if Object:IsA("BoolValue") or Object:IsA("IntValue") or Object:IsA("StringValue") then
			for _, Name in Names do
				if string.find(string.lower(Object.Name), string.lower(Name)) then
					Found_Object = Object
					break
				end
			end
			if Found_Object then
				break
			end
		end
	end

	if not Found_Object then
		return nil
	end

	local Path_Parts = {}
	local Current = Found_Object

	while Current and Current ~= game do
		if Current == Interchangeable then
			table.insert(Path_Parts, 1, "[Interchangeable]")
		else
			table.insert(Path_Parts, 1, Current.Name)
		end
		Current = Current.Parent
	end

	if Current == game then
		table.insert(Path_Parts, 1, "game")
	end

	return table.concat(Path_Parts, "__")
end

local function UsePath(Path : string, Name : string) : Instance
	if not Path or Path == "" then
		return nil
	end

	local Path_Parts = {}
	for Part in string.gmatch(Path, "[^__]+") do
		table.insert(Path_Parts, Part)
	end

	local Current = game

	for _, Object in ipairs(Path_Parts) do
		if Object == "game" then
			Current = game
		elseif Object == "[Interchangeable]" then
			Current = Current:FindFirstChild(Name)
		elseif Current then
			Current = Current:FindFirstChild(Object)
			if not Current then
				return nil
			end
		end
	end

	return Current
end

local function DistanceCheck(target : Model) : boolean
	if _G.DistanceFlag ~= nil and not _G.DistanceFlag or false then return true end
	if not target:FindFirstChild(_G.Part) then return true end

	local distance = (Camera.CFrame.Position - target:FindFirstChild(_G.Part).Position).Magnitude
	return distance < _G.MaxDistance
end

local function CrewCheck(target : Model) : boolean
	if _G.CrewFlag ~= nil and not _G.CrewFlag or false then return true end
	if not CrewPath then warn("Crew check disabled due to no path found", target.Name); _G.CrewFlag = false; return true end

	local CrewInstance1 = UsePath(CrewPath, target.Name)
	local CrewInstance2 = UsePath(CrewPath, Player.Name)
	if not CrewInstance1 or not CrewInstance2 then warn("Crew check passed due to no instance found", target.Name); return true end
	if CrewInstance1.Value == nil or CrewInstance2.Value == nil then warn("Crew check passed due to incorrect instance", target.Name); return true end

	if CrewInstance1.Value ~= CrewInstance2.Value then
		return true
	else
		return false
	end
end

local function KOCheck(target : Model) : boolean
	if _G.KOFlag ~= nil and not _G.KOFlag then 
		return true
	end
	if not KOPath then warn("KO check disabled due to no path found", target.Name); _G.KOFlag = false; return true end

	local KOInstance = UsePath(KOPath, target.Name)
	if not KOInstance then warn("KO check passed due to no value found", target.Name); return true end
	if KOInstance.Value == nil then warn("KO check passed due to incorrect instance", target.Name); return true end

	return not KOInstance.Value
end

local function WallCheck(target : Model, Characters : {Model}?) : boolean
	if not Characters then
		Characters = {}

		table.insert(Characters, Camera)
		for _, nigga in Players:GetPlayers() do
			if nigga.Character and nigga.Character:FindFirstChild("HumanoidRootPart") then
				table.insert(Characters, nigga.Character)
			end
		end
	end

	local rayparams = RaycastParams.new()
	rayparams.FilterType = Enum.RaycastFilterType.Exclude
	rayparams.FilterDescendantsInstances = Characters
	rayparams.RespectCanCollide = true

	local raycast = workspace:Raycast(
		Camera.CFrame.Position,
		target.Head.Position - Camera.CFrame.Position,
		rayparams
	)

	if raycast then
		return false
	else
		return true
	end
end

local function FindNearest() :  Model
	local target = nil
	local distance = _G.FOV
	local MousePosition = Vector2.new(Mouse.X, Mouse.Y)

	local Characters = {}
	table.insert(Characters, Camera)
	for _, nigga in Players:GetPlayers() do
		if nigga.Character and nigga.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(Characters, nigga.Character)
		end
	end

	for _, nigga in Players:GetPlayers() do
		if Player == nigga then continue end
		if not nigga.Character then continue end
		if not nigga.Character:FindFirstChild("HumanoidRootPart") or not nigga.Character:FindFirstChild("Head") then continue end
		if not DistanceCheck(nigga) then continue end

		local pos, onscreen = Camera:WorldToViewportPoint(nigga.Character.Head.Position)
		if not onscreen then continue end

		if not WallCheck(nigga.Character, Characters) then continue end
		if not CrewCheck(nigga.Character) then continue end
		if not KOCheck(nigga.Character) then continue end

		if (MousePosition - Vector2.new(pos.X, pos.Y)).Magnitude < distance then
			distance = (MousePosition - Vector2.new(pos.X, pos.Y)).Magnitude
			target = nigga.Character
		end
	end

	return target
end

local function GetNearestPart(target : Model) : string
	if not _G.NearestPart then return _G.Part end

	local MousePosition = Vector2.new(Mouse.X, Mouse.Y)
	local closest = _G.Part
	local distance = math.huge

	for _, Name in _G.Parts do
		local part = target:FindFirstChild(Name)
		if part then
			local pos, onscreen = Camera:WorldToViewportPoint(part.Position)
			if not onscreen then continue end
			pos = Vector2.new(pos.X, pos.Y)

			if (MousePosition - Vector2.new(pos.X, pos.Y)).Magnitude < distance then
				distance = (MousePosition - Vector2.new(pos.X, pos.Y)).Magnitude
				closest = Name
			end
		end
	end

	return closest
end

local function GetPosition() : Vector3
	local X = Target[_G.Part].Position.X
	local Y = Enum.KeyCode[_G.YPosKeybind] and
		game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode[_G.YPosKeybind]) and
		Player.Character[_G.Part].Position.Y
		or Target[_G.Part].Position.Y

	local Z = Target[_G.Part].Position.Z

	return Vector3.new(X, Y, Z)
end

local function UpdateCamera()
	if not Target or not Target[_G.Part] then return end

	local Position = GetPosition()

	if _G.Smooth then
		local Current = Camera.CFrame
		Current = Current - Current.Position
		local Goal = CFrame.lookAt(Camera.CFrame.Position, Position)
		Goal = Goal - Goal.Position

		Camera.CFrame = CFrame.new(Camera.CFrame.Position) * Current:Lerp(Goal, _G.XZLerpAmount)
	else
		Camera.CFrame = CFrame.lookAt(
			Camera.CFrame.Position,
			Position
		)
	end
end

local function Toggle(enabled : boolean?)
	if enabled == nil then
		CamlockEnabled = not CamlockEnabled
		Target = nil
	else
		CamlockEnabled = enabled
		Target = nil
	end
end

local function Panic()
	CamlockEnabled = false
	Target = nil

	for _, event in events do
		event:Disconnect()
	end
end

local function AimbotMain()
	if Tabbed then return end
	if not CamlockEnabled then return end
	if not Target or not _G.Sticky then Target = FindNearest() end

	if Target then
		if not WallCheck(Target) then return end
		if not KOCheck(Target) then Toggle(false); return end
		if not KOCheck(Player.Character) then Toggle(false); return end
		if _G.NearestPart and #_G.Parts > 1 then _G.Part = GetNearestPart(Target) end

		UpdateCamera()
	end
end

local function TriggerbotMain()
	if Tabbed then return end
	if not TriggerbotEnabled then return end
	
	if TriggerbotHitboxDetected then warn("Triggerbot hasn't detected a hitbox") return end
	if os.clock() - TriggerbotTime < _G.TriggerbotDelay then warn("Delaying triggerbot") return end
	if TriggerbotCooldown then warn("Triggerbot on cooldown") return end
	TriggerbotCooldown = true
	
	mouse1press()
	task.wait(_G.TriggerbotHoldTime)
	mouse1release()
	
	task.wait(_G.TriggerbotCooldown)
	TriggerbotCooldown = false
end

KOPath = GetPath(Player.Character, {"k.o", "ko"})
CrewPath = GetPath(Player, {"crew"})

events = {
	game:GetService("UserInputService").InputBegan:Connect(function(Input, Processed)
		if Processed then return end

		if Enum.KeyCode[_G.CamlockKeybind] and Input.KeyCode == Enum.KeyCode[_G.CamlockKeybind] then
			Toggle()
		elseif Enum.KeyCode[_G.PanicKeybind] and Input.KeyCode == Enum.KeyCode[_G.PanicKeybind] then
			Panic()
		end
	end),
	
	game:GetService("UserInputService").InputEnded:Connect(function(Input, Processed)
		if Input.KeyCode == Enum.KeyCode[_G.CamlockKeybind] and _G.Mode == "Hold" then
			Toggle(false)
		end
	end),
	
	game:GetService("UserInputService").WindowFocused:Connect(function()
		Tabbed = false
	end),
	
	game:GetService("UserInputService").WindowFocusReleased:Connect(function()
		Tabbed = true
	end),
	
	Mouse:GetPropertyChangedSignal("Target"):Connect(function()
		TriggerbotTime = os.clock()
		if Mouse.Target and Mouse.Target.Name == "Hitbox" or Mouse.Target:IsDescendantOf(workspace:FindFirstChild("Players")) then
			TriggerbotHitboxDetected = true
		else
			TriggerbotHitboxDetected = false
		end
	end),
	
	game:GetService("RunService").PreRender:Connect(function()
		if _G.CamlockEnabled then
			AimbotMain()
		end

		if _G.TriggerbotEnabled then
			TriggerbotMain()
		end
	end)
}
