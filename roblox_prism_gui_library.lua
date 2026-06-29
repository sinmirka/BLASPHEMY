-- Prism GUI Library
-- Single-file Roblox GUI helper for loadstring usage.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library
Library.Version = "1.1.1"

local unpackValues = table.unpack or unpack

local function spawnTask(callback)
    if task and task.spawn then
        task.spawn(callback)
    else
        coroutine.wrap(callback)()
    end
end

local Theme = {
    Background = Color3.fromRGB(15, 17, 23),
    BackgroundSoft = Color3.fromRGB(20, 23, 31),
    Sidebar = Color3.fromRGB(18, 21, 29),
    Header = Color3.fromRGB(24, 28, 38),
    Card = Color3.fromRGB(27, 31, 42),
    CardHover = Color3.fromRGB(33, 38, 51),
    Stroke = Color3.fromRGB(58, 67, 86),
    Text = Color3.fromRGB(240, 243, 249),
    Muted = Color3.fromRGB(143, 153, 171),
    Accent = Color3.fromRGB(76, 211, 171),
    AccentBlue = Color3.fromRGB(91, 148, 255),
    Danger = Color3.fromRGB(239, 91, 106),
    SwitchOff = Color3.fromRGB(56, 63, 79),
    Knob = Color3.fromRGB(248, 250, 252),
}

local function create(className, properties)
    local instance = Instance.new(className)
    for key, value in pairs(properties or {}) do
        instance[key] = value
    end
    return instance
end

local function safeCall(callback, ...)
    if type(callback) ~= "function" then
        return
    end

    local args = { ... }
    local argCount = select("#", ...)

    spawnTask(function()
        local ok, err = pcall(function()
            callback(unpackValues(args, 1, argCount))
        end)

        if not ok then
            warn("[PrismGui] callback error: " .. tostring(err))
        end
    end)
end

local function tween(instance, duration, properties)
    local info = TweenInfo.new(duration or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweenObject = TweenService:Create(instance, info, properties)
    tweenObject:Play()
    return tweenObject
end

local function addCorner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent,
    })
end

local function addStroke(parent, transparency)
    return create("UIStroke", {
        Color = Theme.Stroke,
        Transparency = transparency or 0.45,
        Thickness = 1,
        Parent = parent,
    })
end

local function getGuiParents()
    local parents = {}

    local okHui, hui = pcall(function()
        if gethui then
            return gethui()
        end
        return nil
    end)

    if okHui and hui then
        table.insert(parents, hui)
    end

    local okCore, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)

    if okCore and coreGui then
        table.insert(parents, coreGui)
    end

    if LocalPlayer then
        local okPlayerGui, playerGui = pcall(function()
            return LocalPlayer:WaitForChild("PlayerGui")
        end)

        if okPlayerGui and playerGui then
            table.insert(parents, playerGui)
        end
    end

    return parents
end

local function parentGui(screenGui, guiName)
    for _, parent in ipairs(getGuiParents()) do
        pcall(function()
            local existing = parent:FindFirstChild(guiName)
            if existing then
                existing:Destroy()
            end
        end)
    end

    for _, parent in ipairs(getGuiParents()) do
        local ok = pcall(function()
            screenGui.Parent = parent
        end)

        if ok and screenGui.Parent == parent then
            return true
        end
    end

    return false
end

local function getViewportSize()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end

    return Vector2.new(1280, 720)
end

local function setButtonHover(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        tween(button, 0.12, { BackgroundColor3 = hoverColor })
    end)

    button.MouseLeave:Connect(function()
        tween(button, 0.12, { BackgroundColor3 = normalColor })
    end)
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

