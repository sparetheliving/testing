local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local CharacterAddedEvents = {}
local ChildAdded = {}

local function ChangeHitbox(Target : Model) : Part
	local HumanoidRootPart = Target:FindFirstChild("HumanoidRootPart")
	if not HumanoidRootPart then return end

	local RootAttachment = HumanoidRootPart:FindFirstChild("RootAttachment")
	if not RootAttachment then return end

	local Hitbox = RootAttachment:FindFirstChild("Hitbox")
	if not Hitbox then return end

	Hitbox.Size *= (getgenv().HitboxScale or 1.2)
	return RootAttachment
end

local function Setup(nigga : Player)
	local RootAttachment = ChangeHitbox(nigga.Character)
	if not RootAttachment then return end
	ChildAdded[nigga.Name] = RootAttachment.ChildAdded:Connect(function(Part)
		if Part.Name == "Hitbox" then
			ChangeHitbox(Part)
		end
	end)

	CharacterAddedEvents[nigga.Name] = nigga.CharacterAdded:Connect(function(Character)
		ChangeHitbox(Character)
	end)
end

Players.PlayerAdded:Connect(function(nigga)
	nigga.CharacterAdded:Wait()
	task.wait(.1)
	Setup(nigga)
end)

Players.PlayerRemoving:Connect(function(nigga)
	if CharacterAddedEvents[nigga.Name] then
		CharacterAddedEvents[nigga.Name]:Disconnect()
		CharacterAddedEvents[nigga.Name] = nil
	end
	if ChildAdded[nigga.Name] then
		ChildAdded[nigga.Name]:Disconnect()
		ChildAdded[nigga.Name] = nil
	end
end)

task.spawn(function()
	while task.wait(1) do
		for _, nigga in Players:GetPlayers() do
			if nigga == Player then continue end
			if nigga.Character then
				ChangeHitbox(nigga.Character)
			end
		end
	end
end)

warn("Hitbox expander activated")
