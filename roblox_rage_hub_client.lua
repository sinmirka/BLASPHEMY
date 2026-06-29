-- Rage Hub Client
-- Replace GUI_LIBRARY_URL with your raw GitHub link to roblox_prism_gui_library.lua.

local GUI_LIBRARY_URL = "https://cdn.jsdelivr.net/gh/sinmirka/BLASPHEMY@25fc6e3/roblox_prism_gui_library.lua"
local REQUIRED_GUI_LIBRARY_VERSION = "1.1.1"

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local ZERO_VECTOR = Vector3.new(0, 0, 0)

local function deferTask(callback)
    if task and task.defer then
        task.defer(callback)
    elseif task and task.spawn then
        task.spawn(callback)
    else
        coroutine.wrap(callback)()
    end
end

local bootGui = nil
local bootLabel = nil

local function getGuiParentCandidates()
    local parents = {}

    pcall(function()
        if gethui then
            table.insert(parents, gethui())
        end
    end)

    pcall(function()
        table.insert(parents, game:GetService("CoreGui"))
    end)

    if LocalPlayer then
        pcall(function()
            table.insert(parents, LocalPlayer:WaitForChild("PlayerGui", 5))
        end)
    end

    return parents
end

local function ensureBootGui()
    if bootGui then
        return
    end

    bootGui = Instance.new("ScreenGui")
    bootGui.Name = "BLASPHEMY_BootStatus"
    bootGui.ResetOnSpawn = false
    bootGui.IgnoreGuiInset = true
    bootGui.DisplayOrder = 999999

    local frame = Instance.new("Frame")
    frame.Name = "StatusFrame"
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Position = UDim2.new(0.5, 0, 0, 32)
    frame.Size = UDim2.fromOffset(420, 86)
    frame.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
    frame.BorderSizePixel = 0
    frame.Parent = bootGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(76, 211, 171)
    stroke.Transparency = 0.25
    stroke.Thickness = 1
    stroke.Parent = frame

    bootLabel = Instance.new("TextLabel")
    bootLabel.Name = "Status"
    bootLabel.Position = UDim2.fromOffset(14, 10)
    bootLabel.Size = UDim2.new(1, -28, 1, -20)
    bootLabel.BackgroundTransparency = 1
    bootLabel.Font = Enum.Font.GothamSemibold
    bootLabel.Text = "BLASPHEMY\nStarting..."
    bootLabel.TextColor3 = Color3.fromRGB(238, 241, 248)
    bootLabel.TextSize = 13
    bootLabel.TextWrapped = true
    bootLabel.TextXAlignment = Enum.TextXAlignment.Left
    bootLabel.TextYAlignment = Enum.TextYAlignment.Center
    bootLabel.Parent = frame

    for _, parent in ipairs(getGuiParentCandidates()) do
        pcall(function()
            local existing = parent:FindFirstChild(bootGui.Name)
            if existing then
                existing:Destroy()
            end
        end)
    end

    for _, parent in ipairs(getGuiParentCandidates()) do
        local ok = pcall(function()
            bootGui.Parent = parent
        end)

        if ok and bootGui.Parent == parent then
            return
        end
    end
end

local function setBootStatus(message, isError)
    ensureBootGui()

    if bootLabel then
        bootLabel.Text = "BLASPHEMY\n" .. tostring(message)
        bootLabel.TextColor3 = isError and Color3.fromRGB(255, 110, 122) or Color3.fromRGB(238, 241, 248)
    end

    if isError then
        warn("[BLASPHEMY] " .. tostring(message))
    end
end

local function closeBootStatus(delaySeconds)
    local function destroyBoot()
        if bootGui then
            bootGui:Destroy()
            bootGui = nil
            bootLabel = nil
        end
    end

    if task and task.delay then
        task.delay(delaySeconds or 1.25, destroyBoot)
    else
        deferTask(function()
            wait(delaySeconds or 1.25)
            destroyBoot()
        end)
    end
end

setBootStatus("Starting loader...")

local Library = nil

