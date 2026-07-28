local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "The Walking Dead Online 3",
    SubTitle = "by OHM GG",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, 
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Players = game:GetService("Players") 
local RunService = game:GetService("RunService") 
local TweenService = game:GetService("TweenService") 
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer 
local Camera = Workspace.CurrentCamera 

local ESPSettings = {
    Box_Color = Color3.fromRGB(255, 0, 0),
    Box_Thickness = 2,
    Team_Check = false,
    Team_Color = false,
    Autothickness = true
}

local ESPEnabled = false
local ESPData = {} 

local function NewLine(color, thickness)
    local line = Drawing.new("Line")
    line.Visible = false
    line.From = Vector2.new(0, 0)
    line.To = Vector2.new(0, 0)
    line.Color = color
    line.Thickness = thickness
    line.Transparency = 1
    return line
end

local function Vis(lib, state)
    for _, v in pairs(lib) do
        v.Visible = state
    end
end

local function Colorize(lib, color)
    for _, v in pairs(lib) do
        v.Color = color
    end
end

local function RainbowLoop(lib)
    task.spawn(function()
        while ESPEnabled and lib do
            for hue = 0, 1, 1/30 do
                if not ESPEnabled then break end
                local color = Color3.fromHSV(hue, 0.6, 1)
                Colorize(lib, color)
                task.wait(0.15)
            end
        end
    end)
end

local function CleanupPlayerESP(plr)
    if ESPData[plr] then
        local data = ESPData[plr]
        if data.Connection then data.Connection:Disconnect() end
        if data.Library then
            for _, line in pairs(data.Library) do
                pcall(function() line:Remove() end)
            end
        end
        if data.OriPart then
            pcall(function() data.OriPart:Destroy() end)
        end
        ESPData[plr] = nil
    end
end

local function ApplyESP(plr)
    if plr == LocalPlayer or ESPData[plr] then return end

    local library = {
        TL1 = NewLine(ESPSettings.Box_Color, ESPSettings.Box_Thickness),
        TL2 = NewLine(ESPSettings.Box_Color, ESPSettings.Box_Thickness),
        TR1 = NewLine(ESPSettings.Box_Color, ESPSettings.Box_Thickness),
        TR2 = NewLine(ESPSettings.Box_Color, ESPSettings.Box_Thickness),
        BL1 = NewLine(ESPSettings.Box_Color, ESPSettings.Box_Thickness),
        BL2 = NewLine(ESPSettings.Box_Color, ESPSettings.Box_Thickness),
        BR1 = NewLine(ESPSettings.Box_Color, ESPSettings.Box_Thickness),
        BR2 = NewLine(ESPSettings.Box_Color, ESPSettings.Box_Thickness)
    }

    RainbowLoop(library)

    local oripart = Instance.new("Part")
    oripart.Parent = Workspace
    oripart.Transparency = 1
    oripart.CanCollide = false
    oripart.Size = Vector3.new(1, 1, 1)
    oripart.Position = Vector3.new(0, 0, 0)

    local renderConnection
    renderConnection = RunService.RenderStepped:Connect(function()
        if not ESPEnabled then
            Vis(library, false)
            return
        end

        local char = plr.Character
        if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") and char.Humanoid.Health > 0 and char:FindFirstChild("Head") then
            local humRoot = char.HumanoidRootPart
            local _, vis = Camera:WorldToViewportPoint(humRoot.Position)

            if vis then
                oripart.Size = Vector3.new(humRoot.Size.X, humRoot.Size.Y * 1.5, humRoot.Size.Z)
                oripart.CFrame = CFrame.new(humRoot.CFrame.Position, Camera.CFrame.Position)
                
                local SizeX = oripart.Size.X
                local SizeY = oripart.Size.Y
                local TL = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(SizeX, SizeY, 0)).p)
                local TR = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(-SizeX, SizeY, 0)).p)
                local BL = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(SizeX, -SizeY, 0)).p)
                local BR = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(-SizeX, -SizeY, 0)).p)

                if ESPSettings.Team_Check then
                    if plr.TeamColor == LocalPlayer.TeamColor then
                        Colorize(library, Color3.fromRGB(0, 255, 0))
                    else 
                        Colorize(library, Color3.fromRGB(255, 0, 0))
                    end
                end

                if ESPSettings.Team_Color then
                    Colorize(library, plr.TeamColor.Color)
                end

                local ratio = (Camera.CFrame.p - humRoot.Position).Magnitude
                local offset = math.clamp(1 / ratio * 750, 2, 300)

                library.TL1.From = Vector2.new(TL.X, TL.Y)
                library.TL1.To = Vector2.new(TL.X + offset, TL.Y)
                library.TL2.From = Vector2.new(TL.X, TL.Y)
                library.TL2.To = Vector2.new(TL.X, TL.Y + offset)

                library.TR1.From = Vector2.new(TR.X, TR.Y)
                library.TR1.To = Vector2.new(TR.X - offset, TR.Y)
                library.TR2.From = Vector2.new(TR.X, TR.Y)
                library.TR2.To = Vector2.new(TR.X, TR.Y + offset)

                library.BL1.From = Vector2.new(BL.X, BL.Y)
                library.BL1.To = Vector2.new(BL.X + offset, BL.Y)
                library.BL2.From = Vector2.new(BL.X, BL.Y)
                library.BL2.To = Vector2.new(BL.X, BL.Y - offset)

                library.BR1.From = Vector2.new(BR.X, BR.Y)
                library.BR1.To = Vector2.new(BR.X - offset, BR.Y)
                library.BR2.From = Vector2.new(BR.X, BR.Y)
                library.BR2.To = Vector2.new(BR.X, BR.Y - offset)

                Vis(library, true)

                if ESPSettings.Autothickness then
                    local myChar = LocalPlayer.Character
                    if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                        local distance = (myChar.HumanoidRootPart.Position - oripart.Position).Magnitude
                        local value = math.clamp(1 / distance * 100, 1, 4)
                        for _, x in pairs(library) do
                            x.Thickness = value
                        end
                    end
                else 
                    for _, x in pairs(library) do
                        x.Thickness = ESPSettings.Box_Thickness
                    end
                end
            else 
                Vis(library, false)
            end
        else 
            Vis(library, false)
            if not Players:FindFirstChild(plr.Name) then
                CleanupPlayerESP(plr)
            end
        end
    end)

    ESPData[plr] = {
        Library = library,
        OriPart = oripart,
        Connection = renderConnection
    }
