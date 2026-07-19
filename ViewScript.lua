local Enabled = false
local Camera = workspace.CurrentCamera
local function Toggle(Boolean : boolean?)
    if Boolean ~= nil then
        Enabled = Boolean
    end
    
    if Enabled then
        local Player = game:GetService("Players"):FindFirstChild(Person)
        if Player then
            if Player.Character then
                local Humanoid = Player.Character:FindFirstChildWhichIsA("Humanoid")
                if Humanoid then
                    Camera.CameraSubject = Humanoid
                else
                    warn("Player has no humanoid")
                end
            else
                warn("Player not spawned in")
            end
        else
            warn("Player not found")
        end
    else
        local Player = game:GetService("Players").LocalPlayer
        if Player.Character then
            local Humanoid = Player.Character:FindFirstChildWhichIsA("Humanoid")
            if Humanoid then
                Camera.CameraSubject = Humanoid
            else
                warn("Player has no humanoid")
            end
        else
            warn("Player not spawned in")
        end
    end
end

event = game:GetService("UserInputService").InputBegan:Connect(function(Input, Processed)
    if Processed then return end

    if Input.KeyCode == Enum.KeyCode[Keybind] then
        Enabled = not Enabled
        Toggle()
    elseif Input.KeyCode == Enum.KeyCode[Panic] then
        event:Disconnect()
        Toggle(false)
    end
end)