function Library:CreateWindow(config)
    config = config or {}

    local title = config.Title or "Prism"
    local subtitle = config.Subtitle or "Interface"
    local guiName = config.Name or "PrismGui"
    local size = config.Size or Vector2.new(590, 470)
    local collapsedHeight = 44
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    local startPosition = config.Position

    local screenGui = create("ScreenGui", {
        Name = guiName,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = config.DisplayOrder or 100000,
    })

    parentGui(screenGui, guiName)

    local viewport = getViewportSize()
    local position = startPosition or UDim2.fromOffset(
        math.floor((viewport.X - size.X) / 2),
        math.floor((viewport.Y - size.Y) / 2)
    )

    local main = create("Frame", {
        Name = "Main",
        Position = position,
        Size = UDim2.fromOffset(size.X, size.Y),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = screenGui,
    })
    addCorner(main, 9)
    addStroke(main, 0.22)

    create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 23, 31)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 14, 19)),
        }),
        Rotation = 90,
        Parent = main,
    })

    local titleBar = create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, collapsedHeight),
        BackgroundColor3 = Theme.Header,
        BorderSizePixel = 0,
        Parent = main,
    })
    addCorner(titleBar, 9)

    create("Frame", {
        Name = "HeaderCornerCover",
        Position = UDim2.new(0, 0, 1, -9),
        Size = UDim2.new(1, 0, 0, 9),
        BackgroundColor3 = Theme.Header,
        BorderSizePixel = 0,
        Parent = titleBar,
    })

    local accentLine = create("Frame", {
        Name = "AccentLine",
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = titleBar,
    })

    create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.AccentBlue),
        }),
        Parent = accentLine,
    })

    local titleLabel = create("TextLabel", {
        Name = "Title",
        Position = UDim2.fromOffset(16, 7),
        Size = UDim2.new(1, -130, 0, 18),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = titleBar,
    })

    local subtitleLabel = create("TextLabel", {
        Name = "Subtitle",
        Position = UDim2.fromOffset(16, 24),
        Size = UDim2.new(1, -130, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = subtitle,
        TextColor3 = Theme.Muted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = titleBar,
    })

    local minimizeButton = create("TextButton", {
        Name = "Minimize",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -50, 0.5, 0),
        Size = UDim2.fromOffset(30, 28),
        BackgroundColor3 = Color3.fromRGB(36, 42, 54),
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "-",
        TextColor3 = Theme.Text,
        TextSize = 18,
        Parent = titleBar,
    })
    addCorner(minimizeButton, 7)
    setButtonHover(minimizeButton, Color3.fromRGB(36, 42, 54), Color3.fromRGB(47, 55, 70))

    local closeButton = create("TextButton", {
        Name = "Close",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(30, 28),
        BackgroundColor3 = Color3.fromRGB(43, 36, 46),
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "X",
        TextColor3 = Theme.Danger,
        TextSize = 13,
        Parent = titleBar,
    })
    addCorner(closeButton, 7)
    setButtonHover(closeButton, Color3.fromRGB(43, 36, 46), Color3.fromRGB(63, 43, 53))

    local body = create("Frame", {
        Name = "Body",
        Position = UDim2.fromOffset(0, collapsedHeight),
        Size = UDim2.new(1, 0, 1, -collapsedHeight),
        BackgroundTransparency = 1,
        Parent = main,
    })

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, 146, 1, 0),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = body,
    })

    create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = sidebar,
    })

    local tabList = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = sidebar,
    })

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(146, 0),
        Size = UDim2.new(1, -146, 1, 0),
        BackgroundTransparency = 1,
        Parent = body,
    })

    local pages = create("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.new(1, -28, 1, -28),
        BackgroundTransparency = 1,
        Parent = content,
    })

    local window = setmetatable({
        Gui = screenGui,
        Main = main,
        Body = body,
        Pages = pages,
        TitleBar = titleBar,
        Tabs = {},
        SelectedTab = nil,
        Size = size,
        Collapsed = false,
        ToggleKey = toggleKey,
    }, Window)

    function window:SetCollapsed(value)
        self.Collapsed = value == true
        minimizeButton.Text = self.Collapsed and "+" or "-"
        body.Visible = not self.Collapsed

        local targetHeight = self.Collapsed and collapsedHeight or self.Size.Y
        tween(main, 0.18, {
            Size = UDim2.fromOffset(self.Size.X, targetHeight),
        })
    end

    function window:SetVisible(value)
        screenGui.Enabled = value == true
    end

    function window:ToggleVisible()
        screenGui.Enabled = not screenGui.Enabled
    end

    function window:Destroy()
        screenGui:Destroy()
    end

    function window:IsMouseOver()
        if not screenGui.Enabled or not main.Visible then
            return false
        end

        local location = UserInputService:GetMouseLocation()
        local position = main.AbsolutePosition
        local absoluteSize = main.AbsoluteSize

        return location.X >= position.X
            and location.X <= position.X + absoluteSize.X
            and location.Y >= position.Y
            and location.Y <= position.Y + absoluteSize.Y
    end

    function window:SelectTab(tab)
        if type(tab) == "string" then
            tab = self.Tabs[tab]
        end

        if not tab or self.SelectedTab == tab then
            return
        end

        for _, item in pairs(self.Tabs) do
            local selected = item == tab
            item.Page.Visible = selected
            tween(item.Button, 0.15, {
                BackgroundColor3 = selected and Theme.CardHover or Color3.fromRGB(21, 25, 34),
            })
            item.Button.TextColor3 = selected and Theme.Text or Theme.Muted
            item.Accent.Visible = selected
        end

        self.SelectedTab = tab
    end

    function window:AddTab(tabName)
        local order = 0
        for _ in pairs(self.Tabs) do
            order = order + 1
        end

        local button = create("TextButton", {
            Name = tabName .. "Tab",
            LayoutOrder = order,
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Color3.fromRGB(21, 25, 34),
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamSemibold,
            Text = tabName,
            TextColor3 = Theme.Muted,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = sidebar,
        })
        addCorner(button, 8)

        create("UIPadding", {
            PaddingLeft = UDim.new(0, 14),
            Parent = button,
        })

        local accent = create("Frame", {
            Name = "Accent",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(3, 18),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Visible = false,
            Parent = button,
        })
        addCorner(accent, 3)

        local page = create("ScrollingFrame", {
            Name = tabName .. "Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            CanvasSize = UDim2.fromOffset(0, 0),
            Visible = false,
            Parent = pages,
        })

        create("UIPadding", {
            PaddingBottom = UDim.new(0, 12),
            Parent = page,
        })

        local layout = create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            Parent = page,
        })

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 16)
        end)

        local tab = setmetatable({
            Name = tabName,
            Window = self,
            Button = button,
            Accent = accent,
            Page = page,
            Layout = layout,
            ItemCount = 0,
        }, Tab)

        self.Tabs[tabName] = tab

        button.Activated:Connect(function()
            self:SelectTab(tab)
        end)

        button.MouseEnter:Connect(function()
            if self.SelectedTab ~= tab then
                tween(button, 0.12, { BackgroundColor3 = Color3.fromRGB(26, 31, 42) })
            end
        end)

        button.MouseLeave:Connect(function()
            if self.SelectedTab ~= tab then
                tween(button, 0.12, { BackgroundColor3 = Color3.fromRGB(21, 25, 34) })
            end
        end)

        if not self.SelectedTab then
            self:SelectTab(tab)
        end

        return tab
    end

    minimizeButton.Activated:Connect(function()
        window:SetCollapsed(not window.Collapsed)
    end)

    closeButton.Activated:Connect(function()
        screenGui.Enabled = false
    end)

    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == toggleKey then
            screenGui.Enabled = not screenGui.Enabled
        end
    end)

    local dragging = false
    local dragStart = nil
    local startPositionVector = nil

    local function clampToScreen(x, y)
        local absoluteSize = main.AbsoluteSize
        local screenSize = getViewportSize()
        local maxX = math.max(8, screenSize.X - absoluteSize.X - 8)
        local maxY = math.max(8, screenSize.Y - absoluteSize.Y - 8)

        return math.clamp(x, 8, maxX), math.clamp(y, 8, maxY)
    end

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        dragStart = input.Position
        startPositionVector = main.AbsolutePosition

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart
        local x, y = clampToScreen(startPositionVector.X + delta.X, startPositionVector.Y + delta.Y)
        main.Position = UDim2.fromOffset(x, y)
    end)

    return window