end

local PlayerAddedConnection = nil

local function EnableESP()
    if ESPEnabled then return end
    ESPEnabled = true

    for _, plr in ipairs(Players:GetPlayers()) do
        ApplyESP(plr)
    end

    PlayerAddedConnection = Players.PlayerAdded:Connect(function(plr)
        ApplyESP(plr)
    end)
end

local function DisableESP()
    ESPEnabled = false

    if PlayerAddedConnection then
        PlayerAddedConnection:Disconnect()
        PlayerAddedConnection = nil
    end

    for plr, _ in pairs(ESPData) do
        CleanupPlayerESP(plr)
    end
    table.clear(ESPData)
end

------------------------------------------------------------------------
-- Find Cars
------------------------------------------------------------------------
local function GetCarCFrame(car)
    if car:IsA("Model") and car.PrimaryPart then
        return car.PrimaryPart.CFrame
    end
    
    local seat = car:FindFirstChildWhichIsA("VehicleSeat", true) or car:FindFirstChild("DriveSeat", true)
    if seat then
        return seat.CFrame
    end

    local body = car:FindFirstChild("Body", true)
    if body then
        return body:GetPivot()
    end

    return car:GetPivot()
end

local function GetNearestCar()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil, math.huge end
    
    local playerPos = character.HumanoidRootPart.Position
    local carsFolder = Workspace:FindFirstChild("Cars")
    
    if not carsFolder then 
        print("ไม่พบโฟลเดอร์ Cars ใน workspace")
        return nil, math.huge 
    end

    local nearestCar = nil
    local shortestDistance = math.huge
    local nearestCarCFrame = nil

    for _, car in ipairs(carsFolder:GetChildren()) do
        local carCFrame = GetCarCFrame(car)
        
        if carCFrame then
            local distance = (playerPos - carCFrame.Position).Magnitude

            if distance < shortestDistance then
                shortestDistance = distance
                nearestCar = car
                nearestCarCFrame = carCFrame
            end
        end
    end

    return nearestCar, shortestDistance, nearestCarCFrame
end

local function TeleportToNearestCar()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local targetCar, distance, targetCFrame = GetNearestCar()

    if targetCar and targetCFrame then
        character.HumanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 10, 0)
        print("วาร์ปไปยัง " .. targetCar.Name .. " สำเร็จ! ระยะห่างเดิม:", math.floor(distance), "Studs")
    else
        print("ไม่พบตำแหน่งของรถในโฟลเดอร์ Cars")
    end
end

