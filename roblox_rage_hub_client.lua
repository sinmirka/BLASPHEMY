-- Blasphemy Client
-- Replace GUI_LIBRARY_URL with your raw GitHub link to roblox_prism_gui_library.lua.

local GUI_LIBRARY_URL = "https://raw.githubusercontent.com/sinmirka/BLASPHEMY/main/roblox_prism_gui_library.lua?v=1.4.0"
local REQUIRED_GUI_LIBRARY_VERSION = "1.4.0"

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local ZERO_VECTOR = Vector3.new(0, 0, 0)
local SELF_RELOAD_URL = "https://raw.githubusercontent.com/sinmirka/BLASPHEMY/main/roblox_rage_hub_client.lua"

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
    bootLabel.Text = "Blasphemy\nStarting..."
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
        bootLabel.Text = "Blasphemy\n" .. tostring(message)
        bootLabel.TextColor3 = isError and Color3.fromRGB(255, 110, 122) or Color3.fromRGB(238, 241, 248)
    end

    if isError then
        warn("[Blasphemy] " .. tostring(message))
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
        Name = "Blasphemy",
        Title = "Blasphemy",
        Subtitle = "RightShift to hide/show",
        Size = Vector2.new(620, 520),
        ToggleKey = Enum.KeyCode.RightShift,
    })
end)

if not windowOk then
    setBootStatus("CreateWindow failed: " .. tostring(Window), true)
    return
end

local watermarkGui = nil
local watermarkFrame = nil
local watermarkTitle = nil
local watermarkStats = nil
local watermarkAccent = nil
local watermarkStroke = nil

local function getActiveTheme()
    local themeName = "Dark"

    if Window and type(Window.GetTheme) == "function" then
        local ok, currentTheme = pcall(function()
            return Window:GetTheme()
        end)

        if ok and type(currentTheme) == "string" then
            themeName = currentTheme
        end
    end

    if Library and Library.Themes then
        return Library.Themes[themeName] or Library.Themes.Dark
    end

    return {
        BackgroundSoft = Color3.fromRGB(20, 23, 31),
        Card = Color3.fromRGB(27, 31, 42),
        CardHover = Color3.fromRGB(33, 38, 51),
        Stroke = Color3.fromRGB(58, 67, 86),
        Text = Color3.fromRGB(240, 243, 249),
        Muted = Color3.fromRGB(143, 153, 171),
        Accent = Color3.fromRGB(76, 211, 171),
        AccentBlue = Color3.fromRGB(91, 148, 255),
    }
end

local function applyWatermarkTheme()
    if not watermarkFrame then
        return
    end

    local theme = getActiveTheme()
    watermarkFrame.BackgroundColor3 = theme.Card or Color3.fromRGB(27, 31, 42)

    if watermarkTitle then
        watermarkTitle.TextColor3 = theme.Text or Color3.fromRGB(240, 243, 249)
    end

    if watermarkStats then
        watermarkStats.TextColor3 = theme.Muted or Color3.fromRGB(143, 153, 171)
    end

    if watermarkAccent then
        watermarkAccent.BackgroundColor3 = theme.Accent or Color3.fromRGB(76, 211, 171)
    end

    if watermarkStroke then
        watermarkStroke.Color = theme.Stroke or Color3.fromRGB(58, 67, 86)
    end
end

local function parentWatermarkGui(screenGui)
    for _, parent in ipairs(getGuiParentCandidates()) do
        pcall(function()
            local existing = parent:FindFirstChild(screenGui.Name)
            if existing then
                existing:Destroy()
            end
        end)
    end

    for _, parent in ipairs(getGuiParentCandidates()) do
        local ok = pcall(function()
            screenGui.Parent = parent
        end)

        if ok and screenGui.Parent == parent then
            return true
        end
    end

    return false
end

local function readPingMs()
    if LocalPlayer and type(LocalPlayer.GetNetworkPing) == "function" then
        local ok, pingSeconds = pcall(function()
            return LocalPlayer:GetNetworkPing()
        end)

        if ok and type(pingSeconds) == "number" then
            return math.max(0, math.floor((pingSeconds * 1000) + 0.5))
        end
    end

    local okStats, stats = pcall(function()
        return game:GetService("Stats")
    end)

    if okStats and stats then
        local okItem, pingItem = pcall(function()
            return stats.Network.ServerStatsItem["Data Ping"]
        end)

        if okItem and pingItem then
            local okValue, value = pcall(function()
                return pingItem:GetValue()
            end)

            if okValue and type(value) == "number" then
                return math.max(0, math.floor(value + 0.5))
            end

            local okText, text = pcall(function()
                return pingItem:GetValueString()
            end)

            if okText then
                local numberText = tostring(text):match("[%d%.]+")
                local numericValue = numberText and tonumber(numberText)

                if numericValue then
                    return math.max(0, math.floor(numericValue + 0.5))
                end
            end
        end
    end

    return nil
end

local function createBlasphemyWatermark()
    watermarkGui = Instance.new("ScreenGui")
    watermarkGui.Name = "BlasphemyWatermark"
    watermarkGui.ResetOnSpawn = false
    watermarkGui.IgnoreGuiInset = true
    watermarkGui.DisplayOrder = 1000001
    watermarkGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    watermarkFrame = Instance.new("Frame")
    watermarkFrame.Name = "Root"
    watermarkFrame.AnchorPoint = Vector2.new(0.5, 0)
    watermarkFrame.Position = UDim2.new(0.5, 0, 0, 10)
    watermarkFrame.Size = UDim2.fromOffset(312, 34)
    watermarkFrame.BorderSizePixel = 0
    watermarkFrame.Parent = watermarkGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = watermarkFrame

    watermarkStroke = Instance.new("UIStroke")
    watermarkStroke.Transparency = 0.18
    watermarkStroke.Thickness = 1
    watermarkStroke.Parent = watermarkFrame

    watermarkAccent = Instance.new("Frame")
    watermarkAccent.Name = "Accent"
    watermarkAccent.BorderSizePixel = 0
    watermarkAccent.Position = UDim2.fromOffset(10, 8)
    watermarkAccent.Size = UDim2.fromOffset(3, 18)
    watermarkAccent.Parent = watermarkFrame

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 1)
    accentCorner.Parent = watermarkAccent

    watermarkTitle = Instance.new("TextLabel")
    watermarkTitle.Name = "Title"
    watermarkTitle.BackgroundTransparency = 1
    watermarkTitle.Position = UDim2.fromOffset(19, 0)
    watermarkTitle.Size = UDim2.new(0, 120, 1, 0)
    watermarkTitle.Font = Enum.Font.GothamSemibold
    watermarkTitle.Text = "Blasphemy Script"
    watermarkTitle.TextSize = 12
    watermarkTitle.TextXAlignment = Enum.TextXAlignment.Left
    watermarkTitle.TextTruncate = Enum.TextTruncate.AtEnd
    watermarkTitle.Parent = watermarkFrame

    watermarkStats = Instance.new("TextLabel")
    watermarkStats.Name = "Stats"
    watermarkStats.BackgroundTransparency = 1
    watermarkStats.Position = UDim2.fromOffset(144, 0)
    watermarkStats.Size = UDim2.new(1, -156, 1, 0)
    watermarkStats.Font = Enum.Font.GothamMedium
    watermarkStats.Text = "PING -- ms  |  FPS --"
    watermarkStats.TextSize = 11
    watermarkStats.TextXAlignment = Enum.TextXAlignment.Right
    watermarkStats.TextTruncate = Enum.TextTruncate.AtEnd
    watermarkStats.Parent = watermarkFrame

    if not parentWatermarkGui(watermarkGui) then
        watermarkGui:Destroy()
        watermarkGui = nil
        watermarkFrame = nil
        watermarkTitle = nil
        watermarkStats = nil
        watermarkAccent = nil
        watermarkStroke = nil
        return
    end

    applyWatermarkTheme()

    local frames = 0
    local fps = 0
    local lastFpsAt = os.clock()
    local lastTextAt = 0
    local nextPingAt = 0
    local pingText = "--"

    RunService.RenderStepped:Connect(function()
        if not watermarkStats or not watermarkStats.Parent then
            return
        end

        frames = frames + 1

        local now = os.clock()
        local elapsed = now - lastFpsAt

        if elapsed >= 0.5 then
            fps = math.floor((frames / elapsed) + 0.5)
            frames = 0
            lastFpsAt = now
        end

        if now >= nextPingAt then
            local ping = readPingMs()
            pingText = ping and tostring(ping) or "--"
            nextPingAt = now + 1
        end

        if now - lastTextAt >= 0.20 then
            watermarkStats.Text = "PING " .. pingText .. " ms  |  FPS " .. tostring(fps)
            lastTextAt = now
        end
    end)
end

createBlasphemyWatermark()