end

function Tab:_nextOrder()
    self.ItemCount = self.ItemCount + 1
    return self.ItemCount
end

function Tab:AddSection(name)
    local label = create("TextLabel", {
        Name = "Section",
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = string.upper(name or "Section"),
        TextColor3 = Theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Page,
    })

    return label
end

function Tab:AddLabel(text)
    local row = create("Frame", {
        Name = "Label",
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        Parent = self.Page,
    })
    addCorner(row, 8)
    addStroke(row, 0.58)

    create("TextLabel", {
        Name = "Text",
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -28, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = text or "",
        TextColor3 = Theme.Muted,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    return row
end

function Tab:AddButton(config)
    config = config or {}

    local row = create("TextButton", {
        Name = "Button",
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = self.Page,
    })
    addCorner(row, 8)
    addStroke(row, 0.58)
    setButtonHover(row, Theme.Card, Theme.CardHover)

    create("TextLabel", {
        Name = "Label",
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -62, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = config.Name or "Button",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    create("TextLabel", {
        Name = "Arrow",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(24, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = ">",
        TextColor3 = Theme.Accent,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    row.Activated:Connect(function()
        safeCall(config.Callback)
    end)

    return row
end

function Tab:AddToggle(config)
    config = config or {}

    local value = config.Default == true
    local object = {}

    local row = create("TextButton", {
        Name = "Toggle",
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = self.Page,
    })
    addCorner(row, 8)
    addStroke(row, 0.58)
    setButtonHover(row, Theme.Card, Theme.CardHover)

    create("TextLabel", {
        Name = "Label",
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -112, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = config.Name or "Toggle",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    create("TextLabel", {
        Name = "Description",
        Position = UDim2.fromOffset(14, 32),
        Size = UDim2.new(1, -112, 0, 18),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = config.Description or "",
        TextColor3 = Theme.Muted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local switch = create("Frame", {
        Name = "Switch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(56, 28),
        BackgroundColor3 = Theme.SwitchOff,
        BorderSizePixel = 0,
        Parent = row,
    })
    addCorner(switch, 14)

    local knob = create("Frame", {
        Name = "Knob",
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = Theme.Knob,
        BorderSizePixel = 0,
        Parent = switch,
    })
    addCorner(knob, 11)

    local function render()
        tween(switch, 0.16, {
            BackgroundColor3 = value and Theme.Accent or Theme.SwitchOff,
        })
        tween(knob, 0.16, {
            Position = value and UDim2.fromOffset(31, 3) or UDim2.fromOffset(3, 3),
        })
    end

    function object:Set(nextValue, silent)
        value = nextValue == true
        render()

        if not silent then
            safeCall(config.Callback, value)
        end
    end

    function object:Get()
        return value
    end

    row.Activated:Connect(function()
        object:Set(not value)
    end)

    render()
    safeCall(config.Callback, value)

    return object
end

function Tab:AddSlider(config)
    config = config or {}

    local minValue = config.Min or 0
    local maxValue = config.Max or 100
    local increment = config.Increment or 1
    local suffix = config.Suffix or ""
    local value = config.Default or minValue
    local dragging = false
    local object = {}

    local row = create("Frame", {
        Name = "Slider",
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 72),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        Parent = self.Page,
    })
    addCorner(row, 8)
    addStroke(row, 0.58)

    local label = create("TextLabel", {
        Name = "Label",
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -110, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = config.Name or "Slider",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local valueLabel = create("TextLabel", {
        Name = "Value",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 10),
        Size = UDim2.fromOffset(92, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Theme.Accent,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local track = create("TextButton", {
        Name = "Track",
        Position = UDim2.fromOffset(14, 43),
        Size = UDim2.new(1, -28, 0, 8),
        BackgroundColor3 = Color3.fromRGB(50, 57, 73),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = row,
    })
    addCorner(track, 4)

    local fill = create("Frame", {
        Name = "Fill",
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    addCorner(fill, 4)

    local knob = create("Frame", {
        Name = "Knob",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Theme.Knob,
        BorderSizePixel = 0,
        Parent = track,
    })
    addCorner(knob, 8)

    local function snap(number)
        local snapped = math.floor(((number - minValue) / increment) + 0.5) * increment + minValue
        return math.clamp(snapped, minValue, maxValue)
    end

    local function format(number)
        local decimals = increment < 1 and 2 or 0
        local formatted = string.format("%." .. decimals .. "f", number)
        return formatted .. suffix
    end

    local function render()
        local alpha = 0
        if maxValue > minValue then
            alpha = (value - minValue) / (maxValue - minValue)
        end

        alpha = math.clamp(alpha, 0, 1)
        valueLabel.Text = format(value)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.fromScale(alpha, 0.5)
    end

    local function setFromX(x)
        local left = track.AbsolutePosition.X
        local width = math.max(1, track.AbsoluteSize.X)
        local alpha = math.clamp((x - left) / width, 0, 1)
        object:Set(minValue + (maxValue - minValue) * alpha)
    end

    function object:Set(nextValue, silent)
        value = snap(nextValue)
        render()

        if not silent then
            safeCall(config.Callback, value)
        end
    end

    function object:Get()
        return value
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        setFromX(input.Position.X)
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        setFromX(input.Position.X)
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    object:Set(value, true)
    safeCall(config.Callback, value)

    return object
end

function Tab:AddDropdown(config)
    config = config or {}

    local options = config.Options or {}
    local value = config.Default or options[1]
    local open = false
    local object = {}

    local row = create("Frame", {
        Name = "Dropdown",
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.Page,
    })
    addCorner(row, 8)
    addStroke(row, 0.58)

    create("TextLabel", {
        Name = "Label",
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -112, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = config.Name or "Dropdown",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local selectedButton = create("TextButton", {
        Name = "Selected",
        Position = UDim2.fromOffset(14, 32),
        Size = UDim2.new(1, -28, 0, 22),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        Text = "",
        TextColor3 = Theme.Muted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local arrow = create("TextLabel", {
        Name = "Arrow",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 31),
        Size = UDim2.fromOffset(24, 24),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "v",
        TextColor3 = Theme.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    local optionFrame = create("ScrollingFrame", {
        Name = "Options",
        Position = UDim2.fromOffset(10, 62),
        Size = UDim2.new(1, -20, 0, 0),
        BackgroundColor3 = Color3.fromRGB(22, 26, 35),
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.fromOffset(0, 0),
        Visible = false,
        Parent = row,
    })
    addCorner(optionFrame, 7)

    local optionLayout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = optionFrame,
    })

    create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = optionFrame,
    })

    local function setOpen(nextOpen)
        open = nextOpen == true
        local optionHeight = open and (math.min(#options, 7) * 30 + 12) or 0

        optionFrame.Visible = open
        arrow.Text = open and "^" or "v"
        row.Size = UDim2.new(1, 0, 0, 62 + optionHeight)
        optionFrame.Size = UDim2.new(1, -20, 0, optionHeight)
    end

    local function rebuild()
        for _, child in ipairs(optionFrame:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end

        for index, option in ipairs(options) do
            local optionButton = create("TextButton", {
                Name = "Option",
                LayoutOrder = index,
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = tostring(option) == tostring(value) and Color3.fromRGB(34, 43, 56) or Color3.fromRGB(27, 32, 43),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Font = Enum.Font.Gotham,
                Text = tostring(option),
                TextColor3 = tostring(option) == tostring(value) and Theme.Text or Theme.Muted,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = optionFrame,
            })
            addCorner(optionButton, 6)

            create("UIPadding", {
                PaddingLeft = UDim.new(0, 10),
                Parent = optionButton,
            })

            optionButton.Activated:Connect(function()
                object:Set(option)
                setOpen(false)
            end)
        end

        optionFrame.CanvasSize = UDim2.fromOffset(0, #options * 30 + 12)
        selectedButton.Text = value and tostring(value) or "None"
        setOpen(open)
    end

    function object:Set(nextValue, silent)
        value = nextValue
        selectedButton.Text = value and tostring(value) or "None"
        rebuild()

        if not silent then
            safeCall(config.Callback, value)
        end
    end

    function object:Get()
        return value
    end

    function object:SetOptions(nextOptions, nextValue)
        options = nextOptions or {}

        if nextValue ~= nil then
            local exists = false
            for _, option in ipairs(options) do
                if option == nextValue then
                    exists = true
                    break
                end
            end

            value = exists and nextValue or options[1]
        elseif value == nil and options[1] ~= nil then
            value = options[1]
        else
            local stillExists = false
            for _, option in ipairs(options) do
                if option == value then
                    stillExists = true
                    break
                end
            end

            if not stillExists then
                value = options[1]
                safeCall(config.Callback, value)
            end
        end

        rebuild()
    end

    selectedButton.Activated:Connect(function()
        setOpen(not open)
    end)

    rebuild()
    safeCall(config.Callback, value)

    return object
end

function Tab:AddKeybind(config)
    config = config or {}

    local value = config.Default
    local listening = false
    local object = {}

    local row = create("TextButton", {
        Name = "Keybind",
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = self.Page,
    })
    addCorner(row, 8)
    addStroke(row, 0.58)
    setButtonHover(row, Theme.Card, Theme.CardHover)

    create("TextLabel", {
        Name = "Label",
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -128, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = config.Name or "Keybind",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local keyBox = create("TextLabel", {
        Name = "Key",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(98, 28),
        BackgroundColor3 = Color3.fromRGB(22, 26, 35),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "None",
        TextColor3 = Theme.Muted,
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })
    addCorner(keyBox, 7)
    addStroke(keyBox, 0.66)

    local function keyName(keyCode)
        if not keyCode or keyCode == Enum.KeyCode.Unknown then
            return "None"
        end

        return keyCode.Name
    end

    local function render()
        keyBox.Text = listening and "Press..." or keyName(value)
        keyBox.TextColor3 = value and Theme.Text or Theme.Muted
        keyBox.BackgroundColor3 = listening and Color3.fromRGB(32, 44, 51) or Color3.fromRGB(22, 26, 35)
    end

    function object:Set(nextValue, silent)
        value = nextValue
        listening = false
        render()

        if not silent then
            safeCall(config.Changed, value)
        end
    end

    function object:Get()
        return value
    end

    row.Activated:Connect(function()
        listening = true
        render()
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        if listening then
            if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
                object:Set(nil)
            elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                object:Set(input.KeyCode)
            end
            return
        end

        if value and input.KeyCode == value and not gameProcessed then
            safeCall(config.Callback, value)
        end
    end)

    render()
    return object
end

function Tab:AddColorPicker(config)
    config = config or {}

    local palette = config.Palette or {
        Color3.fromRGB(255, 38, 38),
        Color3.fromRGB(255, 145, 56),
        Color3.fromRGB(255, 220, 82),
        Color3.fromRGB(81, 211, 138),
        Color3.fromRGB(76, 211, 171),
        Color3.fromRGB(91, 148, 255),
        Color3.fromRGB(168, 111, 255),
        Color3.fromRGB(248, 250, 252),
    }

    local value = config.Default or palette[1]
    local open = false
    local object = {}

    local row = create("Frame", {
        Name = "ColorPicker",
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.Page,
    })
    addCorner(row, 8)
    addStroke(row, 0.58)

    create("TextLabel", {
        Name = "Label",
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -82, 0, 56),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = config.Name or "Color",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local swatch = create("TextButton", {
        Name = "Swatch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0, 28),
        Size = UDim2.fromOffset(44, 28),
        BackgroundColor3 = value,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = row,
    })
    addCorner(swatch, 7)
    addStroke(swatch, 0.48)

    local paletteFrame = create("Frame", {
        Name = "Palette",
        Position = UDim2.fromOffset(12, 58),
        Size = UDim2.new(1, -24, 0, 34),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = row,
    })

    local layout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = paletteFrame,
    })

    local function setOpen(nextOpen)
        open = nextOpen == true
        paletteFrame.Visible = open
        row.Size = UDim2.new(1, 0, 0, open and 102 or 56)
    end

    function object:Set(nextValue, silent)
        value = nextValue or value
        swatch.BackgroundColor3 = value

        if not silent then
            safeCall(config.Callback, value)
        end
    end

    function object:Get()
        return value
    end

    for index, color in ipairs(palette) do
        local colorButton = create("TextButton", {
            Name = "Color" .. tostring(index),
            LayoutOrder = index,
            Size = UDim2.fromOffset(28, 28),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Parent = paletteFrame,
        })
        addCorner(colorButton, 7)
        addStroke(colorButton, 0.58)

        colorButton.Activated:Connect(function()
            object:Set(color)
            setOpen(false)
        end)
    end

    swatch.Activated:Connect(function()
        setOpen(not open)
    end)

    object:Set(value, true)
    safeCall(config.Callback, value)

    return object
end

if getgenv then
    pcall(function()
        getgenv().PrismGuiLibrary = Library
    end)
end

return Library
