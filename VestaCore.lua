-- VESTA MOBILE | ALL IN ONE (Aim + WH + Triggerbot)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Config = {
    Aim = { Enabled = true, FOV = 150, Smoothness = 0.25, Key = Enum.UserInputType.MouseButton2 },
    WH = { Enabled = true, BoxColor = Color3.fromRGB(140, 80, 255), MaxDistance = 800 },
    Triggerbot = { Enabled = false }
}

local Drawings = {}
local aimHeld = false

-- ИДЕАЛЬНЫЙ ВХ (Bounding Box)
local function getBoundingBox(char)
    local min = Vector3.new(math.huge, math.huge, math.huge)
    local max = Vector3.new(-math.huge, -math.huge, -math.huge)
    local found = false
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" and v.Transparency < 1 then
            local pos, size = v.Position, v.Size / 2
            min = Vector3.new(math.min(min.X, pos.X - size.X), math.min(min.Y, pos.Y - size.Y), math.min(min.Z, pos.Z - size.Z))
            max = Vector3.new(math.max(max.X, pos.X + size.X), math.max(max.Y, pos.Y + size.Y), math.max(max.Z, pos.Z + size.Z))
            found = true
        end
    end
    return found and min or nil, found and max or nil
end

local function updateESP()
    if Camera.ViewportSize.X <= 0 then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or (plr.Team and plr.Team == LocalPlayer.Team) then
            if Drawings[plr] then for _, d in pairs(Drawings[plr]) do d.Visible = false end end
            continue
        end
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health <= 0 then
            if Drawings[plr] then for _, d in pairs(Drawings[plr]) do d.Visible = false end end
            continue
        end
        local minV, maxV = getBoundingBox(char)
        local root = char:FindFirstChild("HumanoidRootPart")
        if not minV or not root then continue end
        if (root.Position - Camera.CFrame.Position).Magnitude > Config.WH.MaxDistance then
            if Drawings[plr] then for _, d in pairs(Drawings[plr]) do d.Visible = false end end
            continue
        end
        local corners = {
            Vector3.new(minV.X, minV.Y, minV.Z), Vector3.new(minV.X, minV.Y, maxV.Z),
            Vector3.new(minV.X, maxV.Y, minV.Z), Vector3.new(minV.X, maxV.Y, maxV.Z),
            Vector3.new(maxV.X, minV.Y, minV.Z), Vector3.new(maxV.X, minV.Y, maxV.Z),
            Vector3.new(maxV.X, maxV.Y, minV.Z), Vector3.new(maxV.X, maxV.Y, maxV.Z)
        }
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local anyOnScreen = false
        for _, corner in ipairs(corners) do
            local sp, on = Camera:WorldToViewportPoint(corner)
            if on and sp.Z > 0 then
                anyOnScreen = true
                minX = math.min(minX, sp.X); maxX = math.max(maxX, sp.X)
                minY = math.min(minY, sp.Y); maxY = math.max(maxY, sp.Y)
            end
        end
        if not anyOnScreen then
            if Drawings[plr] then for _, d in pairs(Drawings[plr]) do d.Visible = false end end
            continue
        end
        if not Drawings[plr] then
            Drawings[plr] = { Box = Drawing.new("Square"), Name = Drawing.new("Text") }
            Drawings[plr].Box.Thickness = 1.5
            Drawings[plr].Box.Color = Config.WH.BoxColor
            Drawings[plr].Box.Filled = false
            Drawings[plr].Name.Size = 13
            Drawings[plr].Name.Center = true
            Drawings[plr].Name.Outline = true
            Drawings[plr].Name.Color = Color3.fromRGB(255, 255, 255)
        end
        local wd = Drawings[plr]
        wd.Box.Size = Vector2.new(maxX - minX, maxY - minY)
        wd.Box.Position = Vector2.new(minX, minY)
        wd.Box.Visible = Config.WH.Enabled
        wd.Name.Text = plr.Name
        wd.Name.Position = Vector2.new(minX + (maxX - minX)/2, minY - 16)
        wd.Name.Visible = Config.WH.Enabled
    end
end

-- АИМ + ТРИГГЕР
local function updateAim()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local best, bestDist = nil, Config.Aim.FOV
    local triggerTarget = nil

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or (plr.Team and plr.Team == LocalPlayer.Team) then continue end
        local char = plr.Character
        local head = char and char:FindFirstChild("Head")
        if not head then continue end
        local sp, on = Camera:WorldToViewportPoint(head.Position)
        if on and sp.Z > 0 then
            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
            if d < bestDist then
                bestDist = d
                best = head
            end
            if d < 30 then triggerTarget = true end
        end
    end

    if Config.Aim.Enabled and aimHeld and best then
        local desired = CFrame.lookAt(Camera.CFrame.Position, best.Position)
        Camera.CFrame = Camera.CFrame:Lerp(desired, 1 - Config.Aim.Smoothness)
    end

    if Config.Triggerbot.Enabled and triggerTarget then
        pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.01)
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end)
    end
end

UserInputService.InputBegan:Connect(function(i, gp) if not gp and i.UserInputType == Config.Aim.Key then aimHeld = true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Config.Aim.Key then aimHeld = false end end)

RunService.RenderStepped:Connect(updateESP)
RunService:BindToRenderStep("VestaAim", Enum.RenderPriority.Camera.Value + 1, updateAim)