local tabsOk, RageTab, CombatTab, PlayerTab, OptimizationsTab, AutoFarmTab, AltTab, SettingsTab = pcall(function()
    local rage = Window:AddTab("Rage")
    local combat = Window:AddTab("Combat")
    local player = Window:AddTab("Player")
    local optimizations = Window:AddTab("Optimizations")
    local autoFarm = Window:AddTab("AutoFarm")
    local alt = Window:AddTab("Alt")
    local settings = Window:AddTab("Settings")
    return rage, combat, player, optimizations, autoFarm, alt, settings
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
    warn("[Blasphemy] VirtualInputManager is unavailable or blocked. Key and mouse simulation may not work here.")
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
    autoUltimate = false,
    autoBurst = false,
    autoDash = false,
    autoEvasive = false,
    playerWalkSpeed = false,
    playerJumpPower = false,
    playerFly = false,
    optNoShadows = false,
    optNoTextures = false,
    optNoEffects = false,
    optLowMaterials = false,
    optTerrainLite = false,
    optLowLighting = false,
    optNo3DRender = false,
    antiAfk = false,
    autoReconnect = false,
    queueScriptOnTeleport = true,
    autoFarmPositionLock = false,
    altAutoReset = false,
    altPositionLock = false,
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
    autoUltimateInterval = 1.00,
    autoBurstInterval = 0.10,
    autoDashInterval = 0.10,
    autoEvasiveInterval = 0.10,
    autoFarmTeleportInterval = 0.12,
    altTeleportInterval = 0.12,
    walkSpeedValue = 32,
    walkSpeedMethod = "Humanoid",
    jumpPowerValue = 75,
    jumpPowerMethod = "JumpPower",
    flySpeed = 55,
    flyMethod = "CFrame",
    altAutoResetDelay = 0.00,
    altRespawnTeleportDelay = 1.00,
    optTextureTransparency = 1.00,
    antiAfkMethod = "Mixed",
    antiAfkInterval = 120.00,
    autoReconnectDelay = 3.00,
    evasiveSideHoldTime = 0.045,
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
local controls = {}
local settings = {
    theme = "Dark",
    selectedConfig = "default",
    menuBind = "RightShift",
}
local targetList = {}
local friendList = {}

local WALK_SPEED_METHODS = { "Humanoid", "CFrame", "Velocity" }
local JUMP_POWER_METHODS = { "JumpPower", "JumpHeight", "Velocity Boost" }
local FLY_METHODS = { "CFrame", "Velocity", "BodyMover" }
local ANTI_AFK_METHODS = { "Mixed", "VirtualUser", "VirtualInput", "Camera Nudge" }

local stateKeys = {
    "autoM1",
    "backgroundM1",
    "autoSkills",
    "autoUltimate",
    "autoBurst",
    "autoDash",
    "autoEvasive",
    "playerWalkSpeed",
    "playerJumpPower",
    "playerFly",
    "optNoShadows",
    "optNoTextures",
    "optNoEffects",
    "optLowMaterials",
    "optTerrainLite",
    "optLowLighting",
    "optNo3DRender",
    "antiAfk",
    "autoReconnect",
    "queueScriptOnTeleport",
    "autoFarmPositionLock",
    "altAutoReset",
    "altPositionLock",
    "findLowPlayers",
    "orbit",
    "smartOrbit",
    "cameraLock",
    "antiVoid",
}

local configKeys = {
    "autoM1Interval",
    "backgroundM1Interval",
    "autoSkillsInterval",
    "autoUltimateInterval",
    "autoBurstInterval",
    "autoDashInterval",
    "autoEvasiveInterval",
    "autoFarmTeleportInterval",
    "altTeleportInterval",
    "walkSpeedValue",
    "walkSpeedMethod",
    "jumpPowerValue",
    "jumpPowerMethod",
    "flySpeed",
    "flyMethod",
    "altAutoResetDelay",
    "altRespawnTeleportDelay",
    "optTextureTransparency",
    "antiAfkMethod",
    "antiAfkInterval",
    "autoReconnectDelay",
    "evasiveSideHoldTime",
    "keyHoldTime",
    "mouseHoldTime",
    "orbitRadius",
    "orbitSpeed",
    "orbitHeight",
    "smartRadius",
    "smartInterval",
    "smartMoveSpeed",
    "camLockDistance",
    "antiVoidSafeY",
    "antiVoidTriggerY",
}

local CONFIG_ROOT = "BLASPHEMY"
local CONFIG_DIR = CONFIG_ROOT .. "/configs"

local targetDropdown = nil
local targetHighlight = nil
local autoFarmSavedCFrame = nil
local altSavedCFrame = nil
local autoFarmPositionLabel = nil
local altPositionLabel = nil
local autoResetConnection = nil
local autoResetVersion = 0
local altTeleportConnection = nil
local altTeleportDiedConnection = nil
local altTeleportReady = false
local altTeleportVersion = 0
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyBodyRoot = nil
local optimizationOriginals = setmetatable({}, { __mode = "k" })
local optimizationWorkspaceConnection = nil
local optimizationLightingConnection = nil
local optimizationWhiteOverlay = nil
local warned3DRenderToggle = false
local antiAfkIdleConnection = nil
local antiAfkLoopRunning = false
local autoReconnectConnections = {}
local autoReconnectPending = false
local autoLoadLabel = nil
local lastJumpBoostAt = 0
local lastSafeCFrame = nil
local nextHighlightUpdate = 0
local orbitAngle = 0
local smartPoint = nil
local nextSmartPointAt = 0
local updateTargetHighlight = nil

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

local function formatCFramePosition(cframe)
    if typeof(cframe) ~= "CFrame" then
        return "none"
    end

    local position = cframe.Position
    return string.format("%.1f, %.1f, %.1f", position.X, position.Y, position.Z)
end

local function updateSavedPositionLabel(label, cframe)
    if not label then
        return
    end

    local textLabel = label:FindFirstChild("Text")
    if textLabel then
        textLabel.Text = "Saved: " .. formatCFramePosition(cframe)
    end
end

local function updateSavedPositionLabels()
    updateSavedPositionLabel(autoFarmPositionLabel, autoFarmSavedCFrame)
    updateSavedPositionLabel(altPositionLabel, altSavedCFrame)
end

local function getSavedPosition(name)
    if name == "autoFarm" then
        return autoFarmSavedCFrame
    end

    if name == "alt" then
        return altSavedCFrame
    end

    return nil
end

local function setSavedPosition(name, cframe)
    if typeof(cframe) ~= "CFrame" then
        return false
    end

    if name == "autoFarm" then
        autoFarmSavedCFrame = cframe
    elseif name == "alt" then
        altSavedCFrame = cframe
    else
        return false
    end

    updateSavedPositionLabels()
    return true
end

local function saveCurrentPosition(name)
    local root = getRoot()
    if not root then
        return false
    end

    return setSavedPosition(name, root.CFrame)
end

local function teleportToCFrame(cframe)
    if typeof(cframe) ~= "CFrame" then
        return false
    end

    local character = getCharacter()
    local root = getRoot(character)
    if not character or not root then
        return false
    end

    pcall(function()
        root.AssemblyLinearVelocity = ZERO_VECTOR
        root.AssemblyAngularVelocity = ZERO_VECTOR
    end)

    local ok = pcall(function()
        character:PivotTo(cframe)
    end)

    if not ok then
        ok = pcall(function()
            root.CFrame = cframe
        end)
    end

    return ok
end

local function teleportToSavedPosition(name)
    return teleportToCFrame(getSavedPosition(name))
end

local function resetCharacter(character)
    character = character or getCharacter()
    if not character then
        return false
    end

    local humanoid = getHumanoid(character)
    if humanoid and humanoid.Health > 0 then
        humanoid.Health = 0
        return true
    end

    local ok = pcall(function()
        character:BreakJoints()
    end)

    return ok
end

local function scheduleAutoReset(character)
    if not state.altAutoReset or not character then
        return
    end

    autoResetVersion = autoResetVersion + 1
    local token = autoResetVersion

    deferTask(function()
        local startedAt = os.clock()
        local humanoid = getHumanoid(character)

        while state.altAutoReset
            and token == autoResetVersion
            and character.Parent
            and not humanoid
            and os.clock() - startedAt < 5 do
            task.wait(0.05)
            humanoid = getHumanoid(character)
        end

        local delaySeconds = math.max(0, tonumber(config.altAutoResetDelay) or 0)
        local resetAt = os.clock() + delaySeconds

        while state.altAutoReset
            and token == autoResetVersion
            and character.Parent
            and os.clock() < resetAt do
            task.wait(math.max(0, math.min(0.05, resetAt - os.clock())))
        end

        if state.altAutoReset and token == autoResetVersion and character.Parent then
            resetCharacter(character)
        end
    end)
end

local function enableAutoReset()
    if not LocalPlayer then
        return
    end

    if not autoResetConnection then
        autoResetConnection = LocalPlayer.CharacterAdded:Connect(function(character)
            scheduleAutoReset(character)
        end)
    end

    scheduleAutoReset(getCharacter())
end

local function disableAutoReset()
    autoResetVersion = autoResetVersion + 1

    if autoResetConnection then
        autoResetConnection:Disconnect()
        autoResetConnection = nil
    end
end

local function disconnectAltTeleportDied()
    if altTeleportDiedConnection then
        altTeleportDiedConnection:Disconnect()
        altTeleportDiedConnection = nil
    end
end

local function pauseAltTeleportCycle()
    altTeleportReady = false
end

local function canAltTeleport()
    if not state.altPositionLock or not altTeleportReady then
        return false
    end

    local character = getCharacter()
    local humanoid = getHumanoid(character)
    local root = getRoot(character)

    return character ~= nil and humanoid ~= nil and root ~= nil and humanoid.Health > 0
end

local function scheduleAltTeleportForCharacter(character, useRespawnDelay)
    if not state.altPositionLock or not character then
        pauseAltTeleportCycle()
        return
    end

    altTeleportVersion = altTeleportVersion + 1
    local token = altTeleportVersion
    pauseAltTeleportCycle()
    disconnectAltTeleportDied()

    deferTask(function()
        local startedAt = os.clock()
        local humanoid = getHumanoid(character)
        local root = getRoot(character)

        while state.altPositionLock
            and token == altTeleportVersion
            and character.Parent
            and (not humanoid or not root)
            and os.clock() - startedAt < 8 do
            task.wait(0.05)
            humanoid = getHumanoid(character)
            root = getRoot(character)
        end

        if not state.altPositionLock
            or token ~= altTeleportVersion
            or not character.Parent
            or not humanoid
            or not root
            or humanoid.Health <= 0 then
            pauseAltTeleportCycle()
            return
        end

        altTeleportDiedConnection = humanoid.Died:Connect(function()
            if token == altTeleportVersion then
                pauseAltTeleportCycle()
            end
        end)

        local delaySeconds = useRespawnDelay and math.max(0, tonumber(config.altRespawnTeleportDelay) or 0) or 0
        local teleportAt = os.clock() + delaySeconds

        while state.altPositionLock
            and token == altTeleportVersion
            and character.Parent
            and humanoid.Health > 0
            and os.clock() < teleportAt do
            task.wait(math.max(0, math.min(0.05, teleportAt - os.clock())))
        end

        if state.altPositionLock
            and token == altTeleportVersion
            and character.Parent
            and humanoid.Health > 0
            and getRoot(character) then
            altTeleportReady = true
            teleportToSavedPosition("alt")
        end
    end)
end

local function startAltTeleportLoop()
    if loopRunning.altPositionLock then
        return
    end

    loopRunning.altPositionLock = true

    task.spawn(function()
        while state.altPositionLock do
            local started = os.clock()

            if canAltTeleport() then
                teleportToSavedPosition("alt")
            end

            task.wait(math.max(0, config.altTeleportInterval - (os.clock() - started)))
        end

        loopRunning.altPositionLock = false
    end)
end

local function enableAltPositionLock()
    if not altSavedCFrame and not saveCurrentPosition("alt") then
        return false
    end

    if LocalPlayer and not altTeleportConnection then
        altTeleportConnection = LocalPlayer.CharacterAdded:Connect(function(character)
            scheduleAltTeleportForCharacter(character, true)
        end)
    end

    scheduleAltTeleportForCharacter(getCharacter(), false)
    startAltTeleportLoop()
    return true
end

local function disableAltPositionLock()
    altTeleportVersion = altTeleportVersion + 1
    pauseAltTeleportCycle()
    disconnectAltTeleportDied()

    if altTeleportConnection then
        altTeleportConnection:Disconnect()
        altTeleportConnection = nil
    end
end

local function isOption(value, options)
    for _, option in ipairs(options) do
        if value == option then
            return true
        end
    end

    return false
end

local function normalizeOption(value, options, fallback)
    if isOption(value, options) then
        return value
    end

    return fallback
end

local optimizationStateKeys = {
    optNoShadows = true,
    optNoTextures = true,
    optNoEffects = true,
    optLowMaterials = true,
    optTerrainLite = true,
    optLowLighting = true,
    optNo3DRender = true,
}

local function rememberProperty(instance, property)
    if not instance then
        return false
    end

    local values = optimizationOriginals[instance]
    if not values then
        values = {}
        optimizationOriginals[instance] = values
    end

    if values[property] ~= nil then
        return true
    end

    local ok, value = pcall(function()
        return instance[property]
    end)

    if ok then
        values[property] = value
        return true
    end

    return false
end

local function setRememberedProperty(instance, property, value)
    if rememberProperty(instance, property) then
        pcall(function()
            instance[property] = value
        end)
    end
end

local function restoreRememberedProperty(instance, property)
    local values = optimizationOriginals[instance]
    if not values or values[property] == nil then
        return
    end

    local originalValue = values[property]
    pcall(function()
        instance[property] = originalValue
    end)

    values[property] = nil
end

local function restorePropertiesFor(predicate, properties)
    for instance in pairs(optimizationOriginals) do
        if predicate(instance) then
            for _, property in ipairs(properties) do
                restoreRememberedProperty(instance, property)
            end
        end
    end
end

local function applyShadowOptimizationTo(instance)
    if instance == Lighting then
        setRememberedProperty(Lighting, "GlobalShadows", false)
    elseif instance:IsA("BasePart") then
        setRememberedProperty(instance, "CastShadow", false)
    end
end

local function restoreShadowOptimization()
    restoreRememberedProperty(Lighting, "GlobalShadows")
    restorePropertiesFor(function(instance)
        return instance:IsA("BasePart")
    end, { "CastShadow" })
end

local function applyTextureOptimizationTo(instance)
    local transparency = math.clamp(tonumber(config.optTextureTransparency) or 1, 0, 1)

    if instance:IsA("Decal") or instance:IsA("Texture") then
        setRememberedProperty(instance, "Transparency", transparency)
    elseif instance:IsA("MeshPart") then
        setRememberedProperty(instance, "TextureID", "")
    elseif instance:IsA("SpecialMesh") then
        setRememberedProperty(instance, "TextureId", "")
    elseif instance:IsA("SurfaceAppearance") then
        setRememberedProperty(instance, "ColorMap", "")
        setRememberedProperty(instance, "MetalnessMap", "")
        setRememberedProperty(instance, "NormalMap", "")
        setRememberedProperty(instance, "RoughnessMap", "")
    end
end

local function restoreTextureOptimization()
    restorePropertiesFor(function(instance)
        return instance:IsA("Decal") or instance:IsA("Texture")
    end, { "Transparency" })

    restorePropertiesFor(function(instance)
        return instance:IsA("MeshPart")
    end, { "TextureID" })

    restorePropertiesFor(function(instance)
        return instance:IsA("SpecialMesh")
    end, { "TextureId" })

    restorePropertiesFor(function(instance)
        return instance:IsA("SurfaceAppearance")
    end, { "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap" })
end

local function applyEffectsOptimizationTo(instance)
    if instance:IsA("ParticleEmitter")
        or instance:IsA("Trail")
        or instance:IsA("Beam")
        or instance:IsA("Smoke")
        or instance:IsA("Fire")
        or instance:IsA("Sparkles")
        or instance:IsA("PostEffect") then
        setRememberedProperty(instance, "Enabled", false)
    elseif instance:IsA("Explosion") then
        setRememberedProperty(instance, "Visible", false)
    end
end

local function restoreEffectsOptimization()
    restorePropertiesFor(function(instance)
        return instance:IsA("ParticleEmitter")
            or instance:IsA("Trail")
            or instance:IsA("Beam")
            or instance:IsA("Smoke")
            or instance:IsA("Fire")
            or instance:IsA("Sparkles")
            or instance:IsA("PostEffect")
    end, { "Enabled" })

    restorePropertiesFor(function(instance)
        return instance:IsA("Explosion")
    end, { "Visible" })
end

local function applyMaterialOptimizationTo(instance)
    if instance:IsA("BasePart") then
        setRememberedProperty(instance, "Material", Enum.Material.SmoothPlastic)
        setRememberedProperty(instance, "Reflectance", 0)
    end

    if instance:IsA("MeshPart") then
        setRememberedProperty(instance, "RenderFidelity", Enum.RenderFidelity.Performance)
    end
end

local function restoreMaterialOptimization()
    restorePropertiesFor(function(instance)
        return instance:IsA("BasePart")
    end, { "Material", "Reflectance" })

    restorePropertiesFor(function(instance)
        return instance:IsA("MeshPart")
    end, { "RenderFidelity" })
end

local function applyTerrainOptimization()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return
    end

    setRememberedProperty(terrain, "Decoration", false)
    setRememberedProperty(terrain, "WaterWaveSize", 0)
    setRememberedProperty(terrain, "WaterWaveSpeed", 0)
    setRememberedProperty(terrain, "WaterReflectance", 0)
    setRememberedProperty(terrain, "WaterTransparency", 1)
end

local function restoreTerrainOptimization()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        restoreRememberedProperty(terrain, "Decoration")
        restoreRememberedProperty(terrain, "WaterWaveSize")
        restoreRememberedProperty(terrain, "WaterWaveSpeed")
        restoreRememberedProperty(terrain, "WaterReflectance")
        restoreRememberedProperty(terrain, "WaterTransparency")
    end
end

local function applyLightingOptimization()
    setRememberedProperty(Lighting, "Brightness", 1)
    setRememberedProperty(Lighting, "EnvironmentDiffuseScale", 0)
    setRememberedProperty(Lighting, "EnvironmentSpecularScale", 0)
    setRememberedProperty(Lighting, "FogEnd", 100000)
    setRememberedProperty(Lighting, "FogStart", 0)
    setRememberedProperty(Lighting, "OutdoorAmbient", Color3.fromRGB(128, 128, 128))
    setRememberedProperty(Lighting, "Ambient", Color3.fromRGB(128, 128, 128))
end

local function restoreLightingOptimization()
    restoreRememberedProperty(Lighting, "Brightness")
    restoreRememberedProperty(Lighting, "EnvironmentDiffuseScale")
    restoreRememberedProperty(Lighting, "EnvironmentSpecularScale")
    restoreRememberedProperty(Lighting, "FogEnd")
    restoreRememberedProperty(Lighting, "FogStart")
    restoreRememberedProperty(Lighting, "OutdoorAmbient")
    restoreRememberedProperty(Lighting, "Ambient")
end

local function parentOptimizationOverlay(screenGui)
    for _, parent in ipairs(getGuiParentCandidates()) do
        pcall(function()
            local existing = parent:FindFirstChild(screenGui.Name)
            if existing then
                existing:Destroy()
            end
        end)
    end

    for _, parent in ipairs(getGuiParentCandidates()) do
        local ok = pcall(function()
            screenGui.Parent = parent
        end)

        if ok and screenGui.Parent == parent then
            return true
        end
    end

    return false
end

local function enableWhiteRenderOverlay()
    if optimizationWhiteOverlay then
        return
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BlasphemyOptimizationWhiteScreen"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 99990
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local frame = Instance.new("Frame")
    frame.Name = "WhiteScreen"
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    if parentOptimizationOverlay(screenGui) then
        optimizationWhiteOverlay = screenGui
    else
        screenGui:Destroy()
    end
end

local function disableWhiteRenderOverlay()
    if optimizationWhiteOverlay then
        optimizationWhiteOverlay:Destroy()
        optimizationWhiteOverlay = nil
    end
end

local function set3DRendering(enabled)
    local ok = pcall(function()
        RunService:Set3dRenderingEnabled(enabled)
    end)

    if not ok and not warned3DRenderToggle then
        warned3DRenderToggle = true
        warn("[Blasphemy] RunService:Set3dRenderingEnabled is unavailable in this environment.")
    end
end

local function apply3DRenderOptimization(enabled)
    if enabled then
        set3DRendering(false)
        enableWhiteRenderOverlay()
    else
        set3DRendering(true)
        disableWhiteRenderOverlay()
    end
end

local function applyOptimizationToInstance(instance)
    if state.optNoShadows then
        applyShadowOptimizationTo(instance)
    end

    if state.optNoTextures then
        applyTextureOptimizationTo(instance)
    end

    if state.optNoEffects then
        applyEffectsOptimizationTo(instance)
    end

    if state.optLowMaterials then
        applyMaterialOptimizationTo(instance)
    end
end

local function applyOptimizationScan()
    applyOptimizationToInstance(Lighting)

    for _, instance in ipairs(workspace:GetDescendants()) do
        applyOptimizationToInstance(instance)
    end

    for _, instance in ipairs(Lighting:GetDescendants()) do
        applyOptimizationToInstance(instance)
    end

    if state.optTerrainLite then
        applyTerrainOptimization()
    end

    if state.optLowLighting then
        applyLightingOptimization()
    end
end

local function hasStreamingOptimizationEnabled()
    return state.optNoShadows
        or state.optNoTextures
        or state.optNoEffects
        or state.optLowMaterials
end

local function updateOptimizationWatchers()
    if hasStreamingOptimizationEnabled() then
        if not optimizationWorkspaceConnection then
            optimizationWorkspaceConnection = workspace.DescendantAdded:Connect(function(instance)
                deferTask(function()
                    applyOptimizationToInstance(instance)
                end)
            end)
        end

        if not optimizationLightingConnection then
            optimizationLightingConnection = Lighting.DescendantAdded:Connect(function(instance)
                deferTask(function()
                    applyOptimizationToInstance(instance)
                end)
            end)
        end
    else
        if optimizationWorkspaceConnection then
            optimizationWorkspaceConnection:Disconnect()
            optimizationWorkspaceConnection = nil
        end

        if optimizationLightingConnection then
            optimizationLightingConnection:Disconnect()
            optimizationLightingConnection = nil
        end
    end
end

local function setOptimizationState(name, enabled)
    if name == "optNoShadows" then
        if enabled then
            applyOptimizationScan()
        else
            restoreShadowOptimization()
        end
    elseif name == "optNoTextures" then
        if enabled then
            applyOptimizationScan()
        else
            restoreTextureOptimization()
        end
    elseif name == "optNoEffects" then
        if enabled then
            applyOptimizationScan()
        else
            restoreEffectsOptimization()
        end
    elseif name == "optLowMaterials" then
        if enabled then
            applyOptimizationScan()
        else
            restoreMaterialOptimization()
        end
    elseif name == "optTerrainLite" then
        if enabled then
            applyTerrainOptimization()
        else
            restoreTerrainOptimization()
        end
    elseif name == "optLowLighting" then
        if enabled then
            applyLightingOptimization()
        else
            restoreLightingOptimization()
        end
    elseif name == "optNo3DRender" then
        apply3DRenderOptimization(enabled)
    end

    updateOptimizationWatchers()
end

local function restoreAllOptimizations()
    restoreShadowOptimization()
    restoreTextureOptimization()
    restoreEffectsOptimization()
    restoreMaterialOptimization()
    restoreTerrainOptimization()
    restoreLightingOptimization()
    apply3DRenderOptimization(false)

    if optimizationWorkspaceConnection then
        optimizationWorkspaceConnection:Disconnect()
        optimizationWorkspaceConnection = nil
    end

    if optimizationLightingConnection then
        optimizationLightingConnection:Disconnect()
        optimizationLightingConnection = nil
    end
end

local function setOptimizationPreset(enabled)
    local keys = {
        "optNoShadows",
        "optNoTextures",
        "optNoEffects",
        "optLowMaterials",
        "optTerrainLite",
        "optLowLighting",
    }

    for _, key in ipairs(keys) do
        if controls[key] then
            controls[key]:Set(enabled)
        else
            state[key] = enabled == true
            setOptimizationState(key, state[key])
        end
    end
end

local function getQueueOnTeleport()
    if type(queue_on_teleport) == "function" then
        return queue_on_teleport
    end

    if syn and type(syn.queue_on_teleport) == "function" then
        return syn.queue_on_teleport
    end

    if fluxus and type(fluxus.queue_on_teleport) == "function" then
        return fluxus.queue_on_teleport
    end

    return nil
end

local function queueSelfOnTeleport()
    if not state.queueScriptOnTeleport then
        return false
    end

    local queue = getQueueOnTeleport()
    if not queue then
        return false
    end

    local code = 'loadstring(game:HttpGet("' .. SELF_RELOAD_URL .. '"))()'
    local ok = pcall(function()
        queue(code)
    end)

    return ok
end

local function performAntiAfk(method)
    method = normalizeOption(method or config.antiAfkMethod, ANTI_AFK_METHODS, "Mixed")

    if method == "Mixed" or method == "VirtualUser" then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end

    if method == "Mixed" or method == "VirtualInput" then
        local location = UserInputService:GetMouseLocation()
        tryVirtualInput(function()
            VirtualInputManager:SendMouseMoveEvent(location.X + 1, location.Y + 1, game)
        end)
        tryVirtualInput(function()
            VirtualInputManager:SendMouseMoveEvent(location.X, location.Y, game)
        end)
    end

    if method == "Mixed" or method == "Camera Nudge" then
        local camera = workspace.CurrentCamera
        if camera then
            local currentCFrame = camera.CFrame
            pcall(function()
                camera.CFrame = currentCFrame * CFrame.Angles(0, math.rad(0.015), 0)
            end)

            deferTask(function()
                if workspace.CurrentCamera == camera then
                    pcall(function()
                        camera.CFrame = currentCFrame
                    end)
                end
            end)
        end
    end
end

local function startAntiAfkLoop()
    if antiAfkLoopRunning then
        return
    end

    antiAfkLoopRunning = true

    task.spawn(function()
        while state.antiAfk do
            task.wait(math.max(15, tonumber(config.antiAfkInterval) or 120))

            if state.antiAfk then
                performAntiAfk()
            end
        end

        antiAfkLoopRunning = false
    end)
end

local function enableAntiAfk()
    if LocalPlayer and not antiAfkIdleConnection then
        antiAfkIdleConnection = LocalPlayer.Idled:Connect(function()
            if state.antiAfk then
                performAntiAfk()
            end
        end)
    end

    performAntiAfk()
    startAntiAfkLoop()
end

local function disableAntiAfk()
    if antiAfkIdleConnection then
        antiAfkIdleConnection:Disconnect()
        antiAfkIdleConnection = nil
    end
end

local function scheduleReconnect(reason)
    if not state.autoReconnect or autoReconnectPending then
        return
    end

    autoReconnectPending = true
    local delaySeconds = math.max(0, tonumber(config.autoReconnectDelay) or 0)

    deferTask(function()
        task.wait(delaySeconds)

        if not state.autoReconnect then
            autoReconnectPending = false
            return
        end

        queueSelfOnTeleport()

        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)

        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)

        warn("[Blasphemy] Auto reconnect attempted: " .. tostring(reason or "unknown"))
    end)
