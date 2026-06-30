-- Prism GUI Library
-- Single-file Roblox GUI helper for loadstring usage.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library
Library.Version = "1.4.0"

local unpackValues = table.unpack or unpack

local function spawnTask(callback)
    if task and task.spawn then
        task.spawn(callback)
    else
        coroutine.wrap(callback)()
    end
end

local Theme = {
    Background = Color3.fromRGB(15, 15, 15),
    BackgroundSoft = Color3.fromRGB(22, 22, 22),
    Sidebar = Color3.fromRGB(19, 19, 19),
    Header = Color3.fromRGB(24, 24, 24),
    Card = Color3.fromRGB(28, 28, 28),
    CardHover = Color3.fromRGB(36, 36, 36),
    Stroke = Color3.fromRGB(48, 48, 48),
    Text = Color3.fromRGB(244, 244, 244),
    Muted = Color3.fromRGB(156, 156, 156),
    Accent = Color3.fromRGB(0, 212, 170),
    AccentBlue = Color3.fromRGB(92, 180, 156),
    Danger = Color3.fromRGB(232, 88, 104),
    SwitchOff = Color3.fromRGB(54, 54, 54),
    Knob = Color3.fromRGB(242, 242, 242),
}

Library.ThemeOrder = { "Dark", "Emerald", "Amethyst", "Crimson", "Light" }
Library.Themes = {
    Dark = {
        Background = Color3.fromRGB(15, 15, 15),
        BackgroundSoft = Color3.fromRGB(22, 22, 22),
        Sidebar = Color3.fromRGB(19, 19, 19),
        Header = Color3.fromRGB(24, 24, 24),
        Card = Color3.fromRGB(28, 28, 28),
        CardHover = Color3.fromRGB(36, 36, 36),
        Stroke = Color3.fromRGB(48, 48, 48),
        Text = Color3.fromRGB(244, 244, 244),
        Muted = Color3.fromRGB(156, 156, 156),
        Accent = Color3.fromRGB(0, 212, 170),
        AccentBlue = Color3.fromRGB(92, 180, 156),
        Danger = Color3.fromRGB(232, 88, 104),
        SwitchOff = Color3.fromRGB(54, 54, 54),
        Knob = Color3.fromRGB(242, 242, 242),
    },
    Emerald = {
        Background = Color3.fromRGB(13, 18, 16),
        BackgroundSoft = Color3.fromRGB(18, 25, 22),
        Sidebar = Color3.fromRGB(16, 22, 20),
        Header = Color3.fromRGB(20, 29, 25),
        Card = Color3.fromRGB(23, 34, 29),
        CardHover = Color3.fromRGB(30, 44, 38),
        Stroke = Color3.fromRGB(54, 76, 67),
        Text = Color3.fromRGB(238, 246, 242),
        Muted = Color3.fromRGB(146, 170, 160),
        Accent = Color3.fromRGB(58, 204, 142),
        AccentBlue = Color3.fromRGB(72, 175, 143),
        Danger = Color3.fromRGB(239, 91, 106),
        SwitchOff = Color3.fromRGB(46, 63, 57),
        Knob = Color3.fromRGB(248, 250, 252),
    },
    Amethyst = {
        Background = Color3.fromRGB(18, 16, 22),
        BackgroundSoft = Color3.fromRGB(25, 22, 31),
        Sidebar = Color3.fromRGB(21, 19, 27),
        Header = Color3.fromRGB(29, 25, 36),
        Card = Color3.fromRGB(33, 29, 41),
        CardHover = Color3.fromRGB(42, 36, 53),
        Stroke = Color3.fromRGB(72, 63, 88),
        Text = Color3.fromRGB(243, 240, 247),
        Muted = Color3.fromRGB(164, 154, 178),
        Accent = Color3.fromRGB(163, 126, 220),
        AccentBlue = Color3.fromRGB(145, 128, 207),
        Danger = Color3.fromRGB(239, 91, 127),
        SwitchOff = Color3.fromRGB(58, 51, 70),
        Knob = Color3.fromRGB(248, 250, 252),
    },
    Crimson = {
        Background = Color3.fromRGB(21, 15, 16),
        BackgroundSoft = Color3.fromRGB(29, 20, 22),
        Sidebar = Color3.fromRGB(25, 18, 20),
        Header = Color3.fromRGB(36, 23, 27),
        Card = Color3.fromRGB(43, 28, 32),
        CardHover = Color3.fromRGB(56, 36, 42),
        Stroke = Color3.fromRGB(91, 59, 66),
        Text = Color3.fromRGB(250, 241, 243),
        Muted = Color3.fromRGB(185, 145, 153),
        Accent = Color3.fromRGB(231, 94, 111),
        AccentBlue = Color3.fromRGB(220, 128, 96),
        Danger = Color3.fromRGB(255, 84, 84),
        SwitchOff = Color3.fromRGB(72, 47, 53),
        Knob = Color3.fromRGB(248, 250, 252),
    },
    Light = {
        Background = Color3.fromRGB(241, 242, 244),
        BackgroundSoft = Color3.fromRGB(249, 249, 250),
        Sidebar = Color3.fromRGB(232, 234, 238),
        Header = Color3.fromRGB(252, 252, 253),
        Card = Color3.fromRGB(255, 255, 255),
        CardHover = Color3.fromRGB(240, 242, 246),
        Stroke = Color3.fromRGB(198, 204, 214),
        Text = Color3.fromRGB(24, 30, 42),
        Muted = Color3.fromRGB(93, 105, 124),
        Accent = Color3.fromRGB(30, 154, 118),
        AccentBlue = Color3.fromRGB(56, 142, 118),
        Danger = Color3.fromRGB(214, 64, 80),
        SwitchOff = Color3.fromRGB(188, 197, 210),
        Knob = Color3.fromRGB(255, 255, 255),
    },
}