if getgenv then
    pcall(function()
        Library = getgenv().PrismGuiLibrary
    end)
end

if not Library or Library.Version ~= REQUIRED_GUI_LIBRARY_VERSION then
    setBootStatus("Loading GUI library...")

    local ok, loadedLibrary = pcall(function()
        return loadstring(game:HttpGet(GUI_LIBRARY_URL))()
    end)

    if not ok then
        setBootStatus("Failed to load GUI library: " .. tostring(loadedLibrary), true)
        return
    end

    Library = loadedLibrary
end

if not Library or type(Library.CreateWindow) ~= "function" then
    setBootStatus("GUI library loaded, but CreateWindow is missing.", true)
    return
end

setBootStatus("Creating window...")

local windowOk, Window = pcall(function()
    return Library:CreateWindow({
        Name = "PrismRageHub",
        Title = "Prism Rage Hub",
        Subtitle = "RightShift to hide/show",
        Size = Vector2.new(620, 520),
        ToggleKey = Enum.KeyCode.RightShift,
    })
end)

if not windowOk then
    setBootStatus("CreateWindow failed: " .. tostring(Window), true)
    return
end

local tabsOk, RageTab = pcall(function()
    local rage = Window:AddTab("Rage")
    Window:AddTab("AutoFarm")
    Window:AddTab("Alt")
    return rage
end)

if not tabsOk then
    setBootStatus("Tab creation failed: " .. tostring(RageTab), true)
    return
end

setBootStatus("Building features...")