end

local function isPromptVisible(instance)
    local current = instance

    while current do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end

        if current:IsA("ScreenGui") and not current.Enabled then
            return false
        end

        current = current.Parent
    end

    return true
end

local function isReconnectPrompt(instance)
    if not instance then
        return false
    end

    if not isPromptVisible(instance) then
        return false
    end

    if instance.Name == "ErrorPrompt" or instance.Name == "ErrorTitle" or instance.Name == "ErrorMessage" then
        return true
    end

    if instance:IsA("TextLabel") or instance:IsA("TextButton") then
        local text = string.lower(tostring(instance.Text or ""))
        return text:find("disconnect", 1, true)
            or text:find("reconnect", 1, true)
            or text:find("kicked", 1, true)
            or text:find("lost connection", 1, true)
            or text:find("error code", 1, true)
    end

    return false
end

local function watchReconnectPromptRoot(root)
    if not root then
        return
    end

    for _, descendant in ipairs(root:GetDescendants()) do
        if isReconnectPrompt(descendant) then
            scheduleReconnect("existing disconnect prompt")
            break
        end
    end

    table.insert(autoReconnectConnections, root.DescendantAdded:Connect(function(descendant)
        if isReconnectPrompt(descendant) then
            scheduleReconnect("disconnect prompt")
        end
    end))
