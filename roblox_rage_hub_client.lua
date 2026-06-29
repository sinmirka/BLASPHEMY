-- Rage Hub Client
-- Replace GUI_LIBRARY_URL with your raw GitHub link to roblox_prism_gui_library.lua.

local GUI_LIBRARY_URL = "https://cdn.jsdelivr.net/gh/sinmirka/BLASPHEMY@c95f3b0/roblox_prism_gui_library.lua"
local REQUIRED_GUI_LIBRARY_VERSION = "1.3.1"

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

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

local tabsOk, RageTab, SettingsTab = pcall(function()
    local rage = Window:AddTab("Rage")
    Window:AddTab("AutoFarm")
    Window:AddTab("Alt")
    local settings = Window:AddTab("Settings")
    return rage, settings
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
    autoUltimate = false,
    autoBurst = false,
    autoDash = false,
    autoEvasive = false,
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

local stateKeys = {
    "autoM1",
    "backgroundM1",
    "autoSkills",
    "autoUltimate",
    "autoBurst",
    "autoDash",
    "autoEvasive",
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
        version = 1,
        theme = settings.theme or Window:GetTheme(),
        menuBind = keyToName(Window:GetToggleKey()),
        targetBind = controls.targetBind and keyToName(controls.targetBind:Get()) or nil,
        targetName = state.targetName,
        states = {},
        config = {},
    }

    for _, key in ipairs(stateKeys) do
        data.states[key] = state[key] == true
    end

    for _, key in ipairs(configKeys) do
        data.config[key] = config[key]
    end

    data.config.highlightColor = colorToData(config.highlightColor)
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

RageTab:AddSection("Combat")

controls.autoM1 = RageTab:AddToggle({
    Name = "Auto M1",
    Description = "Left mouse click at 10 cps",
    Default = false,
    Callback = function(value)
        setState("autoM1", value)
    end,
})

controls.backgroundM1 = RageTab:AddToggle({
    Name = "Background M1",
    Description = "Virtual LMB with GUI guard",
    Default = false,
    Callback = function(value)
        setState("backgroundM1", value)
    end,
})

controls.autoSkills = RageTab:AddToggle({
    Name = "Auto Skills",
    Description = "Press 1-4 and activate first 4 tools",
    Default = false,
    Callback = function(value)
        setState("autoSkills", value)
    end,
})

controls.autoUltimate = RageTab:AddToggle({
    Name = "Auto Ultimate",
    Description = "Press G once per second",
    Default = false,
    Callback = function(value)
        setState("autoUltimate", value)
    end,
})

controls.autoBurst = RageTab:AddToggle({
    Name = "Auto Burst",
    Description = "Spam R at 10 cps",
    Default = false,
    Callback = function(value)
        setState("autoBurst", value)
    end,
})

controls.autoDash = RageTab:AddToggle({
    Name = "Auto Dash/Wall Combo",
    Description = "Spam Q at 10 cps",
    Default = false,
    Callback = function(value)
        setState("autoDash", value)
    end,
})

controls.autoEvasive = RageTab:AddToggle({
    Name = "Auto Evasive",
    Description = "Hold D while pressing Q",
    Default = false,
    Callback = function(value)
        setState("autoEvasive", value)
    end,
})

RageTab:AddSection("Timings")

controls.autoM1Interval = RageTab:AddSlider({
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

controls.autoSkillsInterval = RageTab:AddSlider({
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

controls.autoBurstInterval = RageTab:AddSlider({
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

controls.autoEvasiveInterval = RageTab:AddSlider({
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

controls.autoUltimateInterval = RageTab:AddSlider({
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
            notifyStatus("Deleted config: " .. sanitizeConfigName(name))
        else
            notifyStatus("Delete failed: " .. tostring(err), true, 2.5)
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
        notifyStatus("BLASPHEMY is running.")
    end,
})

SettingsTab:AddButton({
    Name = "Destroy GUI",
    Callback = function()
        for _, key in ipairs(stateKeys) do
            state[key] = false
        end

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
