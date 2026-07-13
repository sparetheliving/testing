local HitboxScale = 55

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local CharacterAddedEvents = {}
local ChildAdded = {}

local function ChangeHitbox(Target : Model) : Part
	task.spawn(function()
		local HumanoidRootPart = Target:WaitForChild("HumanoidRootPart", 1)
		if not HumanoidRootPart then return end

		local RootAttachment = HumanoidRootPart:WaitForChild("RootAttachment", 1)
		if not RootAttachment then return end

		local Hitbox = RootAttachment:WaitForChild("Hitbox", 1)
		if not Hitbox then return end

		Hitbox.Size *= HitboxScale
		return RootAttachment
	end)
end

local function Setup(nigga : Player)
	local RootAttachment = ChangeHitbox(nigga.Character)
	if not RootAttachment then return end
	ChildAdded[nigga.Name] = RootAttachment.ChildAdded:Connect(function(Part)
		if Part.Name == "Hitbox" then
			ChangeHitbox(Part)
		end
	end)

	CharacterAddedEvents[nigga.Name] = nigga.CharacterAdded:Connect(ChangeHitbox)
end

for _, nigga in Players:GetPlayers() do
	if nigga == Player then continue end
	if nigga.Character then
		Setup(nigga)
	end
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
