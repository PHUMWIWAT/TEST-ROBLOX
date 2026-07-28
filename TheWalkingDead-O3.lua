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

local Settings = {
    Color1 = Color3.fromRGB(0, 0, 70),
    Color2 = Color3.fromRGB(0, 150, 255),

    ParticleColor = Color3.fromRGB(0, 100, 255),
    SpawnRate = 0.15,

    BoxThickness = 3.5, 
    PulseSpeed = 1.2,
    RotationSpeed = 3, 
    MaxDistance = 3000, 
}

local Players = game:GetService("Players") 
local RunService = game:GetService("RunService") 
local TweenService = game:GetService("TweenService") 
local LocalPlayer = Players.LocalPlayer 
local Camera = workspace.CurrentCamera 

local ParticleFolder = workspace:FindFirstChild("ESP_DarkBlue_Particles") or Instance.new("Folder", workspace)
ParticleFolder.Name = "ESP_DarkBlue_Particles"

local ESPEnabled = false
local ActiveESP = {} 
local GlobalConnections = {} 

local function RemoveVanillaName(char)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
end

local function SpawnNeonParticle(pos)
    if not ESPEnabled then return end
    
    local part = Instance.new("Part")
    part.Size = Vector3.new(0.3, 0.3, 0.3)
    part.Position = pos + Vector3.new(
        math.random(-2,2),
        -3.5,
        math.random(-2,2)
    )
    part.Anchored = true 
    part.CanCollide = false 
    part.Shape = Enum.PartType.Ball
    part.Material = Enum.Material.Neon 
    part.Color = Settings.ParticleColor
    part.Parent = ParticleFolder

    local tween = TweenService:Create(part,
        TweenInfo.new(1.8, Enum.EasingStyle.Quart),
        {
            Position = part.Position + Vector3.new(0, 7, 0),
            Transparency = 1,
            Size = Vector3.new(0,0,0)
        }
    )
    tween:Play()
    tween.Completed:Connect(function()
        part:Destroy()
    end)
end
local function CleanupPlayerESP(player)
    if ActiveESP[player] then
        if ActiveESP[player].BoxGui then ActiveESP[player].BoxGui:Destroy() end
        if ActiveESP[player].NameGui then ActiveESP[player].NameGui:Destroy() end
        if ActiveESP[player].Connections then
            for _, conn in pairs(ActiveESP[player].Connections) do
                conn:Disconnect()
            end
        end
        ActiveESP[player] = nil
    end