------------------------------------------------------------------------
-- FPS Boost
------------------------------------------------------------------------
local sethiddenproperty = sethiddenproperty or set_hidden_property or set_hidden_prop
local Lighting = game:GetService("Lighting")
local Terrain = Workspace.Terrain
local RenderSettings = settings():GetService("RenderSettings")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

local OriginalSettings = {
    Lighting = {},
    Terrain = {},
    SavedMaterials = {},
    SavedShadows = {},
    SavedEffects = {}
}

local FPSBoostConnections = {}
local IsFPSBoostEnabled = false

local function EnableFPSBoost()
    if IsFPSBoostEnabled then return end
    IsFPSBoostEnabled = true

    OriginalSettings.Lighting.GlobalShadows = Lighting.GlobalShadows
    OriginalSettings.Lighting.FogEnd = Lighting.FogEnd
    
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e9

    if sethiddenproperty then
        pcall(sethiddenproperty, Lighting, "Technology", Enum.Technology.Compatibility)
    end

    RenderSettings.EagerBulkExecution = false
    RenderSettings.QualityLevel = Enum.QualityLevel.Level01
    RenderSettings.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    Workspace.InterpolationThrottling = Enum.InterpolationThrottlingMode.Enabled

    OriginalSettings.Terrain.WaterWaveSize = Terrain.WaterWaveSize
    OriginalSettings.Terrain.WaterWaveSpeed = Terrain.WaterWaveSpeed
    OriginalSettings.Terrain.WaterReflectance = Terrain.WaterReflectance
    OriginalSettings.Terrain.WaterTransparency = Terrain.WaterTransparency

    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 0
    if sethiddenproperty then pcall(sethiddenproperty, Terrain, "Decoration", false) end

    for _, Object in ipairs(game:GetDescendants()) do
        if Object:IsA("BasePart") then
            OriginalSettings.SavedMaterials[Object] = Object.Material
            OriginalSettings.SavedShadows[Object] = Object.CastShadow
            
            Object.Material = Enum.Material.SmoothPlastic
            Object.CastShadow = false
        elseif Object:IsA("ParticleEmitter") or Object:IsA("Sparkles") or Object:IsA("Smoke") or Object:IsA("Trail") or Object:IsA("Fire") then
            OriginalSettings.SavedEffects[Object] = Object.Enabled
            Object.Enabled = false
        elseif Object:IsA("PostEffect") or Object:IsA("Atmosphere") then
            OriginalSettings.SavedEffects[Object] = Object.Enabled
            Object.Enabled = false
        elseif (Object:IsA("Decal") or Object:IsA("Texture")) and string.lower(Object.Parent.Name) ~= "head" then
            OriginalSettings.SavedEffects[Object] = Object.Transparency
            Object.Transparency = 1
        end
    end

    local descAdded = game.DescendantAdded:Connect(function(Object)
        if not IsFPSBoostEnabled then return end
        if Object:IsA("BasePart") then
            Object.Material = Enum.Material.SmoothPlastic
            Object.CastShadow = false
        elseif Object:IsA("ParticleEmitter") or Object:IsA("Sparkles") or Object:IsA("Smoke") or Object:IsA("Trail") or Object:IsA("Fire") then
            Object.Enabled = false
        end
    end)
    table.insert(FPSBoostConnections, descAdded)
end

local function DisableFPSBoost()
    if not IsFPSBoostEnabled then return end
    IsFPSBoostEnabled = false

    for _, conn in ipairs(FPSBoostConnections) do
        if conn then conn:Disconnect() end
    end
    table.clear(FPSBoostConnections)

    Lighting.GlobalShadows = OriginalSettings.Lighting.GlobalShadows or true
    Lighting.FogEnd = OriginalSettings.Lighting.FogEnd or 100000

    Terrain.WaterWaveSize = OriginalSettings.Terrain.WaterWaveSize or 0.15
    Terrain.WaterWaveSpeed = OriginalSettings.Terrain.WaterWaveSpeed or 10
    Terrain.WaterReflectance = OriginalSettings.Terrain.WaterReflectance or 1
    Terrain.WaterTransparency = OriginalSettings.Terrain.WaterTransparency or 1

    for obj, mat in pairs(OriginalSettings.SavedMaterials) do
        if obj and obj.Parent then obj.Material = mat end
    end
    for obj, shadow in pairs(OriginalSettings.SavedShadows) do
        if obj and obj.Parent then obj.CastShadow = shadow end
    end
    for obj, state in pairs(OriginalSettings.SavedEffects) do
        if obj and obj.Parent then
            if typeof(state) == "boolean" then
                obj.Enabled = state
            elseif typeof(state) == "number" then
                obj.Transparency = state
            end
        end
    end

    table.clear(OriginalSettings.SavedMaterials)
    table.clear(OriginalSettings.SavedShadows)
    table.clear(OriginalSettings.SavedEffects)