local function applyThemePreset(themeName)
    local preset = Library.Themes[themeName] or Library.Themes.Dark
    for key, value in pairs(preset) do
        Theme[key] = value
    end
end

applyThemePreset("Dark")

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

local function mixColor(a, b, alpha)
    alpha = math.clamp(alpha or 0.5, 0, 1)

    return Color3.new(
        a.R + (b.R - a.R) * alpha,
        a.G + (b.G - a.G) * alpha,
        a.B + (b.B - a.B) * alpha
    )
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
    local function resolveColor(color)
        if type(color) == "function" then
            return color()
        end

        return color
    end

    button.MouseEnter:Connect(function()
        tween(button, 0.12, { BackgroundColor3 = resolveColor(hoverColor) })
    end)

    button.MouseLeave:Connect(function()
        tween(button, 0.12, { BackgroundColor3 = resolveColor(normalColor) })
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
    local size = config.Size or Vector2.new(600, 470)
    local collapsedHeight = 44
    local sidebarWidth = config.SidebarWidth or 148
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
    addCorner(main, 8)
    addStroke(main, 0.18)

    local titleBar = create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, collapsedHeight),
        BackgroundColor3 = Theme.Header,
        BorderSizePixel = 0,
        Parent = main,
    })
    addCorner(titleBar, 8)

    create("Frame", {
        Name = "HeaderCornerCover",
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8),
        BackgroundColor3 = Theme.Header,
        BorderSizePixel = 0,
        Parent = titleBar,
    })

    local headerDivider = create("Frame", {
        Name = "HeaderDivider",
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        Parent = titleBar,
    })

    local titleLabel = create("TextLabel", {
        Name = "Title",
        Position = UDim2.fromOffset(14, 7),
        Size = UDim2.new(1, -130, 0, 18),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = titleBar,
    })

    local subtitleLabel = create("TextLabel", {
        Name = "Subtitle",
        Position = UDim2.fromOffset(14, 25),
        Size = UDim2.new(1, -130, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = subtitle,
        TextColor3 = Theme.Muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = titleBar,
    })

    local minimizeButton = create("TextButton", {
        Name = "Minimize",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -48, 0.5, 0),
        Size = UDim2.fromOffset(28, 24),
        BackgroundColor3 = Theme.Header,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "-",
        TextColor3 = Theme.Muted,
        TextSize = 16,
        Parent = titleBar,
    })
    addCorner(minimizeButton, 6)
    setButtonHover(minimizeButton, function()
        return Theme.Header
    end, function()
        return Theme.Card
    end)

    local closeButton = create("TextButton", {
        Name = "Close",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(28, 24),
        BackgroundColor3 = Theme.Header,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "X",
        TextColor3 = Theme.Danger,
        TextSize = 13,
        Parent = titleBar,
    })
    addCorner(closeButton, 6)
    setButtonHover(closeButton, function()
        return Theme.Header
    end, function()
        return mixColor(Theme.Card, Theme.Danger, 0.22)
    end)

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
        Size = UDim2.new(0, sidebarWidth, 1, 0),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = body,
    })

    local sidebarDivider = create("Frame", {
        Name = "SidebarDivider",
        Position = UDim2.fromOffset(sidebarWidth, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Theme.Stroke,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        Parent = body,
    })

    create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = sidebar,
    })

    local tabList = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = sidebar,
    })

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(sidebarWidth, 0),
        Size = UDim2.new(1, -sidebarWidth, 1, 0),
        BackgroundTransparency = 1,
        Parent = body,
    })

    local pages = create("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.new(1, -20, 1, -20),
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

    function window:SetToggleKey(keyCode)
        if keyCode and typeof(keyCode) == "EnumItem" then
            toggleKey = keyCode
            self.ToggleKey = keyCode
            return true
        end

        return false
    end

    function window:GetToggleKey()
        return toggleKey
    end

    function window:RefreshTheme()
        main.BackgroundColor3 = Theme.Background
        titleBar.BackgroundColor3 = Theme.Header
        sidebar.BackgroundColor3 = Theme.Sidebar
        headerDivider.BackgroundColor3 = Theme.Stroke
        sidebarDivider.BackgroundColor3 = Theme.Stroke

        for _, descendant in ipairs(main:GetDescendants()) do
            if descendant:IsA("UIStroke") then
                descendant.Color = Theme.Stroke
            elseif descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
                if descendant.Name == "Close" then
                    descendant.TextColor3 = Theme.Danger
                elseif descendant.Name == "Description"
                    or descendant.Name == "Subtitle"
                    or descendant.Name == "Selected"
                    or descendant.Name == "Text"
                    or descendant.Name == "ButtonArrow"
                    or descendant.Name == "Minimize" then
                    descendant.TextColor3 = Theme.Muted
                elseif descendant.Name == "Value" or descendant.Name == "Arrow" or descendant.Name == "Key" or descendant.Name == "Check" then
                    descendant.TextColor3 = Theme.Accent
                else
                    descendant.TextColor3 = Theme.Text
                end
            end

            if descendant:IsA("Frame") or descendant:IsA("TextButton") or descendant:IsA("TextBox") or descendant:IsA("ScrollingFrame") then
                if descendant.Name == "TitleBar" or descendant.Name == "HeaderCornerCover" or descendant.Name == "Minimize" then
                    descendant.BackgroundColor3 = Theme.Header
                elseif descendant.Name == "Sidebar" then
                    descendant.BackgroundColor3 = Theme.Sidebar
                elseif descendant.Name == "HeaderDivider" or descendant.Name == "SidebarDivider" or descendant.Name == "SectionLine" then
                    descendant.BackgroundColor3 = Theme.Stroke
                elseif descendant.Name == "Accent" or descendant.Name == "Fill" then
                    descendant.BackgroundColor3 = Theme.Accent
                elseif descendant.Name == "Switch" then
                    local knob = descendant:FindFirstChild("Knob")
                    if knob and knob.Position.X.Offset > 10 then
                        descendant.BackgroundColor3 = Theme.Accent
                    else
                        descendant.BackgroundColor3 = Theme.SwitchOff
                    end
                elseif descendant.Name == "Knob" then
                    descendant.BackgroundColor3 = Theme.Knob
                elseif descendant.Name == "Close" then
                    descendant.BackgroundColor3 = Theme.Header
                elseif descendant.Name == "Toggle"
                    or descendant.Name == "Slider"
                    or descendant.Name == "Dropdown"
                    or descendant.Name == "MultiDropdown"
                    or descendant.Name == "Button"
                    or descendant.Name == "Keybind"
                    or descendant.Name == "ColorPicker"
                    or descendant.Name == "Input" then
                    descendant.BackgroundColor3 = Theme.Card
                elseif descendant.Name == "InfoLabel" then
                    descendant.BackgroundColor3 = Theme.BackgroundSoft
                elseif descendant.Name == "Key" then
                    descendant.BackgroundColor3 = Theme.BackgroundSoft
                elseif descendant.Name == "Option" then
                    descendant.BackgroundColor3 = Theme.BackgroundSoft
                elseif descendant.Name == "Track" then
                    descendant.BackgroundColor3 = Theme.SwitchOff
                elseif descendant.Name == "Options" or descendant.Name == "TextBox" then
                    descendant.BackgroundColor3 = Theme.BackgroundSoft
                end
            end
        end

        if self.SelectedTab then
            local selectedTab = self.SelectedTab
            self.SelectedTab = nil
            self:SelectTab(selectedTab)
        end
    end

    function window:SetTheme(themeName)
        if not Library.Themes[themeName] then
            return false
        end

        applyThemePreset(themeName)
        self.ThemeName = themeName
        self:RefreshTheme()
        return true
    end

    function window:GetTheme()
        return self.ThemeName or "Dark"
    end

    function window:GetThemeNames()
        local names = {}
        for _, name in ipairs(Library.ThemeOrder) do
            table.insert(names, name)
        end
        return names
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
                BackgroundColor3 = selected and Theme.Card or Theme.Sidebar,
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
            Size = UDim2.new(1, 0, 0, 31),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamSemibold,
            Text = tabName,
            TextColor3 = Theme.Muted,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = sidebar,
        })
        addCorner(button, 7)

        create("UIPadding", {
            PaddingLeft = UDim.new(0, 16),
            PaddingRight = UDim.new(0, 8),
            Parent = button,
        })

        local accent = create("Frame", {
            Name = "Accent",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 4, 0.5, 0),
            Size = UDim2.fromOffset(2, 15),
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
            PaddingBottom = UDim.new(0, 10),
            Parent = page,
        })

        local layout = create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            Parent = page,
        })

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 12)
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
                tween(button, 0.12, { BackgroundColor3 = Theme.BackgroundSoft })
            end
        end)

        button.MouseLeave:Connect(function()
            if self.SelectedTab ~= tab then
                tween(button, 0.12, { BackgroundColor3 = Theme.Sidebar })
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
    local row = create("Frame", {
        Name = "Section",
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Parent = self.Page,
    })

    local label = create("TextLabel", {
        Name = "SectionLabel",
        Position = UDim2.fromOffset(1, 0),
        Size = UDim2.new(0, 156, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = tostring(name or "Section"),
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    create("Frame", {
        Name = "SectionLine",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(1, -170, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Parent = row,
    })

    return row
end

function Tab:AddLabel(text)
    local row = create("Frame", {
        Name = "InfoLabel",
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Theme.BackgroundSoft,
        BorderSizePixel = 0,
        Parent = self.Page,
    })
    addCorner(row, 6)
    addStroke(row, 0.64)

    create("TextLabel", {
        Name = "Text",
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = text or "",
        TextColor3 = Theme.Muted,
        TextSize = 11,
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
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = self.Page,
    })
    addCorner(row, 6)
    addStroke(row, 0.54)
    setButtonHover(row, function()
        return Theme.Card
    end, function()
        return Theme.CardHover
    end)

    create("TextLabel", {
        Name = "Label",
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -52, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = config.Name or "Button",
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    create("TextLabel", {
        Name = "ButtonArrow",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(20, 18),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = ">",
        TextColor3 = Theme.Muted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    row.Activated:Connect(function()
        safeCall(config.Callback)
    end)

    return row
end

function Tab:AddInput(config)
    config = config or {}

    local value = config.Default or ""
    local object = {}

    local row = create("Frame", {
        Name = "Input",
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        Parent = self.Page,
    })
    addCorner(row, 6)
    addStroke(row, 0.54)

    create("TextLabel", {
        Name = "Label",
        Position = UDim2.fromOffset(10, 6),
        Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = config.Name or "Input",
        TextColor3 = Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local box = create("TextBox", {
        Name = "TextBox",
        Position = UDim2.fromOffset(10, 27),
        Size = UDim2.new(1, -20, 0, 20),
        BackgroundColor3 = Theme.BackgroundSoft,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderText = config.Placeholder or "",
        Text = tostring(value),
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.Muted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })
    addCorner(box, 5)
    addStroke(box, 0.66)

    create("UIPadding", {
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
        Parent = box,
    })

    function object:Set(nextValue, silent)
        value = tostring(nextValue or "")
        box.Text = value

        if not silent then
            safeCall(config.Callback, value)
        end
    end

    function object:Get()
        return value
    end

    box.FocusLost:Connect(function()
        object:Set(box.Text)
    end)

    return object
end

function Tab:AddToggle(config)
    config = config or {}

    local value = config.Default == true
    local object = {}

    local row = create("TextButton", {
        Name = "Toggle",
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = self.Page,
    })
    addCorner(row, 6)
    addStroke(row, 0.54)
    setButtonHover(row, function()
        return Theme.Card
    end, function()
        return Theme.CardHover
    end)

    create("TextLabel", {
        Name = "Label",
        Position = UDim2.fromOffset(10, 7),
        Size = UDim2.new(1, -94, 0, 17),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = config.Name or "Toggle",
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    create("TextLabel", {
        Name = "Description",
        Position = UDim2.fromOffset(10, 25),
        Size = UDim2.new(1, -94, 0, 15),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = config.Description or "",
        TextColor3 = Theme.Muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local switch = create("Frame", {
        Name = "Switch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(40, 20),
        BackgroundColor3 = Theme.SwitchOff,
        BorderSizePixel = 0,
        Parent = row,
    })
    addCorner(switch, 10)

    local knob = create("Frame", {
        Name = "Knob",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Theme.Knob,
        BorderSizePixel = 0,
        Parent = switch,
    })
    addCorner(knob, 8)

    local function render()
        tween(switch, 0.16, {
            BackgroundColor3 = value and Theme.Accent or Theme.SwitchOff,
        })
        tween(knob, 0.16, {
            Position = value and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2),
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
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        Parent = self.Page,
    })
    addCorner(row, 6)
    addStroke(row, 0.54)

    local label = create("TextLabel", {
        Name = "Label",
        Position = UDim2.fromOffset(10, 7),
        Size = UDim2.new(1, -96, 0, 17),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = config.Name or "Slider",
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local valueLabel = create("TextLabel", {
        Name = "Value",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 7),
        Size = UDim2.fromOffset(84, 17),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local track = create("TextButton", {
        Name = "Track",
        Position = UDim2.fromOffset(10, 35),
        Size = UDim2.new(1, -20, 0, 5),
        BackgroundColor3 = Theme.SwitchOff,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = row,
    })
    addCorner(track, 2)

    local fill = create("Frame", {
        Name = "Fill",
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    addCorner(fill, 3)

    local knob = create("Frame", {
        Name = "Knob",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(11, 11),
        BackgroundColor3 = Theme.Knob,
        BorderSizePixel = 0,
        Parent = track,
    })
    addCorner(knob, 5)

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
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.Page,
    })
    addCorner(row, 6)
    addStroke(row, 0.54)

    create("TextLabel", {
        Name = "Label",
        Position = UDim2.fromOffset(10, 6),
        Size = UDim2.new(1, -92, 0, 17),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = config.Name or "Dropdown",
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local selectedButton = create("TextButton", {
        Name = "Selected",
        Position = UDim2.fromOffset(10, 27),
        Size = UDim2.new(1, -20, 0, 20),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        Text = "",
        TextColor3 = Theme.Muted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local arrow = create("TextLabel", {
        Name = "Arrow",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 25),
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "v",
        TextColor3 = Theme.Accent,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    local optionFrame = create("ScrollingFrame", {
        Name = "Options",
        Position = UDim2.fromOffset(8, 52),
        Size = UDim2.new(1, -16, 0, 0),
        BackgroundColor3 = Theme.BackgroundSoft,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.fromOffset(0, 0),
        Visible = false,
        Parent = row,
    })
    addCorner(optionFrame, 6)
    addStroke(optionFrame, 0.68)

    local optionLayout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3),
        Parent = optionFrame,
    })

    create("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        Parent = optionFrame,
    })

    local function setOpen(nextOpen)
        open = nextOpen == true
        local optionHeight = open and (math.min(#options, 7) * 25 + 10) or 0

        optionFrame.Visible = open
        arrow.Text = open and "^" or "v"
        row.Size = UDim2.new(1, 0, 0, 52 + optionHeight)
        optionFrame.Size = UDim2.new(1, -16, 0, optionHeight)
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
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = tostring(option) == tostring(value) and Theme.CardHover or Theme.BackgroundSoft,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Font = Enum.Font.Gotham,
                Text = tostring(option),
                TextColor3 = tostring(option) == tostring(value) and Theme.Text or Theme.Muted,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = optionFrame,
            })
            addCorner(optionButton, 5)

            create("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                Parent = optionButton,
            })

            optionButton.Activated:Connect(function()
                object:Set(option)
                setOpen(false)
            end)
        end

        optionFrame.CanvasSize = UDim2.fromOffset(0, #options * 25 + 10)
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

function Tab:AddMultiDropdown(config)
    config = config or {}

    local options = config.Options or {}
    local selected = {}
    local open = false
    local object = {}

    local function normalizeSelection(selection)
        local normalized = {}

        if type(selection) ~= "table" then
            return normalized
        end

        for key, value in pairs(selection) do
            if type(key) == "number" then
                normalized[tostring(value)] = true
            elseif value == true then
                normalized[tostring(key)] = true
            end
        end

        return normalized
    end

    selected = normalizeSelection(config.Default)

    local row = create("Frame", {
        Name = "MultiDropdown",
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.Page,
    })
    addCorner(row, 6)
    addStroke(row, 0.54)

    create("TextLabel", {
        Name = "Label",
        Position = UDim2.fromOffset(10, 6),
        Size = UDim2.new(1, -92, 0, 17),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = config.Name or "Multi Dropdown",
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local selectedButton = create("TextButton", {
        Name = "Selected",
        Position = UDim2.fromOffset(10, 27),
        Size = UDim2.new(1, -20, 0, 20),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        Text = "",
        TextColor3 = Theme.Muted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local arrow = create("TextLabel", {
        Name = "Arrow",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 25),
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "v",
        TextColor3 = Theme.Accent,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    local optionFrame = create("ScrollingFrame", {
        Name = "Options",
        Position = UDim2.fromOffset(8, 52),
        Size = UDim2.new(1, -16, 0, 0),
        BackgroundColor3 = Theme.BackgroundSoft,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.fromOffset(0, 0),
        Visible = false,
        Parent = row,
    })
    addCorner(optionFrame, 6)
    addStroke(optionFrame, 0.68)

    local optionLayout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3),
        Parent = optionFrame,
    })

    create("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        Parent = optionFrame,
    })

    local function selectedList()
        local list = {}
        for name, enabled in pairs(selected) do
            if enabled then
                table.insert(list, name)
            end
        end
        table.sort(list)
        return list
    end

    local function updateSummary()
        local list = selectedList()

        if #list == 0 then
            selectedButton.Text = "None"
        elseif #list <= 2 then
            selectedButton.Text = table.concat(list, ", ")
        else
            selectedButton.Text = tostring(#list) .. " selected"
        end
    end

    local function setOpen(nextOpen)
        open = nextOpen == true
        local optionHeight = open and (math.min(#options, 8) * 25 + 10) or 0

        optionFrame.Visible = open
        arrow.Text = open and "^" or "v"
        row.Size = UDim2.new(1, 0, 0, 52 + optionHeight)
        optionFrame.Size = UDim2.new(1, -16, 0, optionHeight)
    end

    local function rebuild()
        for _, child in ipairs(optionFrame:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end

        for index, option in ipairs(options) do
            local optionName = tostring(option)
            local enabled = selected[optionName] == true
            local optionButton = create("TextButton", {
                Name = "Option",
                LayoutOrder = index,
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = enabled and Theme.CardHover or Theme.BackgroundSoft,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Font = Enum.Font.Gotham,
                Text = optionName,
                TextColor3 = enabled and Theme.Text or Theme.Muted,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = optionFrame,
            })
            addCorner(optionButton, 5)

            create("UIPadding", {
                PaddingLeft = UDim.new(0, 24),
                PaddingRight = UDim.new(0, 8),
                Parent = optionButton,
            })

            create("TextLabel", {
                Name = "Check",
                Position = UDim2.fromOffset(7, 0),
                Size = UDim2.fromOffset(12, 22),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = enabled and "x" or "",
                TextColor3 = Theme.Accent,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = optionButton,
            })

            optionButton.Activated:Connect(function()
                selected[optionName] = not selected[optionName]
                if selected[optionName] ~= true then
                    selected[optionName] = nil
                end

                rebuild()
                safeCall(config.Callback, selectedList())
            end)
        end

        optionFrame.CanvasSize = UDim2.fromOffset(0, #options * 25 + 10)
        updateSummary()
        setOpen(open)
    end

    function object:Set(nextSelection, silent)
        selected = normalizeSelection(nextSelection)
        rebuild()

        if not silent then
            safeCall(config.Callback, selectedList())
        end
    end

    function object:Get()
        return selectedList()
    end

    function object:GetMap()
        local copy = {}
        for name, enabled in pairs(selected) do
            if enabled then
                copy[name] = true
            end
        end
        return copy
    end

    function object:SetOptions(nextOptions, nextSelection)
        options = nextOptions or {}

        if nextSelection ~= nil then
            selected = normalizeSelection(nextSelection)
        end

        rebuild()
    end

    selectedButton.Activated:Connect(function()
        setOpen(not open)
    end)

    rebuild()
    safeCall(config.Callback, selectedList())

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
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = self.Page,
    })
    addCorner(row, 6)
    addStroke(row, 0.54)
    setButtonHover(row, function()
        return Theme.Card
    end, function()
        return Theme.CardHover
    end)

    create("TextLabel", {
        Name = "Label",
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -104, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = config.Name or "Keybind",
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local keyBox = create("TextLabel", {
        Name = "Key",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(86, 24),
        BackgroundColor3 = Theme.BackgroundSoft,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "None",
        TextColor3 = Theme.Muted,
        TextSize = 11,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })
    addCorner(keyBox, 6)
    addStroke(keyBox, 0.62)

    local function keyName(keyCode)
        if not keyCode or keyCode == Enum.KeyCode.Unknown then
            return "None"
        end

        return keyCode.Name
    end

    local function render()
        keyBox.Text = listening and "Press..." or keyName(value)
        keyBox.TextColor3 = value and Theme.Text or Theme.Muted
        keyBox.BackgroundColor3 = listening and Theme.CardHover or Theme.BackgroundSoft
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
        Color3.fromRGB(231, 136, 76),
        Color3.fromRGB(218, 184, 92),
        Color3.fromRGB(95, 190, 129),
        Color3.fromRGB(0, 212, 170),
        Color3.fromRGB(112, 158, 194),
        Color3.fromRGB(163, 126, 220),
        Color3.fromRGB(242, 242, 242),
    }

    local value = config.Default or palette[1]
    local open = false
    local object = {}

    local row = create("Frame", {
        Name = "ColorPicker",
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.Page,
    })
    addCorner(row, 6)
    addStroke(row, 0.54)

    create("TextLabel", {
        Name = "Label",
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -68, 0, 42),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = config.Name or "Color",
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local swatch = create("TextButton", {
        Name = "Swatch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0, 21),
        Size = UDim2.fromOffset(36, 22),
        BackgroundColor3 = value,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = row,
    })
    addCorner(swatch, 6)
    addStroke(swatch, 0.44)

    local paletteFrame = create("Frame", {
        Name = "Palette",
        Position = UDim2.fromOffset(10, 44),
        Size = UDim2.new(1, -20, 0, 28),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = row,
    })

    local layout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = paletteFrame,
    })

    local function setOpen(nextOpen)
        open = nextOpen == true
        paletteFrame.Visible = open
        row.Size = UDim2.new(1, 0, 0, open and 78 or 42)
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
            Size = UDim2.fromOffset(22, 22),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Parent = paletteFrame,
        })
        addCorner(colorButton, 5)
        addStroke(colorButton, 0.54)

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