end
local function ApplyESP(player)
    if player == LocalPlayer then return end
    local function OnChar(char)
        if not ESPEnabled then return end
        CleanupPlayerESP(player) -- ล้างของเก่าก่อนสร้างใหม่
        RemoveVanillaName(char)
        local root = char:WaitForChild("HumanoidRootPart", 15)
        if not root or not ESPEnabled then return end
        local playerName = player.Name
        local userId = player.UserId
        local boxGui = Instance.new("BillboardGui")
        boxGui.Adornee = root 
        boxGui.Size = UDim2.new(4,0,5.5,0) 
        boxGui.AlwaysOnTop = true
        boxGui.MaxDistance = Settings.MaxDistance
        boxGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        local mainFrame = Instance.new("Frame")
        mainFrame.Size = UDim2.new(1,0,1,0)
        mainFrame.BackgroundTransparency = 1
        mainFrame.Parent = boxGui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.3, 0)
        corner.Parent = mainFrame
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = Settings.BoxThickness
        stroke.Color = Color3.new(1,1,1)
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = mainFrame
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Settings.Color1),
            ColorSequenceKeypoint.new(0.5, Settings.Color2),
            ColorSequenceKeypoint.new(1, Settings.Color1)
        })
        gradient.Parent = stroke
        task.spawn(function()
            while ESPEnabled and boxGui and boxGui.Parent do
                gradient.Rotation += Settings.RotationSpeed
                task.wait(0.02)
            end
        end)
        local nameGui = Instance.new("BillboardGui")
        nameGui.Adornee = root
        nameGui.Size = UDim2.new(4,0,1.5,0)
        nameGui.StudsOffset = Vector3.new(0, 3.5, 0) 
        nameGui.AlwaysOnTop = true
        nameGui.MaxDistance = Settings.MaxDistance
        nameGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1,0,1,0)
        container.BackgroundTransparency = 1
        container.Parent = nameGui
        local avatar = Instance.new("ImageLabel")
        avatar.Size = UDim2.new(0.25,0,1,0)
        avatar.BackgroundTransparency = 1
        avatar.Parent = container
        task.spawn(function()
            local ok, img = pcall(function()
                return Players:GetUserThumbnailAsync(
                    userId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size150x150
                )
            end)
            if ok and avatar then avatar.Image = img end
        end)
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.75,0,1,0)
        nameLabel.Position = UDim2.new(0.27,0,0,0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = playerName
        nameLabel.TextScaled = true
        nameLabel.TextColor3 = Color3.new(1,1,1)
        nameLabel.TextStrokeTransparency = 0.3
        nameLabel.Parent = container
        pcall(function()
            nameLabel.FontFace = Font.new("rbxassetid://11322590111")
        end)
        task.spawn(function()
            while ESPEnabled and boxGui and boxGui.Parent do
                if root and root.Parent then
                    local dist = (Camera.CFrame.Position - root.Position).Magnitude
                    if dist < 300 then
                        SpawnNeonParticle(root.Position)
                    end
                end
                task.wait(Settings.SpawnRate)
            end
        end)
        local renderConn
        renderConn = RunService.RenderStepped:Connect(function()
            if not char.Parent or not ESPEnabled then
                CleanupPlayerESP(player)
            end
        end)
        ActiveESP[player] = {
            BoxGui = boxGui,
            NameGui = nameGui,
            Connections = { renderConn }
        }
    end
    local charAddedConn = player.CharacterAdded:Connect(OnChar)
    if ActiveESP[player] then
        table.insert(ActiveESP[player].Connections, charAddedConn)
    else
        ActiveESP[player] = { Connections = { charAddedConn } }
    end
    if player.Character then
        task.spawn(OnChar, player.Character)
    end
end

local ESPLoopThread = nil

local function EnableESP()
    if ESPEnabled then return end 
    ESPEnabled = true

    ESPLoopThread = task.spawn(function()
        while ESPEnabled do
            -- 1. วนเช็กผู้เล่นทุกคนที่อยู่ในเซิร์ฟเวอร์
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    -- เรียก ApplyESP วนเช็ก/อัปเดตตลอดเวลา
                    ApplyESP(player)
                end
            end

            task.wait(0.5)
        end
    end)
end

local function DisableESP()
    ESPEnabled = false

    -- ยกเลิก Thread ของ Loop (ถ้ายังรันอยู่)
    if ESPLoopThread then
        task.cancel(ESPLoopThread)
        ESPLoopThread = nil
    end

    -- ล้างข้อมูล ESP ที่แสดงผลอยู่ทั้งหมดออก
    for player, _ in pairs(ActiveESP) do
        CleanupPlayerESP(player)
    end
    table.clear(ActiveESP)

    if ParticleFolder then
        ParticleFolder:ClearAllChildren()
    end
end


-- Find Cars

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
    local carsFolder = workspace:FindFirstChild("Cars")
    
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
        -- วาร์ปไปที่ตำแหน่ง DriveSeat/PrimaryPart แล้วขยับขึ้นข้างบน 5 studs
        character.HumanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 10, 0)
        
        print("วาร์ปไปยัง " .. targetCar.Name .. " สำเร็จ! ระยะห่างเดิม:", math.floor(distance), "Studs")
    else
        print("ไม่พบตำแหน่งของรถในโฟลเดอร์ Cars")
    end
end