local bootstrapOk, bootstrapErr = xpcall(function()

local function getVirtualInputManager()
    local ok, service = pcall(function()
        return game:GetService("VirtualInputManager")
    end)

    if ok then
        return service
    end

    return nil
end

local VirtualInputManager = getVirtualInputManager()
local warnedVirtualInput = false

local function warnVirtualInput()
    if warnedVirtualInput then
        return
    end

    warnedVirtualInput = true
    warn("[PrismRageHub] VirtualInputManager is unavailable or blocked. Key and mouse simulation may not work here.")
end

local function tryVirtualInput(callback)
    if not VirtualInputManager then
        warnVirtualInput()
        return false
    end

    local ok = pcall(callback)
    if not ok then
        warnVirtualInput()
    end

    return ok
end

local state = {
    autoM1 = false,
    backgroundM1 = false,
    autoSkills = false,
    backgroundSkills = false,
    autoUltimate = false,
    autoBurst = false,
    autoDash = false,
    findLowPlayers = false,
    orbit = false,
    smartOrbit = false,
    cameraLock = false,
    antiVoid = false,
    targetName = "Nearest",
}

local config = {
    autoM1Interval = 0.10,
    backgroundM1Interval = 0.10,
    autoSkillsInterval = 0.10,
    backgroundSkillsInterval = 0.12,
    autoUltimateInterval = 1.00,
    autoBurstInterval = 0.10,
    autoDashInterval = 0.10,
    keyHoldTime = 0.015,
    mouseHoldTime = 0.012,
    orbitRadius = 5,
    orbitSpeed = 20,
    orbitHeight = 0,
    smartRadius = 9,
    smartInterval = 0.28,
    smartMoveSpeed = 26,
    camLockDistance = 12,
    antiVoidSafeY = -8,
    antiVoidTriggerY = -35,
    highlightColor = Color3.fromRGB(255, 38, 38),
}

local loopRunning = {}
local targetDropdown = nil
local targetHighlight = nil
local lastSafeCFrame = nil
local nextHighlightUpdate = 0
local orbitAngle = 0
local smartPoint = nil
local nextSmartPointAt = 0

local function getCharacter()
    return LocalPlayer and LocalPlayer.Character
end

local function getHumanoid(character)
    character = character or getCharacter()
    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(character)
    character = character or getCharacter()
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("UpperTorso")
end

local function getEquippedTool()
    local character = getCharacter()
    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Tool")
end

local function getBackpackTools()
    local tools = {}
    local backpack = LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack")

    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            if child:IsA("Tool") then
                table.insert(tools, child)
            end
        end
    end

    local equipped = getEquippedTool()
    if equipped then
        table.insert(tools, 1, equipped)
    end

    return tools
end

local function activateTool(tool)
    tool = tool or getEquippedTool()
    if not tool then
        return false
    end

    local ok = pcall(function()
        tool:Activate()
    end)

    task.delay(0.03, function()
        pcall(function()
            tool:Deactivate()
        end)
    end)

    return ok
end

local function equipAndActivateSlot(slot)
    local tools = getBackpackTools()
    local tool = tools[slot]
    if not tool then
        return false
    end

    local humanoid = getHumanoid()
    if humanoid and tool.Parent ~= getCharacter() then
        pcall(function()
            humanoid:EquipTool(tool)
        end)
        task.wait(0.025)
    end

    return activateTool(tool)
end

local function getMousePosition()
    local location = UserInputService:GetMouseLocation()
    return math.floor(location.X), math.floor(location.Y)
end

local function sendMouseClick()
    if Window:IsMouseOver() then
        return
    end

    local x, y = getMousePosition()
    local downOk = tryVirtualInput(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
    end)

    task.wait(config.mouseHoldTime)

    local upOk = tryVirtualInput(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)

    if not downOk or not upOk then
        activateTool()
    end
end

local function sendKey(keyCode)
    local downOk = tryVirtualInput(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    end)

    task.wait(config.keyHoldTime)

    local upOk = tryVirtualInput(function()
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)

    return downOk and upOk
end

local function startLoop(name, intervalGetter, callback)
    if loopRunning[name] then
        return
    end

    loopRunning[name] = true

    task.spawn(function()
        if name == "autoM1" then
            task.wait(0.15)
        end

        while state[name] do
            local started = os.clock()
            callback()
            local interval = type(intervalGetter) == "function" and intervalGetter() or intervalGetter
            task.wait(math.max(0, interval - (os.clock() - started)))
        end

        loopRunning[name] = false
    end)
end

local skillKeys = {
    Enum.KeyCode.One,
    Enum.KeyCode.Two,
    Enum.KeyCode.Three,
    Enum.KeyCode.Four,
}

local function setState(name, value)
    state[name] = value == true

    if not state[name] then
        return
    end

    if name == "autoM1" then
        startLoop(name, function()
            return config.autoM1Interval
        end, sendMouseClick)
    elseif name == "backgroundM1" then
        startLoop(name, function()
            return config.backgroundM1Interval
        end, function()
            activateTool()
        end)
    elseif name == "autoSkills" then
        startLoop(name, function()
            return config.autoSkillsInterval
        end, function()
            for _, keyCode in ipairs(skillKeys) do
                if not state.autoSkills then
                    break
                end
                sendKey(keyCode)
            end
        end)
    elseif name == "backgroundSkills" then
        startLoop(name, function()
            return config.backgroundSkillsInterval
        end, function()
            for slot = 1, 4 do
                if not state.backgroundSkills then
                    break
                end
                equipAndActivateSlot(slot)
            end
        end)
    elseif name == "autoUltimate" then
        startLoop(name, function()
            return config.autoUltimateInterval
        end, function()
            sendKey(Enum.KeyCode.G)
        end)
    elseif name == "autoBurst" then
        startLoop(name, function()
            return config.autoBurstInterval
        end, function()
            sendKey(Enum.KeyCode.R)
        end)
    elseif name == "autoDash" then
        startLoop(name, function()
            return config.autoDashInterval
        end, function()
            sendKey(Enum.KeyCode.Q)
        end)
    end
end

local function getTargetOptions()
    local options = { "Nearest" }

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(options, player.Name)
        end
    end

    return options
end

local function getNearestTarget()
    local localRoot = getRoot()
    local nearestPlayer = nil
    local nearestDistance = math.huge

    if not localRoot then
        return nil
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local root = getRoot(player.Character)
            local humanoid = getHumanoid(player.Character)

            if root and humanoid and humanoid.Health > 0 then
                local distance = (root.Position - localRoot.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestPlayer = player
                end
            end
        end
    end

    return nearestPlayer
end

local function getLowestHealthTarget()
    local lowestPlayer = nil
    local lowestScore = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local humanoid = getHumanoid(player.Character)
            local root = getRoot(player.Character)

            if humanoid and root and humanoid.Health > 0 then
                local maxHealth = math.max(humanoid.MaxHealth, 1)
                local healthScore = humanoid.Health / maxHealth

                if healthScore < lowestScore then
                    lowestScore = healthScore
                    lowestPlayer = player
                end
            end
        end
    end

    return lowestPlayer
end

local function getDynamicTarget()
    if state.findLowPlayers then
        return getLowestHealthTarget() or getNearestTarget()
    end

    return getNearestTarget()
end

local function getTargetPlayer()
    if state.targetName ~= "Nearest" then
        local player = Players:FindFirstChild(state.targetName)
        if player and player ~= LocalPlayer then
            return player
        end
    end

    return getDynamicTarget()
end

local function lockDynamicTarget()
    local target = getDynamicTarget()
    if not target then
        return
    end

    state.targetName = target.Name
    smartPoint = nil

    if targetDropdown then
        targetDropdown:SetOptions(getTargetOptions(), state.targetName)
    end
end

local function clearTargetHighlight()
    if targetHighlight then
        targetHighlight:Destroy()
        targetHighlight = nil
    end
end

local function updateTargetHighlight()
    local target = getTargetPlayer()
    local character = target and target.Character

    if not character then
        clearTargetHighlight()
        return
    end

    if not targetHighlight then
        targetHighlight = Instance.new("Highlight")
        targetHighlight.Name = "PrismTargetHighlight"
        targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        targetHighlight.FillTransparency = 0.65
        targetHighlight.OutlineTransparency = 0.05
    end

    targetHighlight.FillColor = config.highlightColor
    targetHighlight.OutlineColor = config.highlightColor
    targetHighlight.Adornee = character
    targetHighlight.Parent = character
end

local function pickSmartPoint(targetRoot)
    local angle = math.random() * math.pi * 2
    local radius = config.smartRadius * (0.62 + math.random() * 0.58)
    local height = config.orbitHeight + math.random(-2, 2)
    local offset = Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)

    smartPoint = targetRoot.Position + offset
    nextSmartPointAt = os.clock() + config.smartInterval
end

RunService.Heartbeat:Connect(function(deltaTime)
    local root = getRoot()

    if root then
        if root.Position.Y > config.antiVoidSafeY then
            lastSafeCFrame = root.CFrame
        elseif state.antiVoid and root.Position.Y < config.antiVoidTriggerY and lastSafeCFrame then
            root.AssemblyLinearVelocity = ZERO_VECTOR
            root.AssemblyAngularVelocity = ZERO_VECTOR
            root.CFrame = lastSafeCFrame + Vector3.new(0, 4, 0)
        end
    end

    if os.clock() >= nextHighlightUpdate then
        nextHighlightUpdate = os.clock() + 0.20
        updateTargetHighlight()
    end

    if not state.orbit and not state.smartOrbit then
        return
    end

    local targetPlayer = getTargetPlayer()
    local targetRoot = targetPlayer and getRoot(targetPlayer.Character)

    if not root or not targetRoot then
        return
    end

    if state.smartOrbit then
        if not smartPoint or os.clock() >= nextSmartPointAt then
            pickSmartPoint(targetRoot)
        end

        local alpha = math.clamp(deltaTime * config.smartMoveSpeed, 0, 1)
        local nextPosition = root.Position:Lerp(smartPoint, alpha)
        root.AssemblyLinearVelocity = ZERO_VECTOR
        root.AssemblyAngularVelocity = ZERO_VECTOR
        root.CFrame = CFrame.new(nextPosition, targetRoot.Position)
        return
    end

    orbitAngle = (orbitAngle + deltaTime * config.orbitSpeed) % (math.pi * 2)

    local offset = Vector3.new(
        math.cos(orbitAngle) * config.orbitRadius,
        config.orbitHeight,
        math.sin(orbitAngle) * config.orbitRadius
    )

    local position = targetRoot.Position + offset
    root.AssemblyLinearVelocity = ZERO_VECTOR
    root.AssemblyAngularVelocity = ZERO_VECTOR
    root.CFrame = CFrame.new(position, targetRoot.Position)
end)

RunService.RenderStepped:Connect(function()
    if not state.cameraLock then
        return
    end

    local camera = workspace.CurrentCamera
    local root = getRoot()
    local targetPlayer = getTargetPlayer()
    local targetRoot = targetPlayer and getRoot(targetPlayer.Character)

    if not camera or not root or not targetRoot then
        return
    end

    if (targetRoot.Position - root.Position).Magnitude > config.camLockDistance then
        return
    end

    camera.CFrame = CFrame.new(camera.CFrame.Position, targetRoot.Position + Vector3.new(0, 1.8, 0))
end)

RageTab:AddSection("Target")

targetDropdown = RageTab:AddDropdown({
    Name = "Select Target Player",
    Options = getTargetOptions(),
    Default = "Nearest",
    Callback = function(value)
        state.targetName = value or "Nearest"
        smartPoint = nil
    end,
})

RageTab:AddKeybind({
    Name = "Target Bind",
    Default = nil,
    Callback = function()
        lockDynamicTarget()
    end,
})

RageTab:AddButton({
    Name = "Refresh Target List",
    Callback = function()
        targetDropdown:SetOptions(getTargetOptions(), state.targetName)
    end,
})

Players.PlayerAdded:Connect(function()
    deferTask(function()
        targetDropdown:SetOptions(getTargetOptions(), state.targetName)
    end)
end)

Players.PlayerRemoving:Connect(function()
    deferTask(function()
        targetDropdown:SetOptions(getTargetOptions(), state.targetName)
    end)
end)

RageTab:AddToggle({
    Name = "Find Low Players",
    Description = "Prefer lowest-health target",
    Default = false,
    Callback = function(value)
        state.findLowPlayers = value
        smartPoint = nil
    end,
})

RageTab:AddToggle({
    Name = "Smart Orbit",
    Description = "Jump between random points around target",
    Default = false,
    Callback = function(value)
        state.smartOrbit = value
        smartPoint = nil
    end,
})

RageTab:AddToggle({
    Name = "Camera Lock on Target",
    Description = "Aim camera at selected target",
    Default = false,
    Callback = function(value)
        state.cameraLock = value
    end,
})

RageTab:AddToggle({
    Name = "Enable Anti-Void",
    Description = "Return to last safe position if falling",
    Default = false,
    Callback = function(value)
        state.antiVoid = value
    end,
})

RageTab:AddColorPicker({
    Name = "Highlight Customization",
    Default = config.highlightColor,
    Callback = function(value)
        config.highlightColor = value
        updateTargetHighlight()
    end,
})

RageTab:AddSection("Movement")

RageTab:AddToggle({
    Name = "Orbit",
    Description = "Spin around selected target",
    Default = false,
    Callback = function(value)
        state.orbit = value
        if value then
            smartPoint = nil
        end
    end,
})

RageTab:AddSlider({
    Name = "Orbit Distance",
    Min = 1,
    Max = 50,
    Default = config.orbitRadius,
    Increment = 1,
    Suffix = "/50",
    Callback = function(value)
        config.orbitRadius = value
    end,
})

RageTab:AddSlider({
    Name = "Orbit Rotation Speed",
    Min = 2,
    Max = 100,
    Default = config.orbitSpeed,
    Increment = 1,
    Suffix = "/100",
    Callback = function(value)
        config.orbitSpeed = value
    end,
})

RageTab:AddSlider({
    Name = "CamLock Distance",
    Min = 1,
    Max = 50,
    Default = config.camLockDistance,
    Increment = 1,
    Suffix = "/50",
    Callback = function(value)
        config.camLockDistance = value
    end,
})

RageTab:AddSlider({
    Name = "Orbit Height",
    Min = -8,
    Max = 12,
    Default = config.orbitHeight,
    Increment = 1,
    Suffix = " studs",
    Callback = function(value)
        config.orbitHeight = value
        smartPoint = nil
    end,
})

RageTab:AddSlider({
    Name = "Smart Radius",
    Min = 4,
    Max = 26,
    Default = config.smartRadius,
    Increment = 1,
    Suffix = " studs",
    Callback = function(value)
        config.smartRadius = value
        smartPoint = nil
    end,
})

RageTab:AddSlider({
    Name = "Smart Swap Delay",
    Min = 0.08,
    Max = 1.20,
    Default = config.smartInterval,
    Increment = 0.02,
    Suffix = "s",
    Callback = function(value)
        config.smartInterval = value
    end,
})

RageTab:AddSlider({
    Name = "Smart Move Speed",
    Min = 6,
    Max = 60,
    Default = config.smartMoveSpeed,
    Increment = 1,
    Suffix = "x",
    Callback = function(value)
        config.smartMoveSpeed = value
    end,
})

RageTab:AddSection("Combat")

RageTab:AddToggle({
    Name = "Auto M1",
    Description = "Left mouse click at 10 cps",
    Default = false,
    Callback = function(value)
        setState("autoM1", value)
    end,
})

RageTab:AddToggle({
    Name = "Background M1",
    Description = "Tool:Activate at 10 cps",
    Default = false,
    Callback = function(value)
        setState("backgroundM1", value)
    end,
})

RageTab:AddToggle({
    Name = "Auto Skills",
    Description = "Press keys 1, 2, 3, 4",
    Default = false,
    Callback = function(value)
        setState("autoSkills", value)
    end,
})

RageTab:AddToggle({
    Name = "Background Skills",
    Description = "Equip and activate first 4 tools",
    Default = false,
    Callback = function(value)
        setState("backgroundSkills", value)
    end,
})

RageTab:AddToggle({
    Name = "Auto Ultimate",
    Description = "Press G once per second",
    Default = false,
    Callback = function(value)
        setState("autoUltimate", value)
    end,
})

RageTab:AddToggle({
    Name = "Auto Burst",
    Description = "Spam R at 10 cps",
    Default = false,
    Callback = function(value)
        setState("autoBurst", value)
    end,
})

RageTab:AddToggle({
    Name = "Auto Dash/Wall Combo",
    Description = "Spam Q at 10 cps",
    Default = false,
    Callback = function(value)
        setState("autoDash", value)
    end,
})

RageTab:AddSection("Timings")

RageTab:AddSlider({
    Name = "M1 Delay",
    Min = 0.03,
    Max = 0.50,
    Default = config.autoM1Interval,
    Increment = 0.01,
    Suffix = "s",
    Callback = function(value)
        config.autoM1Interval = value
        config.backgroundM1Interval = value
    end,
})

RageTab:AddSlider({
    Name = "Skill Delay",
    Min = 0.03,
    Max = 0.60,
    Default = config.autoSkillsInterval,
    Increment = 0.01,
    Suffix = "s",
    Callback = function(value)
        config.autoSkillsInterval = value
        config.backgroundSkillsInterval = value
    end,
})

RageTab:AddSlider({
    Name = "Burst/Dash Delay",
    Min = 0.03,
    Max = 0.60,
    Default = config.autoBurstInterval,
    Increment = 0.01,
    Suffix = "s",
    Callback = function(value)
        config.autoBurstInterval = value
        config.autoDashInterval = value
    end,
})

RageTab:AddSlider({
    Name = "Ultimate Delay",
    Min = 0.30,
    Max = 5.00,
    Default = config.autoUltimateInterval,
    Increment = 0.05,
    Suffix = "s",
    Callback = function(value)
        config.autoUltimateInterval = value
    end,
})
end, function(err)
    if debug and debug.traceback then
        return debug.traceback(err)
    end

    return tostring(err)
end)

if not bootstrapOk then
    setBootStatus("Runtime error: " .. tostring(bootstrapErr), true)
    return
end

setBootStatus("Loaded.")
closeBootStatus(1.5)
