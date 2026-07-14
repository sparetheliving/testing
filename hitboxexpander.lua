local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local function ChangeHitbox(Target : Model) : Part
	local HumanoidRootPart = Target:WaitForChild("HumanoidRootPart", 1)
	if not HumanoidRootPart then return end

	local RootAttachment = HumanoidRootPart:WaitForChild("RootAttachment", 1)
	if not RootAttachment then return end

	local Hitbox = RootAttachment:WaitForChild("Hitbox", 1)
	if not Hitbox then return end

	Hitbox.Size *= (getgenv().HitboxScale or 1.2)
	return RootAttachment
end

for _, nigga in Players:GetPlayers() do
	if nigga == Player then continue end
	if nigga.Character then
		ChangeHitbox(nigga.Character)
	end
end

warn("Hitbox expander activated")