-- FPS
local sethiddenproperty = sethiddenproperty or set_hidden_property or set_hidden_prop
local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain
local RenderSettings = settings():GetService("RenderSettings")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

-- เก็บค่าเดิมไว้ฟื้นฟูเมื่อปิดใช้งาน
local OriginalSettings = {
    Lighting = {},
    Terrain = {},
    SavedMaterials = {},
    SavedShadows = {},
    SavedEffects = {}
}

local FPSBoostConnections = {}
local IsFPSBoostEnabled = false

-- ฟังก์ชันเปิดใช้งาน FPS Boost
local function EnableFPSBoost()
    if IsFPSBoostEnabled then return end
    IsFPSBoostEnabled = true

    -- 1. บันทึกค่า Render & Lighting เดิม
    OriginalSettings.Lighting.GlobalShadows = Lighting.GlobalShadows
    OriginalSettings.Lighting.FogEnd = Lighting.FogEnd
    
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e9

    if sethiddenproperty then
        pcall(sethiddenproperty, Lighting, "Technology", Enum.Technology.Compatibility)
    end

    -- 2. ตั้งค่า Render Graphics
    RenderSettings.EagerBulkExecution = false
    RenderSettings.QualityLevel = Enum.QualityLevel.Level01
    RenderSettings.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    workspace.InterpolationThrottling = Enum.InterpolationThrottlingMode.Enabled

    -- 3. บันทึกและปรับค่า Terrain Water
    OriginalSettings.Terrain.WaterWaveSize = Terrain.WaterWaveSize
    OriginalSettings.Terrain.WaterWaveSpeed = Terrain.WaterWaveSpeed
    OriginalSettings.Terrain.WaterReflectance = Terrain.WaterReflectance
    OriginalSettings.Terrain.WaterTransparency = Terrain.WaterTransparency

    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 0
    if sethiddenproperty then pcall(sethiddenproperty, Terrain, "Decoration", false) end

    -- 4. จัดการ Object ในเกม (ลบเงา/ปรับ Material/ปิด Effect)
    for _, Object in ipairs(game:GetDescendants()) do
        if Object:IsA("BasePart") then
            -- เก็บค่าเดิม
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

    -- 5. ดักจับไอเทมสร้างใหม่ระหว่างเล่น ให้ปรับกะโหลกอัตโนมัติ
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

-- ฟังก์ชันปิดใช้งาน FPS Boost (คืนค่าเดิม)
local function DisableFPSBoost()
    if not IsFPSBoostEnabled then return end
    IsFPSBoostEnabled = false

    -- ตัดการเชื่อมต่อ Event
    for _, conn in ipairs(FPSBoostConnections) do
        if conn then conn:Disconnect() end
    end
    table.clear(FPSBoostConnections)

    -- คืนค่า Lighting & Terrain
    Lighting.GlobalShadows = OriginalSettings.Lighting.GlobalShadows or true
    Lighting.FogEnd = OriginalSettings.Lighting.FogEnd or 100000

    Terrain.WaterWaveSize = OriginalSettings.Terrain.WaterWaveSize or 0.15
    Terrain.WaterWaveSpeed = OriginalSettings.Terrain.WaterWaveSpeed or 10
    Terrain.WaterReflectance = OriginalSettings.Terrain.WaterReflectance or 1
    Terrain.WaterTransparency = OriginalSettings.Terrain.WaterTransparency or 1

    -- คืนค่าวัตถุต่างๆ
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

    -- ล้างตาราง
    table.clear(OriginalSettings.SavedMaterials)
    table.clear(OriginalSettings.SavedShadows)
    table.clear(OriginalSettings.SavedEffects)
end

-- Speed

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
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                hrp.CFrame = CFrame.new(targetPosition) + Vector3.new(0, 5, 0)
            end
        end
    end)

    local Toggle = Tabs.Main:AddToggle("ESPToggle", { Title = "DarkBlue Neon ESP", Default = false })
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
    local SpeedSlider = Tabs.Main:AddSlider("SpeedSlider", {
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