end

------------------------------------------------------------------------
-- WalkSpeed Settings
------------------------------------------------------------------------
getgenv().SpeedSettings = getgenv().SpeedSettings or {
    Enabled = false,
    Speed = 16,
    Control = true,
    Friction = 2.0
}

local SpeedConnection = nil

local function EnhanceControl(reset)
    local character = LocalPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        if reset then
            rootPart.CustomPhysicalProperties = nil
        else
            rootPart.CustomPhysicalProperties = PhysicalProperties.new(
                0.7, 
                getgenv().SpeedSettings.Friction, 
                0.5, 
                1.0, 
                0.5
            )
        end
    end
end

local function SetWalkSpeed(speedValue)
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = speedValue
    end
end

local function EnableSpeed()
    getgenv().SpeedSettings.Enabled = true
    
    if getgenv().SpeedSettings.Control then
        EnhanceControl(false)
    end

    if SpeedConnection then SpeedConnection:Disconnect() end

    SpeedConnection = RunService.RenderStepped:Connect(function()
        if getgenv().SpeedSettings.Enabled then
            SetWalkSpeed(getgenv().SpeedSettings.Speed)
        end
    end)
end

local function DisableSpeed()
    getgenv().SpeedSettings.Enabled = false

    if SpeedConnection then
        SpeedConnection:Disconnect()
        SpeedConnection = nil
    end

    SetWalkSpeed(16)
    EnhanceControl(true)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if getgenv().SpeedSettings.Enabled then
        EnableSpeed()
    end
end)

------------------------------------------------------------------------
-- Teleport List & UI Setup
------------------------------------------------------------------------
local TeleportValue = {
    "not select",
    "farm_01",
    "bunker",
}

local TeleportList = {
    ['farm_01']     = Vector3.new(2620.53,289.76,-2956.35),
    ['bunker']      = Vector3.new(5304.38,128.99,-5807.91),
}

local Options = Fluent.Options

do
    Tabs.Main:AddButton({
        Title = "Teleport To Nearest Car",
        Description = "วาร์ปไปยังรถที่อยู่ใกล้",
        Callback = function()
            TeleportToNearestCar()
        end
    })

    local Dropdown = Tabs.Main:AddDropdown("Dropdown", {
        Title = "Teleport (Coordinates)",
        Values = TeleportValue,
        Multi = false,
        Default = 1,
    })
    
    Dropdown:SetValue("not select")
    
    Dropdown:OnChanged(function(Value)
        local targetPosition = TeleportList[Value]
        
        if targetPosition then
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                hrp.CFrame = CFrame.new(targetPosition) + Vector3.new(0, 5, 0)
            end
        end
    end)

    local Toggle = Tabs.Main:AddToggle("ESPToggle", { Title = "Drawing Box Corner ESP", Default = false })
    Toggle:OnChanged(function()
        local state = Options.ESPToggle.Value
        if state then
            EnableESP()
        else
            DisableESP()
        end
    end)
    Options.ESPToggle:SetValue(false)

    local FPSToggle = Tabs.Main:AddToggle("FPSToggle", { Title = "FPS Boost (Optimized)", Default = false })
    FPSToggle:OnChanged(function()
        local state = Options.FPSToggle.Value
        if state then
            EnableFPSBoost()
        else
            DisableFPSBoost()
        end
    end)
    Options.FPSToggle:SetValue(false)
    
    local SpeedToggle = Tabs.Main:AddToggle("SpeedToggle", { Title = "WalkSpeed Hack", Default = false })
    SpeedToggle:OnChanged(function()
        local state = Options.SpeedToggle.Value
        if state then
            EnableSpeed()
        else
            DisableSpeed()
        end
    end)

    Tabs.Main:AddSlider("SpeedSlider", {
        Title = "Speed Value",
        Description = "ปรับความเร็วการเดิน/วิ่ง",
        Default = 16,
        Min = 16,
        Max = 45,
        Rounding = 0,
        Callback = function(Value)
            getgenv().SpeedSettings.Speed = Value
            if getgenv().SpeedSettings.Enabled then
                SetWalkSpeed(Value)
            end
        end
    })
end

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

SaveManager:LoadAutoloadConfig()