end

local function enableAutoReconnect()
    autoReconnectPending = false

    for _, connection in ipairs(autoReconnectConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    autoReconnectConnections = {}

    local okCoreGui, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)

    if okCoreGui and coreGui then
        watchReconnectPromptRoot(coreGui)
    end

    pcall(function()
        table.insert(autoReconnectConnections, GuiService.ErrorMessageChanged:Connect(function(message)
            if state.autoReconnect and tostring(message or "") ~= "" then
                scheduleReconnect("GuiService error")
            end
        end))
    end)
end

local function disableAutoReconnect()
    autoReconnectPending = false

    for _, connection in ipairs(autoReconnectConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    autoReconnectConnections = {}
end

local originalHumanoidValues = setmetatable({}, { __mode = "k" })

local function getOriginalHumanoidValues(humanoid)
    if not humanoid then
        return nil
    end

    if not originalHumanoidValues[humanoid] then
        originalHumanoidValues[humanoid] = {
            WalkSpeed = humanoid.WalkSpeed,
            JumpPower = humanoid.JumpPower,
            JumpHeight = humanoid.JumpHeight,
            UseJumpPower = humanoid.UseJumpPower,
        }
    end

    return originalHumanoidValues[humanoid]
end

local function restoreWalkSpeed()
    local humanoid = getHumanoid()
    local original = getOriginalHumanoidValues(humanoid)

    if humanoid and original then
        pcall(function()
            humanoid.WalkSpeed = original.WalkSpeed
        end)
    end
end

local function restoreJumpPower()
    local humanoid = getHumanoid()
    local original = getOriginalHumanoidValues(humanoid)

    if humanoid and original then
        pcall(function()
            humanoid.UseJumpPower = original.UseJumpPower
        end)

        pcall(function()
            humanoid.JumpPower = original.JumpPower
        end)

        pcall(function()
            humanoid.JumpHeight = original.JumpHeight
        end)
    end
end

local function cleanupFlyObjects()
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end

    if flyBodyGyro then
        flyBodyGyro:Destroy()
        flyBodyGyro = nil
    end

    flyBodyRoot = nil
end

local function cleanupPlayerMovement()
    cleanupFlyObjects()
    restoreWalkSpeed()
    restoreJumpPower()
end

local function getFlyInputVector()
    if UserInputService:GetFocusedTextBox() then
        return ZERO_VECTOR
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return ZERO_VECTOR
    end

    local cameraCFrame = camera.CFrame
    local direction = ZERO_VECTOR

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        direction = direction + cameraCFrame.LookVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        direction = direction - cameraCFrame.LookVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        direction = direction + cameraCFrame.RightVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        direction = direction - cameraCFrame.RightVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        direction = direction + Vector3.new(0, 1, 0)
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
        or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        direction = direction - Vector3.new(0, 1, 0)
    end

    if direction.Magnitude > 1 then
        return direction.Unit
    end

    return direction
end

local function ensureFlyBodyMovers(root)
    if flyBodyRoot ~= root then
        cleanupFlyObjects()
    end

    if not flyBodyVelocity then
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Name = "BlasphemyFlyVelocity"
        flyBodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 900000
        flyBodyVelocity.P = 1250
        flyBodyVelocity.Parent = root
    end

    if not flyBodyGyro then
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.Name = "BlasphemyFlyGyro"
        flyBodyGyro.MaxTorque = Vector3.new(1, 1, 1) * 900000
        flyBodyGyro.P = 9000
        flyBodyGyro.D = 420
        flyBodyGyro.Parent = root
    end

    flyBodyRoot = root
end

local function applyWalkSpeed(deltaTime)
    if not state.playerWalkSpeed or state.playerFly then
        return
    end

    local humanoid = getHumanoid()
    local root = getRoot()
    if not humanoid then
        return
    end

    local original = getOriginalHumanoidValues(humanoid)
    local method = normalizeOption(config.walkSpeedMethod, WALK_SPEED_METHODS, "Humanoid")
    local speed = math.max(0, tonumber(config.walkSpeedValue) or 0)

    if method == "Humanoid" then
        humanoid.WalkSpeed = speed
        return
    end

    if method == "CFrame" then
        humanoid.WalkSpeed = original and original.WalkSpeed or humanoid.WalkSpeed

        if root and humanoid.MoveDirection.Magnitude > 0 then
            local baseSpeed = original and original.WalkSpeed or 16
            local extraSpeed = math.max(speed - baseSpeed, 0)
            root.CFrame = root.CFrame + (humanoid.MoveDirection.Unit * extraSpeed * deltaTime)
        end

        return
    end

    if method == "Velocity" and root then
        humanoid.WalkSpeed = 0

        local currentVelocity = root.AssemblyLinearVelocity
        local moveDirection = humanoid.MoveDirection

        if moveDirection.Magnitude > 0 then
            root.AssemblyLinearVelocity = Vector3.new(
                moveDirection.Unit.X * speed,
                currentVelocity.Y,
                moveDirection.Unit.Z * speed
            )
        else
            root.AssemblyLinearVelocity = Vector3.new(0, currentVelocity.Y, 0)
        end
    end
end

local function applyJumpPower()
    if not state.playerJumpPower then
        return
    end

    local humanoid = getHumanoid()
    local root = getRoot()
    if not humanoid then
        return
    end

    getOriginalHumanoidValues(humanoid)

    local method = normalizeOption(config.jumpPowerMethod, JUMP_POWER_METHODS, "JumpPower")
    local power = math.max(0, tonumber(config.jumpPowerValue) or 0)

    if method == "JumpPower" then
        pcall(function()
            humanoid.UseJumpPower = true
        end)

        humanoid.JumpPower = power
        return
    end

    if method == "JumpHeight" then
        pcall(function()
            humanoid.UseJumpPower = false
        end)

        pcall(function()
            humanoid.JumpHeight = math.max(1, power / 7)
        end)

        return
    end

    if method == "Velocity Boost" and root and not UserInputService:GetFocusedTextBox() then
        local wantsJump = humanoid.Jump or UserInputService:IsKeyDown(Enum.KeyCode.Space)
        local grounded = humanoid.FloorMaterial ~= Enum.Material.Air

        if wantsJump and grounded and os.clock() - lastJumpBoostAt >= 0.18 then
            local velocity = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(velocity.X, power, velocity.Z)
            lastJumpBoostAt = os.clock()
        end
    end
end

local function applyFly(deltaTime)
    if not state.playerFly then
        return
    end

    local root = getRoot()
    local camera = workspace.CurrentCamera
    if not root or not camera then
        cleanupFlyObjects()
        return
    end

    local method = normalizeOption(config.flyMethod, FLY_METHODS, "CFrame")
    local speed = math.max(0, tonumber(config.flySpeed) or 0)
    local moveDirection = getFlyInputVector()

    pcall(function()
        root.AssemblyAngularVelocity = ZERO_VECTOR
    end)

    if method == "CFrame" then
        cleanupFlyObjects()
        root.AssemblyLinearVelocity = ZERO_VECTOR

        local nextPosition = root.Position + (moveDirection * speed * deltaTime)
        root.CFrame = CFrame.new(nextPosition, nextPosition + camera.CFrame.LookVector)
        return
    end

    if method == "Velocity" then
        cleanupFlyObjects()
        root.AssemblyLinearVelocity = moveDirection * speed
        return
    end

    if method == "BodyMover" then
        ensureFlyBodyMovers(root)
        flyBodyVelocity.Velocity = moveDirection * speed
        flyBodyGyro.CFrame = camera.CFrame
    end
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

local function sendVirtualMouseClick(blockGui, suppressGui)
    local mouseOverGui = Window:IsMouseOver()
    if blockGui and mouseOverGui then
        return false
    end

    local restoreGui = false
    if suppressGui and mouseOverGui and Window.Gui and Window.Gui.Enabled then
        Window.Gui.Enabled = false
        restoreGui = true
    end

    local x, y = getMousePosition()
    local downOk = tryVirtualInput(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
    end)

    task.wait(config.mouseHoldTime)

    local upOk = tryVirtualInput(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)

    if restoreGui and Window.Gui then
        Window.Gui.Enabled = true
    end

    return downOk and upOk
end

local function sendMouseClick()
    return sendVirtualMouseClick(true)
end

local function sendBackgroundMouseClick()
    return sendVirtualMouseClick(false, true)
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

local function sendEvasiveDash()
    local dDownOk = tryVirtualInput(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.D, false, game)
    end)

    task.wait(0.006)

    local qDownOk = tryVirtualInput(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
    end)

    task.wait(config.keyHoldTime)

    local qUpOk = tryVirtualInput(function()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
    end)

    task.wait(config.evasiveSideHoldTime)

    local dUpOk = tryVirtualInput(function()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game)
    end)

    return dDownOk and qDownOk and qUpOk and dUpOk
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

    if optimizationStateKeys[name] then
        setOptimizationState(name, state[name])
        return
    end

    if name == "antiAfk" then
        if state[name] then
            enableAntiAfk()
        else
            disableAntiAfk()
        end

        return
    end

    if name == "autoReconnect" then
        if state[name] then
            enableAutoReconnect()
        else
            disableAutoReconnect()
        end

        return
    end

    if name == "altAutoReset" then
        if state[name] then
            enableAutoReset()
        else
            disableAutoReset()
        end

        return
    end

    if name == "playerWalkSpeed" and not state[name] then
        restoreWalkSpeed()
        return
    end

    if name == "playerJumpPower" and not state[name] then
        restoreJumpPower()
        return
    end

    if name == "playerFly" and not state[name] then
        cleanupFlyObjects()
        return
    end

    if name == "altPositionLock" and not state[name] then
        disableAltPositionLock()
        return
    end

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
        end, sendBackgroundMouseClick)
    elseif name == "autoSkills" then
        startLoop(name, function()
            return config.autoSkillsInterval
        end, function()
            for slot, keyCode in ipairs(skillKeys) do
                if not state.autoSkills then
                    break
                end

                sendKey(keyCode)
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
    elseif name == "autoEvasive" then
        startLoop(name, function()
            return config.autoEvasiveInterval
        end, sendEvasiveDash)
    elseif name == "autoFarmPositionLock" then
        if not autoFarmSavedCFrame and not saveCurrentPosition("autoFarm") then
            state[name] = false
            if controls[name] then
                controls[name]:Set(false, true)
            end
            return
        end

        startLoop(name, function()
            return config.autoFarmTeleportInterval
        end, function()
            teleportToSavedPosition("autoFarm")
        end)
    elseif name == "altPositionLock" then
        if not enableAltPositionLock() then
            state[name] = false
            if controls[name] then
                controls[name]:Set(false, true)
            end
            return
        end
    end
end

local function listFromMap(map)
    local list = {}

    for name, enabled in pairs(map or {}) do
        if enabled == true then
            table.insert(list, name)
        end
    end

    table.sort(list)
    return list
end

local function mapFromList(list)
    local map = {}

    if type(list) ~= "table" then
        return map
    end

    for key, value in pairs(list) do
        if type(key) == "number" then
            map[tostring(value)] = true
        elseif value == true then
            map[tostring(key)] = true
        end
    end

    return map
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

local function getPlayerOptions()
    local options = {}
    local seen = {}

    local function addName(name)
        name = tostring(name or "")
        if name ~= "" and not seen[name] then
            seen[name] = true
            table.insert(options, name)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            addName(player.Name)
        end
    end

    for name, enabled in pairs(targetList) do
        if enabled then
            addName(name)
        end
    end

    for name, enabled in pairs(friendList) do
        if enabled then
            addName(name)
        end
    end

    table.sort(options)
    return options
end

local function updatePlayerControls()
    if targetDropdown then
        targetDropdown:SetOptions(getTargetOptions(), state.targetName)
    end

    local options = getPlayerOptions()

    if controls.targetList then
        controls.targetList:SetOptions(options, listFromMap(targetList))
    end

    if controls.friendList then
        controls.friendList:SetOptions(options, listFromMap(friendList))
    end
end

local function getTargetParts(player)
    if not player or player == LocalPlayer or friendList[player.Name] then
        return nil, nil
    end

    local root = getRoot(player.Character)
    local humanoid = getHumanoid(player.Character)

    if not root or not humanoid or humanoid.Health <= 0 then
        return nil, nil
    end

    return root, humanoid
end

local function getPriorityTarget()
    local lowestPlayer = nil
    local lowestScore = math.huge

    for name, enabled in pairs(targetList) do
        if enabled and not friendList[name] then
            local player = Players:FindFirstChild(name)
            local _, humanoid = getTargetParts(player)

            if humanoid then
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

local function getNearestTarget()
    local localRoot = getRoot()
    local nearestPlayer = nil
    local nearestDistance = math.huge

    if not localRoot then
        return nil
    end

    for _, player in ipairs(Players:GetPlayers()) do
        local root = nil
        local humanoid = nil

        root, humanoid = getTargetParts(player)

        if root and humanoid then
            local distance = (root.Position - localRoot.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPlayer = player
            end
        end
    end

    return nearestPlayer
end

local function getLowestHealthTarget()
    local lowestPlayer = nil
    local lowestScore = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        local _, humanoid = getTargetParts(player)

        if humanoid then
            local maxHealth = math.max(humanoid.MaxHealth, 1)
            local healthScore = humanoid.Health / maxHealth

            if healthScore < lowestScore then
                lowestScore = healthScore
                lowestPlayer = player
            end
        end
    end

    return lowestPlayer
end

local function getDynamicTarget()
    local priorityTarget = getPriorityTarget()
    if priorityTarget then
        return priorityTarget
    end

    if state.findLowPlayers then
        return getLowestHealthTarget() or getNearestTarget()
    end

    return getNearestTarget()
end

local function getTargetPlayer()
    local priorityTarget = getPriorityTarget()
    if priorityTarget then
        return priorityTarget
    end

    if state.targetName ~= "Nearest" then
        local player = Players:FindFirstChild(state.targetName)
        if getTargetParts(player) then
            return player
        end
    end

    return getDynamicTarget()
end

local function hasActiveAttackMode()
    return state.autoM1
        or state.backgroundM1
        or state.autoSkills
        or state.autoUltimate
        or state.autoBurst
        or state.autoDash
        or state.autoEvasive
        or state.orbit
        or state.smartOrbit
        or state.cameraLock
end

local function getCurrentAttackTarget()
    if not hasActiveAttackMode() then
        return nil
    end

    return getTargetPlayer()
end

local function lockDynamicTarget()
    local target = getDynamicTarget()
    if not target then
        return
    end

    state.targetName = target.Name
    smartPoint = nil

    updatePlayerControls()
end

local function keyToName(keyCode)
    if keyCode and typeof(keyCode) == "EnumItem" then
        return keyCode.Name
    end

    return nil
end

local function keyFromName(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end

    for _, item in ipairs(Enum.KeyCode:GetEnumItems()) do
        if item.Name == name then
            return item
        end
    end

    return nil
end

local function colorToData(color)
    return {
        r = math.floor(color.R * 255 + 0.5),
        g = math.floor(color.G * 255 + 0.5),
        b = math.floor(color.B * 255 + 0.5),
    }
end

local function colorFromData(data, fallback)
    if type(data) ~= "table" then
        return fallback
    end

    local red = math.clamp(tonumber(data.r) or fallback.R * 255, 0, 255)
    local green = math.clamp(tonumber(data.g) or fallback.G * 255, 0, 255)
    local blue = math.clamp(tonumber(data.b) or fallback.B * 255, 0, 255)

    return Color3.fromRGB(red, green, blue)
end

local function cframeToData(cframe)
    if typeof(cframe) ~= "CFrame" then
        return nil
    end

    return { cframe:GetComponents() }
end

local function cframeFromData(data)
    if type(data) ~= "table" then
        return nil
    end

    local values = {}
    local source = data.components or data

    for index = 1, 12 do
        local value = tonumber(source[index])
        if not value then
            return nil
        end

        values[index] = value
    end

    return CFrame.new(
        values[1], values[2], values[3],
        values[4], values[5], values[6],
        values[7], values[8], values[9],
        values[10], values[11], values[12]
    )
end

local function hasFileApi()
    return type(writefile) == "function"
        and type(readfile) == "function"
        and type(isfile) == "function"
end

local function ensureConfigFolder()
    if type(makefolder) ~= "function" then
        return true
    end

    pcall(function()
        if type(isfolder) ~= "function" or not isfolder(CONFIG_ROOT) then
            makefolder(CONFIG_ROOT)
        end
    end)

    pcall(function()
        if type(isfolder) ~= "function" or not isfolder(CONFIG_DIR) then
            makefolder(CONFIG_DIR)
        end
    end)

    return true
end

local function sanitizeConfigName(name)
    local cleaned = tostring(name or "default")
        :gsub("[^%w%-%_ ]", "")
        :gsub("%s+", "_")

    if cleaned == "" then
        cleaned = "default"
    end

    return cleaned
end

local function getConfigPath(name)
    local safeName = sanitizeConfigName(name)

    if type(makefolder) == "function" then
        return CONFIG_DIR .. "/" .. safeName .. ".json"
    end

    return CONFIG_ROOT .. "_" .. safeName .. ".json"
end

local function getAutoLoadPath()
    local userId = LocalPlayer and LocalPlayer.UserId or 0

    if type(makefolder) == "function" then
        return CONFIG_DIR .. "/autoload_" .. tostring(userId) .. ".txt"
    end

    return CONFIG_ROOT .. "_autoload_" .. tostring(userId) .. ".txt"
end

local function listConfigNames()
    local names = {}
    local seen = {}

    local function addName(name)
        name = sanitizeConfigName(name)
        if not seen[name] then
            seen[name] = true
            table.insert(names, name)
        end
    end

    addName(settings.selectedConfig)

    if type(listfiles) == "function" then
        local canList = type(isfolder) ~= "function" or isfolder(CONFIG_DIR)
        if canList then
            local ok, files = pcall(listfiles, CONFIG_DIR)
            if ok and type(files) == "table" then
                for _, path in ipairs(files) do
                    local name = tostring(path):match("([^/\\]+)%.json$")
                    if name then
                        addName(name)
                    end
                end
            end
        end
    end

    table.sort(names)

    if #names == 0 then
        addName("default")
    end

    return names
end

local function refreshConfigDropdown(selectedName)
    if controls.configList then
        controls.configList:SetOptions(listConfigNames(), sanitizeConfigName(selectedName or settings.selectedConfig))
    end
end

local function notifyStatus(message, isError, duration)
    setBootStatus(message, isError == true)
    closeBootStatus(duration or 1.5)
end

local function collectConfigData()
    local data = {
        version = 7,
        theme = settings.theme or Window:GetTheme(),
        menuBind = keyToName(Window:GetToggleKey()),
        targetBind = controls.targetBind and keyToName(controls.targetBind:Get()) or nil,
        targetName = state.targetName,
        states = {},
        config = {},
        positions = {},
    }

    for _, key in ipairs(stateKeys) do
        data.states[key] = state[key] == true
    end

    for _, key in ipairs(configKeys) do
        data.config[key] = config[key]
    end

    data.config.highlightColor = colorToData(config.highlightColor)
    data.positions.autoFarm = cframeToData(autoFarmSavedCFrame)
    data.positions.alt = cframeToData(altSavedCFrame)
    data.targetList = listFromMap(targetList)
    data.friendList = listFromMap(friendList)

    return data
end

local function syncNumericControls()
    local numericControls = {
        autoM1Interval = config.autoM1Interval,
        autoSkillsInterval = config.autoSkillsInterval,
        autoBurstInterval = config.autoBurstInterval,
        autoUltimateInterval = config.autoUltimateInterval,
        autoEvasiveInterval = config.autoEvasiveInterval,
        autoFarmTeleportInterval = config.autoFarmTeleportInterval,
        altTeleportInterval = config.altTeleportInterval,
        walkSpeedValue = config.walkSpeedValue,
        jumpPowerValue = config.jumpPowerValue,
        flySpeed = config.flySpeed,
        altAutoResetDelay = config.altAutoResetDelay,
        altRespawnTeleportDelay = config.altRespawnTeleportDelay,
        optTextureTransparency = config.optTextureTransparency,
        antiAfkInterval = config.antiAfkInterval,
        autoReconnectDelay = config.autoReconnectDelay,
        evasiveSideHoldTime = config.evasiveSideHoldTime,
        orbitRadius = config.orbitRadius,
        orbitSpeed = config.orbitSpeed,
        orbitHeight = config.orbitHeight,
        smartRadius = config.smartRadius,
        smartInterval = config.smartInterval,
        smartMoveSpeed = config.smartMoveSpeed,
        camLockDistance = config.camLockDistance,
        keyHoldTime = config.keyHoldTime,
        mouseHoldTime = config.mouseHoldTime,
        antiVoidSafeY = config.antiVoidSafeY,
        antiVoidTriggerY = config.antiVoidTriggerY,
    }

    for key, value in pairs(numericControls) do
        if controls[key] then
            controls[key]:Set(value, true)
        end
    end
end

local function syncChoiceControls()
    local choiceControls = {
        walkSpeedMethod = config.walkSpeedMethod,
        jumpPowerMethod = config.jumpPowerMethod,
        flyMethod = config.flyMethod,
        antiAfkMethod = config.antiAfkMethod,
    }

    for key, value in pairs(choiceControls) do
        if controls[key] then
            controls[key]:Set(value, true)
        end
    end
end

local function applyConfigData(data)
    if type(data) ~= "table" then
        return false, "Config is not a table"
    end

    if type(data.config) == "table" then
        for _, key in ipairs(configKeys) do
            if data.config[key] ~= nil then
                config[key] = data.config[key]
            end
        end

        config.highlightColor = colorFromData(data.config.highlightColor, config.highlightColor)
        config.walkSpeedMethod = normalizeOption(config.walkSpeedMethod, WALK_SPEED_METHODS, "Humanoid")
        config.jumpPowerMethod = normalizeOption(config.jumpPowerMethod, JUMP_POWER_METHODS, "JumpPower")
        config.flyMethod = normalizeOption(config.flyMethod, FLY_METHODS, "CFrame")
        config.antiAfkMethod = normalizeOption(config.antiAfkMethod, ANTI_AFK_METHODS, "Mixed")
    end

    if type(data.positions) == "table" then
        autoFarmSavedCFrame = cframeFromData(data.positions.autoFarm)
        altSavedCFrame = cframeFromData(data.positions.alt)
        updateSavedPositionLabels()
    end

    if type(data.states) == "table" then
        for _, key in ipairs(stateKeys) do
            local enabled = data.states[key] == true
            if controls[key] then
                controls[key]:Set(enabled)
            else
                state[key] = enabled
            end
        end
    end

    targetList = mapFromList(data.targetList)
    friendList = mapFromList(data.friendList)

    if type(data.targetName) == "string" and data.targetName ~= "" then
        state.targetName = data.targetName
        smartPoint = nil

        updatePlayerControls()
    end

    updatePlayerControls()

    if controls.highlightColor then
        controls.highlightColor:Set(config.highlightColor, true)
    end

    syncNumericControls()
    syncChoiceControls()
    updateTargetHighlight()

    if type(data.theme) == "string" and Window:SetTheme(data.theme) then
        settings.theme = data.theme
        if controls.theme then
            controls.theme:Set(data.theme, true)
        end
    end

    local menuKey = keyFromName(data.menuBind)
    if menuKey then
        Window:SetToggleKey(menuKey)
        settings.menuBind = menuKey.Name
        if controls.menuBind then
            controls.menuBind:Set(menuKey, true)
        end
    end

    local targetKey = keyFromName(data.targetBind)
    if controls.targetBind then
        controls.targetBind:Set(targetKey, true)
    end

    return true
end

local function saveConfig(name)
    if not hasFileApi() then
        return false, "File API is not available in this executor"
    end

    ensureConfigFolder()

    local safeName = sanitizeConfigName(name)
    local encodedOk, encoded = pcall(function()
        return HttpService:JSONEncode(collectConfigData())
    end)

    if not encodedOk then
        return false, encoded
    end

    local ok, err = pcall(writefile, getConfigPath(safeName), encoded)
    if not ok then
        return false, err
    end

    settings.selectedConfig = safeName
    return true
end

local function loadConfig(name)
    if not hasFileApi() then
        return false, "File API is not available in this executor"
    end

    local safeName = sanitizeConfigName(name)
    local path = getConfigPath(safeName)

    if not isfile(path) then
        return false, "Config not found: " .. path
    end

    local readOk, content = pcall(readfile, path)
    if not readOk then
        return false, content
    end

    local decodeOk, decoded = pcall(function()
        return HttpService:JSONDecode(content)
    end)

    if not decodeOk then
        return false, decoded
    end

    local applyOk, applyErr = applyConfigData(decoded)
    if not applyOk then
        return false, applyErr
    end

    settings.selectedConfig = safeName
    refreshConfigDropdown(safeName)
    return true
end

local function deleteConfig(name)
    if not hasFileApi() then
        return false, "File API is not available in this executor"
    end

    if type(delfile) ~= "function" then
        return false, "delfile is not available in this executor"
    end

    local safeName = sanitizeConfigName(name)
    local path = getConfigPath(safeName)

    if not isfile(path) then
        return false, "Config not found: " .. path
    end

    local ok, err = pcall(delfile, path)
    if not ok then
        return false, err
    end

    settings.selectedConfig = "default"
    refreshConfigDropdown(settings.selectedConfig)
    return true
end

local function setLabelText(label, text)
    if not label then
        return
    end

    local textLabel = label:FindFirstChild("Text")
    if textLabel then
        textLabel.Text = text
    end
end

local function readAutoLoadConfigName()
    if not hasFileApi() then
        return nil
    end

    local path = getAutoLoadPath()
    if not isfile(path) then
        return nil
    end

    local ok, content = pcall(readfile, path)
    if not ok then
        return nil
    end

    local name = tostring(content or ""):match("^%s*(.-)%s*$")
    if name == "" then
        return nil
    end

    return sanitizeConfigName(name)
end

local function updateAutoLoadLabel()
    local userId = LocalPlayer and LocalPlayer.UserId or 0
    local name = readAutoLoadConfigName()

    if name then
        setLabelText(autoLoadLabel, "Auto Load: " .. name .. " | UserId: " .. tostring(userId))
    else
        setLabelText(autoLoadLabel, "Auto Load: none | UserId: " .. tostring(userId))
    end
end

local function setAutoLoadConfig(name)
    if not hasFileApi() then
        return false, "File API is not available in this executor"
    end

    ensureConfigFolder()

    local safeName = sanitizeConfigName(name)
    local configPath = getConfigPath(safeName)

    if not isfile(configPath) then
        local saveOk, saveErr = saveConfig(safeName)
        if not saveOk then
            return false, saveErr
        end
    end

    local ok, err = pcall(writefile, getAutoLoadPath(), safeName)
    if not ok then
        return false, err
    end

    settings.selectedConfig = safeName
    refreshConfigDropdown(safeName)
    updateAutoLoadLabel()
    return true
end

local function clearAutoLoadConfig()
    if not hasFileApi() then
        return false, "File API is not available in this executor"
    end

    ensureConfigFolder()

    local path = getAutoLoadPath()

    if type(delfile) == "function" and isfile(path) then
        local ok, err = pcall(delfile, path)
        if not ok then
            return false, err
        end
    else
        local ok, err = pcall(writefile, path, "")
        if not ok then
            return false, err
        end
    end

    updateAutoLoadLabel()
    return true
end

local function tryAutoLoadConfig()
    local name = readAutoLoadConfigName()
    updateAutoLoadLabel()

    if not name then
        return false, "No auto-load config set"
    end

    local ok, err = loadConfig(name)
    updateAutoLoadLabel()

    if not ok then
        return false, err
    end

    return true, name
end

local function clearTargetHighlight()
    if targetHighlight then
        targetHighlight:Destroy()
        targetHighlight = nil
    end
end

function updateTargetHighlight()
    local target = getCurrentAttackTarget()
    local character = target and target.Character

    if not character or not getTargetParts(target) then
        clearTargetHighlight()
        return
    end

    if not targetHighlight then
        targetHighlight = Instance.new("Highlight")
        targetHighlight.Name = "BlasphemyTargetHighlight"
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

    applyWalkSpeed(deltaTime)
    applyJumpPower()
    applyFly(deltaTime)

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
controls.targetDropdown = targetDropdown

controls.targetBind = RageTab:AddKeybind({
    Name = "Target Bind",
    Default = nil,
    Callback = function()
        lockDynamicTarget()
    end,
})

RageTab:AddButton({
    Name = "Refresh Target List",
    Callback = function()
        updatePlayerControls()
    end,
})

controls.targetList = RageTab:AddMultiDropdown({
    Name = "Target List",
    Options = getPlayerOptions(),
    Default = listFromMap(targetList),
    Callback = function(values)
        targetList = mapFromList(values)

        for name in pairs(friendList) do
            targetList[name] = nil
        end

        if controls.targetList then
            controls.targetList:Set(listFromMap(targetList), true)
        end

        smartPoint = nil
    end,
})

controls.friendList = RageTab:AddMultiDropdown({
    Name = "Friend List",
    Options = getPlayerOptions(),
    Default = listFromMap(friendList),
    Callback = function(values)
        friendList = mapFromList(values)

        for name in pairs(friendList) do
            targetList[name] = nil
        end

        if state.targetName ~= "Nearest" and friendList[state.targetName] then
            state.targetName = "Nearest"
        end

        if controls.targetList then
            controls.targetList:Set(listFromMap(targetList), true)
        end

        updatePlayerControls()
        smartPoint = nil
    end,
})

Players.PlayerAdded:Connect(function()
    deferTask(function()
        updatePlayerControls()
    end)
end)

Players.PlayerRemoving:Connect(function()
    deferTask(function()
        updatePlayerControls()
    end)
end)

controls.findLowPlayers = RageTab:AddToggle({
    Name = "Find Low Players",
    Description = "Prefer lowest-health target",
    Default = false,
    Callback = function(value)
        state.findLowPlayers = value
        smartPoint = nil
    end,
})

controls.smartOrbit = RageTab:AddToggle({
    Name = "Smart Orbit",
    Description = "Jump between random points around target",
    Default = false,
    Callback = function(value)
        state.smartOrbit = value
        smartPoint = nil
    end,
})

controls.cameraLock = RageTab:AddToggle({
    Name = "Camera Lock on Target",
    Description = "Aim camera at selected target",
    Default = false,
    Callback = function(value)
        state.cameraLock = value
    end,
})

controls.antiVoid = RageTab:AddToggle({
    Name = "Enable Anti-Void",
    Description = "Return to last safe position if falling",
    Default = false,
    Callback = function(value)
        state.antiVoid = value
    end,
})

controls.highlightColor = RageTab:AddColorPicker({
    Name = "Highlight Customization",
    Default = config.highlightColor,
    Callback = function(value)
        config.highlightColor = value
        updateTargetHighlight()
    end,
})

RageTab:AddSection("Movement")

controls.orbit = RageTab:AddToggle({
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

controls.orbitRadius = RageTab:AddSlider({
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

controls.orbitSpeed = RageTab:AddSlider({
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

controls.camLockDistance = RageTab:AddSlider({
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

controls.orbitHeight = RageTab:AddSlider({
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

controls.smartRadius = RageTab:AddSlider({
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

controls.smartInterval = RageTab:AddSlider({
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

controls.smartMoveSpeed = RageTab:AddSlider({
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

CombatTab:AddSection("Combat")

controls.autoM1 = CombatTab:AddToggle({
    Name = "Auto M1",
    Description = "Left mouse click at 10 cps",
    Default = false,
    Callback = function(value)
        setState("autoM1", value)
    end,
})

controls.backgroundM1 = CombatTab:AddToggle({
    Name = "Background M1",
    Description = "Virtual LMB with GUI guard",
    Default = false,
    Callback = function(value)
        setState("backgroundM1", value)
    end,
})

controls.autoSkills = CombatTab:AddToggle({
    Name = "Auto Skills",
    Description = "Press 1-4 and activate first 4 tools",
    Default = false,
    Callback = function(value)
        setState("autoSkills", value)
    end,
})

controls.autoUltimate = CombatTab:AddToggle({
    Name = "Auto Ultimate",
    Description = "Press G once per second",
    Default = false,
    Callback = function(value)
        setState("autoUltimate", value)
    end,
})

controls.autoBurst = CombatTab:AddToggle({
    Name = "Auto Burst",
    Description = "Spam R at 10 cps",
    Default = false,
    Callback = function(value)
        setState("autoBurst", value)
    end,
})

controls.autoDash = CombatTab:AddToggle({
    Name = "Auto Dash/Wall Combo",
    Description = "Spam Q at 10 cps",
    Default = false,
    Callback = function(value)
        setState("autoDash", value)
    end,
})

controls.autoEvasive = CombatTab:AddToggle({
    Name = "Auto Evasive",
    Description = "Hold D while pressing Q",
    Default = false,
    Callback = function(value)
        setState("autoEvasive", value)
    end,
})

CombatTab:AddSection("Timings")

controls.autoM1Interval = CombatTab:AddSlider({
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

controls.autoSkillsInterval = CombatTab:AddSlider({
    Name = "Skill Delay",
    Min = 0.03,
    Max = 0.60,
    Default = config.autoSkillsInterval,
    Increment = 0.01,
    Suffix = "s",
    Callback = function(value)
        config.autoSkillsInterval = value
    end,
})

controls.autoBurstInterval = CombatTab:AddSlider({
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

controls.autoEvasiveInterval = CombatTab:AddSlider({
    Name = "Evasive Delay",
    Min = 0.03,
    Max = 0.60,
    Default = config.autoEvasiveInterval,
    Increment = 0.01,
    Suffix = "s",
    Callback = function(value)
        config.autoEvasiveInterval = value
    end,
})

controls.autoUltimateInterval = CombatTab:AddSlider({
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

PlayerTab:AddSection("WalkSpeed")

controls.playerWalkSpeed = PlayerTab:AddToggle({
    Name = "WalkSpeed",
    Description = "Custom movement speed",
    Default = false,
    Callback = function(value)
        setState("playerWalkSpeed", value)
    end,
})

controls.walkSpeedMethod = PlayerTab:AddDropdown({
    Name = "Walk Method",
    Options = WALK_SPEED_METHODS,
    Default = config.walkSpeedMethod,
    Callback = function(value)
        config.walkSpeedMethod = normalizeOption(value, WALK_SPEED_METHODS, "Humanoid")

        if state.playerWalkSpeed then
            restoreWalkSpeed()
        end
    end,
})

controls.walkSpeedValue = PlayerTab:AddSlider({
    Name = "Walk Speed",
    Min = 8,
    Max = 160,
    Default = config.walkSpeedValue,
    Increment = 1,
    Suffix = "sps",
    Callback = function(value)
        config.walkSpeedValue = value
    end,
})

PlayerTab:AddSection("Jump")

controls.playerJumpPower = PlayerTab:AddToggle({
    Name = "Jump Power",
    Description = "Custom jump strength",
    Default = false,
    Callback = function(value)
        setState("playerJumpPower", value)
    end,
})

controls.jumpPowerMethod = PlayerTab:AddDropdown({
    Name = "Jump Method",
    Options = JUMP_POWER_METHODS,
    Default = config.jumpPowerMethod,
    Callback = function(value)
        config.jumpPowerMethod = normalizeOption(value, JUMP_POWER_METHODS, "JumpPower")

        if state.playerJumpPower then
            restoreJumpPower()
        end
    end,
})

controls.jumpPowerValue = PlayerTab:AddSlider({
    Name = "Jump Value",
    Min = 20,
    Max = 250,
    Default = config.jumpPowerValue,
    Increment = 1,
    Suffix = "power",
    Callback = function(value)
        config.jumpPowerValue = value
    end,
})

PlayerTab:AddSection("Fly")

controls.playerFly = PlayerTab:AddToggle({
    Name = "Fly",
    Description = "WASD, Space up, Ctrl/Shift down",
    Default = false,
    Callback = function(value)
        setState("playerFly", value)
    end,
})

controls.flyMethod = PlayerTab:AddDropdown({
    Name = "Fly Method",
    Options = FLY_METHODS,
    Default = config.flyMethod,
    Callback = function(value)
        config.flyMethod = normalizeOption(value, FLY_METHODS, "CFrame")
        cleanupFlyObjects()
    end,
})

controls.flySpeed = PlayerTab:AddSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 200,
    Default = config.flySpeed,
    Increment = 1,
    Suffix = "sps",
    Callback = function(value)
        config.flySpeed = value
    end,
})

OptimizationsTab:AddSection("Render")

controls.optNo3DRender = OptimizationsTab:AddToggle({
    Name = "Disable 3D Render",
    Description = "White screen behind GUI",
    Default = false,
    Callback = function(value)
        setState("optNo3DRender", value)
    end,
})

controls.optNoShadows = OptimizationsTab:AddToggle({
    Name = "No Shadows",
    Description = "Global and part shadows off",
    Default = false,
    Callback = function(value)
        setState("optNoShadows", value)
    end,
})

controls.optLowLighting = OptimizationsTab:AddToggle({
    Name = "Low Lighting",
    Description = "Simplify lighting values",
    Default = false,
    Callback = function(value)
        setState("optLowLighting", value)
    end,
})

OptimizationsTab:AddSection("World")

controls.optNoTextures = OptimizationsTab:AddToggle({
    Name = "No Textures",
    Description = "Hide decals and clear mesh maps",
    Default = false,
    Callback = function(value)
        setState("optNoTextures", value)
    end,
})

controls.optTextureTransparency = OptimizationsTab:AddSlider({
    Name = "Texture Transparency",
    Min = 0.00,
    Max = 1.00,
    Default = config.optTextureTransparency,
    Increment = 0.05,
    Suffix = "x",
    Callback = function(value)
        config.optTextureTransparency = value

        if state.optNoTextures then
            applyOptimizationScan()
        end
    end,
})

controls.optNoEffects = OptimizationsTab:AddToggle({
    Name = "No Effects",
    Description = "Particles, beams, trails, post FX",
    Default = false,
    Callback = function(value)
        setState("optNoEffects", value)
    end,
})

controls.optLowMaterials = OptimizationsTab:AddToggle({
    Name = "Low Materials",
    Description = "SmoothPlastic and low mesh fidelity",
    Default = false,
    Callback = function(value)
        setState("optLowMaterials", value)
    end,
})

controls.optTerrainLite = OptimizationsTab:AddToggle({
    Name = "Terrain Lite",
    Description = "Terrain decoration and water effects off",
    Default = false,
    Callback = function(value)
        setState("optTerrainLite", value)
    end,
})

OptimizationsTab:AddSection("Presets")

OptimizationsTab:AddButton({
    Name = "Potato Preset",
    Callback = function()
        setOptimizationPreset(true)
        notifyStatus("Optimization preset enabled.")
    end,
})

OptimizationsTab:AddButton({
    Name = "Restore Optimizations",
    Callback = function()
        for key in pairs(optimizationStateKeys) do
            if controls[key] then
                controls[key]:Set(false)
            else
                state[key] = false
            end
        end

        restoreAllOptimizations()
        notifyStatus("Optimizations restored.")
    end,
})

OptimizationsTab:AddButton({
    Name = "Rescan World",
    Callback = function()
        applyOptimizationScan()
        notifyStatus("Optimization scan applied.")
    end,
})

OptimizationsTab:AddButton({
    Name = "GC Sweep",
    Callback = function()
        pcall(function()
            collectgarbage("collect")
        end)

        notifyStatus("Garbage collection requested.")
    end,
})

AutoFarmTab:AddSection("Position")

autoFarmPositionLabel = AutoFarmTab:AddLabel("Saved: none")

AutoFarmTab:AddButton({
    Name = "SetPosition",
    Callback = function()
        if saveCurrentPosition("autoFarm") then
            notifyStatus("AutoFarm position saved.")

            if controls.autoFarmPositionLock then
                controls.autoFarmPositionLock:Set(true)
            end
        else
            notifyStatus("No character root to save.", true, 2.5)
        end
    end,
})

controls.autoFarmPositionLock = AutoFarmTab:AddToggle({
    Name = "Position Lock",
    Description = "Teleport to saved AutoFarm CFrame",
    Default = false,
    Callback = function(value)
        setState("autoFarmPositionLock", value)
    end,
})

controls.autoFarmTeleportInterval = AutoFarmTab:AddSlider({
    Name = "Teleport Delay",
    Min = 0.05,
    Max = 1.00,
    Default = config.autoFarmTeleportInterval,
    Increment = 0.01,
    Suffix = "s",
    Callback = function(value)
        config.autoFarmTeleportInterval = value
    end,
})

AltTab:AddSection("Respawn")

controls.altAutoReset = AltTab:AddToggle({
    Name = "AutoReset",
    Description = "Reset on every character spawn",
    Default = false,
    Callback = function(value)
        setState("altAutoReset", value)
    end,
})

controls.altAutoResetDelay = AltTab:AddSlider({
    Name = "Reset Delay",
    Min = 0.00,
    Max = 10.00,
    Default = config.altAutoResetDelay,
    Increment = 0.05,
    Suffix = "s",
    Callback = function(value)
        config.altAutoResetDelay = value

        if state.altAutoReset then
            scheduleAutoReset(getCharacter())
        end
    end,
})

AltTab:AddButton({
    Name = "Reset Current",
    Callback = function()
        if resetCharacter() then
            notifyStatus("Current character reset.")
        else
            notifyStatus("No character to reset.", true, 2.5)
        end
    end,
})

AltTab:AddSection("Position")

altPositionLabel = AltTab:AddLabel("Saved: none")

AltTab:AddButton({
    Name = "SetPosition",
    Callback = function()
        if saveCurrentPosition("alt") then
            notifyStatus("Alt position saved.")

            if controls.altPositionLock then
                controls.altPositionLock:Set(true)
            end
        else
            notifyStatus("No character root to save.", true, 2.5)
        end
    end,
})

controls.altPositionLock = AltTab:AddToggle({
    Name = "Position Lock",
    Description = "Teleport to saved Alt CFrame",
    Default = false,
    Callback = function(value)
        setState("altPositionLock", value)
    end,
})

controls.altRespawnTeleportDelay = AltTab:AddSlider({
    Name = "Respawn Teleport Delay",
    Min = 0.00,
    Max = 10.00,
    Default = config.altRespawnTeleportDelay,
    Increment = 0.05,
    Suffix = "s",
    Callback = function(value)
        config.altRespawnTeleportDelay = value

        if state.altPositionLock and not altTeleportReady then
            scheduleAltTeleportForCharacter(getCharacter(), true)
        end
    end,
})

controls.altTeleportInterval = AltTab:AddSlider({
    Name = "Teleport Delay",
    Min = 0.05,
    Max = 1.00,
    Default = config.altTeleportInterval,
    Increment = 0.01,
    Suffix = "s",
    Callback = function(value)
        config.altTeleportInterval = value
    end,
})

updateSavedPositionLabels()

SettingsTab:AddSection("Configs")

controls.configName = SettingsTab:AddInput({
    Name = "Config Name",
    Placeholder = "default",
    Default = settings.selectedConfig,
    Callback = function(value)
        settings.selectedConfig = sanitizeConfigName(value)
        refreshConfigDropdown(settings.selectedConfig)
    end,
})

controls.configList = SettingsTab:AddDropdown({
    Name = "Saved Configs",
    Options = listConfigNames(),
    Default = settings.selectedConfig,
    Callback = function(value)
        settings.selectedConfig = sanitizeConfigName(value)
        if controls.configName then
            controls.configName:Set(settings.selectedConfig, true)
        end
    end,
})

SettingsTab:AddButton({
    Name = "Refresh Config List",
    Callback = function()
        refreshConfigDropdown(settings.selectedConfig)
        notifyStatus("Config list refreshed.")
    end,
})

SettingsTab:AddButton({
    Name = "Save Config",
    Callback = function()
        local name = controls.configName and controls.configName:Get() or settings.selectedConfig
        local ok, err = saveConfig(name)

        if ok then
            if controls.configName then
                controls.configName:Set(settings.selectedConfig, true)
            end
            refreshConfigDropdown(settings.selectedConfig)
            notifyStatus("Saved config: " .. settings.selectedConfig)
        else
            notifyStatus("Save failed: " .. tostring(err), true, 2.5)
        end
    end,
})

SettingsTab:AddButton({
    Name = "Load Config",
    Callback = function()
        local name = settings.selectedConfig
        local ok, err = loadConfig(name)

        if ok then
            if controls.configName then
                controls.configName:Set(settings.selectedConfig, true)
            end
            notifyStatus("Loaded config: " .. settings.selectedConfig)
        else
            notifyStatus("Load failed: " .. tostring(err), true, 2.5)
        end
    end,
})

SettingsTab:AddButton({
    Name = "Delete Config",
    Callback = function()
        local name = settings.selectedConfig
        local ok, err = deleteConfig(name)

        if ok then
            if controls.configName then
                controls.configName:Set(settings.selectedConfig, true)
            end

            if readAutoLoadConfigName() == sanitizeConfigName(name) then
                clearAutoLoadConfig()
            else
                updateAutoLoadLabel()
            end

            notifyStatus("Deleted config: " .. sanitizeConfigName(name))
        else
            notifyStatus("Delete failed: " .. tostring(err), true, 2.5)
        end
    end,
})

autoLoadLabel = SettingsTab:AddLabel("Auto Load: none | UserId: " .. tostring(LocalPlayer and LocalPlayer.UserId or 0))
updateAutoLoadLabel()

SettingsTab:AddButton({
    Name = "Set as Auto Load",
    Callback = function()
        local name = controls.configName and controls.configName:Get() or settings.selectedConfig
        local ok, err = setAutoLoadConfig(name)

        if ok then
            if controls.configName then
                controls.configName:Set(settings.selectedConfig, true)
            end

            notifyStatus("Auto Load set: " .. settings.selectedConfig)
        else
            notifyStatus("Auto Load failed: " .. tostring(err), true, 2.5)
        end
    end,
})

SettingsTab:AddButton({
    Name = "Clear Auto Load",
    Callback = function()
        local ok, err = clearAutoLoadConfig()

        if ok then
            notifyStatus("Auto Load cleared.")
        else
            notifyStatus("Clear failed: " .. tostring(err), true, 2.5)
        end
    end,
})

SettingsTab:AddButton({
    Name = "Copy Config JSON",
    Callback = function()
        if type(setclipboard) ~= "function" then
            notifyStatus("setclipboard is not available in this executor", true, 2.5)
            return
        end

        local ok, encoded = pcall(function()
            return HttpService:JSONEncode(collectConfigData())
        end)

        if not ok then
            notifyStatus("Copy failed: " .. tostring(encoded), true, 2.5)
            return
        end

        setclipboard(encoded)
        notifyStatus("Config JSON copied.")
    end,
})

SettingsTab:AddSection("Interface")

controls.theme = SettingsTab:AddDropdown({
    Name = "GUI Theme",
    Options = Window:GetThemeNames(),
    Default = settings.theme,
    Callback = function(value)
        local themeName = value or "Dark"
        if Window:SetTheme(themeName) then
            settings.theme = themeName
            applyWatermarkTheme()
        end
    end,
})

controls.menuBind = SettingsTab:AddKeybind({
    Name = "Hide GUI Bind",
    Default = Enum.KeyCode.RightShift,
    Changed = function(keyCode)
        local nextKey = keyCode or Enum.KeyCode.RightShift
        Window:SetToggleKey(nextKey)
        settings.menuBind = nextKey.Name
        notifyStatus("Hide bind: " .. nextKey.Name)
    end,
})

SettingsTab:AddSection("Session")

controls.antiAfk = SettingsTab:AddToggle({
    Name = "Anti-AFK",
    Description = "Idle protection with fallback methods",
    Default = state.antiAfk,
    Callback = function(value)
        setState("antiAfk", value)
    end,
})

controls.antiAfkMethod = SettingsTab:AddDropdown({
    Name = "Anti-AFK Method",
    Options = ANTI_AFK_METHODS,
    Default = config.antiAfkMethod,
    Callback = function(value)
        config.antiAfkMethod = normalizeOption(value, ANTI_AFK_METHODS, "Mixed")

        if state.antiAfk then
            performAntiAfk()
        end
    end,
})

controls.antiAfkInterval = SettingsTab:AddSlider({
    Name = "Anti-AFK Pulse",
    Min = 15,
    Max = 600,
    Default = config.antiAfkInterval,
    Increment = 5,
    Suffix = "s",
    Callback = function(value)
        config.antiAfkInterval = value
    end,
})

controls.autoReconnect = SettingsTab:AddToggle({
    Name = "Auto Reconnect",
    Description = "Reconnect on kick/disconnect prompts",
    Default = state.autoReconnect,
    Callback = function(value)
        setState("autoReconnect", value)
    end,
})

controls.autoReconnectDelay = SettingsTab:AddSlider({
    Name = "Reconnect Delay",
    Min = 0,
    Max = 30,
    Default = config.autoReconnectDelay,
    Increment = 0.5,
    Suffix = "s",
    Callback = function(value)
        config.autoReconnectDelay = value
    end,
})

controls.queueScriptOnTeleport = SettingsTab:AddToggle({
    Name = "Queue Script on Reconnect",
    Description = "Requires queue_on_teleport support",
    Default = state.queueScriptOnTeleport,
    Callback = function(value)
        state.queueScriptOnTeleport = value == true
    end,
})

SettingsTab:AddButton({
    Name = "Reset All Toggles",
    Callback = function()
        for _, key in ipairs(stateKeys) do
            if controls[key] then
                controls[key]:Set(false)
            else
                state[key] = false
            end
        end

        notifyStatus("All toggles disabled.")
    end,
})

SettingsTab:AddButton({
    Name = "Show Loader Status",
    Callback = function()
        notifyStatus("Blasphemy is running.")
    end,
})

SettingsTab:AddButton({
    Name = "Destroy GUI",
    Callback = function()
        for _, key in ipairs(stateKeys) do
            state[key] = false
        end

        disableAutoReset()
        disableAltPositionLock()
        disableAntiAfk()
        disableAutoReconnect()
        cleanupPlayerMovement()
        restoreAllOptimizations()
        clearTargetHighlight()
        Window:Destroy()
    end,
})

SettingsTab:AddSection("Advanced")

controls.keyHoldTime = SettingsTab:AddSlider({
    Name = "Key Hold Time",
    Min = 0.005,
    Max = 0.080,
    Default = config.keyHoldTime,
    Increment = 0.005,
    Suffix = "s",
    Callback = function(value)
        config.keyHoldTime = value
    end,
})

controls.mouseHoldTime = SettingsTab:AddSlider({
    Name = "Mouse Hold Time",
    Min = 0.005,
    Max = 0.080,
    Default = config.mouseHoldTime,
    Increment = 0.005,
    Suffix = "s",
    Callback = function(value)
        config.mouseHoldTime = value
    end,
})

controls.evasiveSideHoldTime = SettingsTab:AddSlider({
    Name = "Evasive D Hold",
    Min = 0.010,
    Max = 0.140,
    Default = config.evasiveSideHoldTime,
    Increment = 0.005,
    Suffix = "s",
    Callback = function(value)
        config.evasiveSideHoldTime = value
    end,
})

controls.antiVoidSafeY = SettingsTab:AddSlider({
    Name = "Anti-Void Safe Y",
    Min = -50,
    Max = 20,
    Default = config.antiVoidSafeY,
    Increment = 1,
    Suffix = "y",
    Callback = function(value)
        config.antiVoidSafeY = value
    end,
})

controls.antiVoidTriggerY = SettingsTab:AddSlider({
    Name = "Anti-Void Trigger Y",
    Min = -120,
    Max = -5,
    Default = config.antiVoidTriggerY,
    Increment = 1,
    Suffix = "y",
    Callback = function(value)
        config.antiVoidTriggerY = value
    end,
})

deferTask(function()
    local ok, result = tryAutoLoadConfig()

    if ok then
        notifyStatus("Auto-loaded config: " .. tostring(result))
    elseif result ~= "No auto-load config set" then
        notifyStatus("Auto-load failed: " .. tostring(result), true, 2.5)
    end
end)
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
