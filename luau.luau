-- ================================================================
-- NEXUS UI (Engine-Native Shadow & Tab Drag Edition)
-- Suitable for loadstring hosting
-- ================================================================

local NexusUI = {}
NexusUI.__index = NexusUI

-- Color Palette Configuration
NexusUI.Theme = {
    Background = Color3.fromRGB(17, 17, 17),
    Header = Color3.fromRGB(22, 22, 22),
    Sidebar = Color3.fromRGB(20, 20, 20),
    Container = Color3.fromRGB(25, 25, 25),
    Element = Color3.fromRGB(30, 30, 30),
    Accent = Color3.fromRGB(90, 120, 255),
    TextPrimary = Color3.fromRGB(255, 255, 255),   -- White when selected
    TextSecondary = Color3.fromRGB(120, 120, 120), -- Gray when unselected
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function create(className, properties, children)
    local instance = Instance.new(className)
    for prop, val in pairs(properties or {}) do
        instance[prop] = val
    end
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    return instance
end

local function animate(instance, tweenInfo, properties)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Engine Native UI Shadow (No Image Assets)
local function applyNativeShadow(frame)
    create("UIStroke", {
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 3,
        Transparency = 0.4,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = frame,
    })
end

function NexusUI.CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "Nexus Hub"
    local windowSize = config.Size or UDim2.fromOffset(580, 380)

    local screenGui = create("ScreenGui", {
        Name = "NexusUI_Framework",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    pcall(function() screenGui.Parent = CoreGui end)
    if not screenGui.Parent then
        screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end

    local mainFrame = create("Frame", {
        Name = "MainFrame",
        Size = windowSize,
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = NexusUI.Theme.Background,
        BorderSizePixel = 0,
        Parent = screenGui,
    })

    applyNativeShadow(mainFrame)

    -- Header Bar
    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = NexusUI.Theme.Header,
        BorderSizePixel = 0,
        Parent = mainFrame,
    }, {
        create("TextLabel", {
            Text = string.upper(windowTitle),
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = NexusUI.Theme.TextPrimary,
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.fromOffset(12, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
        }),
    })

    -- Dragging Logic for Window
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Sidebar Area with Layout Sorting
    local sidebarLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 130, 1, -38),
        Position = UDim2.fromOffset(0, 38),
        BackgroundColor3 = NexusUI.Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = mainFrame,
    }, {
        sidebarLayout,
        create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
    })

    -- Content Container Area
    local contentArea = create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -130, 1, -38),
        Position = UDim2.fromOffset(130, 38),
        BackgroundTransparency = 1,
        Parent = mainFrame,
    })

    local Window = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        Tabs = {},
        ToggleKey = Enum.KeyCode.RightControl,
        Connections = {},
        TabCount = 0,
    }

    -- Keybind Listener Connection
    local inputConnection = UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Window.ToggleKey then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)
    table.insert(Window.Connections, inputConnection)

    -- Window Unload Method
    function Window:Unload()
        for _, conn in ipairs(Window.Connections) do
            if conn then conn:Disconnect() end
        end
        if screenGui then screenGui:Destroy() end
    end

    ------------------------------------------------------------
    -- TAB CREATION WITH DRAG REORDERING
    ------------------------------------------------------------
    function Window:CreateTab(tabName)
        Window.TabCount = Window.TabCount + 1
        local currentOrder = Window.TabCount

        local tabContainer = create("ScrollingFrame", {
            Name = tabName .. "_Container",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = NexusUI.Theme.Accent,
            Parent = contentArea,
        }, {
            create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
            create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
        })

        local tabButton = create("TextButton", {
            Name = tabName .. "_TabBtn",
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = NexusUI.Theme.Container,
            BackgroundTransparency = 1,
            Text = tabName,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = NexusUI.Theme.TextSecondary,
            BorderSizePixel = 0,
            LayoutOrder = currentOrder,
            AutoButtonColor = false,
            Parent = sidebar,
        })

        local Tab = { Container = tabContainer, Button = tabButton, LayoutOrder = currentOrder }

        -- Direct Button on Tab (without needing a Section)
        function Tab:AddButton(text, callback)
            local btn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = NexusUI.Theme.Container,
                BorderSizePixel = 0,
                Text = text,
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                TextColor3 = NexusUI.Theme.TextPrimary,
                AutoButtonColor = false,
                Parent = tabContainer,
            })

            btn.MouseButton1Click:Connect(function()
                animate(btn, TweenInfo.new(0.08), { BackgroundColor3 = NexusUI.Theme.Accent })
                task.wait(0.08)
                animate(btn, TweenInfo.new(0.1), { BackgroundColor3 = NexusUI.Theme.Container })
                if callback then callback() end
            end)

            return btn
        end

        -- Direct Textbox on Tab
        function Tab:AddTextbox(text, placeholder, callback)
            local boxFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = NexusUI.Theme.Container,
                BorderSizePixel = 0,
                Parent = tabContainer,
            })

            create("TextLabel", {
                Size = UDim2.new(0.5, -8, 1, 0),
                Position = UDim2.fromOffset(8, 0),
                BackgroundTransparency = 1,
                Text = text,
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                TextColor3 = NexusUI.Theme.TextPrimary,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = boxFrame,
            })

            local textBox = create("TextBox", {
                Size = UDim2.new(0.5, -8, 0, 22),
                Position = UDim2.new(0.5, 0, 0.5, -11),
                BackgroundColor3 = NexusUI.Theme.Element,
                BorderSizePixel = 0,
                Text = "",
                PlaceholderText = placeholder or "Enter text...",
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = NexusUI.Theme.TextPrimary,
                PlaceholderColor3 = NexusUI.Theme.TextSecondary,
                ClearTextOnFocus = false,
                Parent = boxFrame,
            })

            textBox.FocusLost:Connect(function(enterPressed)
                if callback then callback(textBox.Text, enterPressed) end
            end)

            return boxFrame
        end

        -- Select Tab Logic
        local function selectTab()
            for _, t in pairs(Window.Tabs) do
                t.Container.Visible = false
                animate(t.Button, TWEEN_FAST, { 
                    BackgroundTransparency = 1, 
                    TextColor3 = NexusUI.Theme.TextSecondary 
                })
            end
            tabContainer.Visible = true
            animate(tabButton, TWEEN_FAST, { 
                BackgroundTransparency = 0, 
                BackgroundColor3 = NexusUI.Theme.Container, 
                TextColor3 = NexusUI.Theme.TextPrimary 
            })
        end

        tabButton.MouseButton1Click:Connect(selectTab)

        -- Tab Drag-to-Reorder System
        local tabDragging = false
        local dragOffsetY = 0

        tabButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                tabDragging = true
                dragOffsetY = input.Position.Y - tabButton.AbsolutePosition.Y
            end
        end)

        tabButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                tabDragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if tabDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mouseY = input.Position.Y
                for _, otherTab in ipairs(Window.Tabs) do
                    if otherTab ~= Tab then
                        local otherBtn = otherTab.Button
                        local otherMinY = otherBtn.AbsolutePosition.Y
                        local otherMaxY = otherMinY + otherBtn.AbsoluteSize.Y

                        if mouseY >= otherMinY and mouseY <= otherMaxY then
                            -- Swap Layout Orders
                            local tempOrder = tabButton.LayoutOrder
                            tabButton.LayoutOrder = otherBtn.LayoutOrder
                            otherBtn.LayoutOrder = tempOrder
                            break
                        end
                    end
                end
            end
        end)

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then selectTab() end

        ------------------------------------------------------------
        -- SECTION CREATION
        ------------------------------------------------------------
        function Tab:CreateSection(sectionName)
            local sectionFrame = create("Frame", {
                Name = sectionName .. "_Section",
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = NexusUI.Theme.Container,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = tabContainer,
            })

            local sectionHeader = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                Text = "  " .. string.upper(sectionName),
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = NexusUI.Theme.TextPrimary,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                Parent = sectionFrame,
            })

            local elementList = create("Frame", {
                Name = "Elements",
                Size = UDim2.new(1, -12, 1, -32),
                Position = UDim2.fromOffset(6, 30),
                BackgroundTransparency = 1,
                Parent = sectionFrame,
            }, {
                create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
            })

            local isExpanded = true
            local function updateSectionHeight()
                local contentHeight = elementList.UIListLayout.AbsoluteContentSize.Y
                local targetHeight = isExpanded and (contentHeight + 34) or 28
                animate(sectionFrame, TWEEN_FAST, { Size = UDim2.new(1, 0, 0, targetHeight) })
            end

            elementList.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSectionHeight)
            sectionHeader.MouseButton1Click:Connect(function()
                isExpanded = not isExpanded
                updateSectionHeight()
            end)

            local Section = {}

            function Section:AddButton(text, callback)
                local btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = NexusUI.Theme.Element,
                    BorderSizePixel = 0,
                    Text = text,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = NexusUI.Theme.TextPrimary,
                    AutoButtonColor = false,
                    Parent = elementList,
                })

                btn.MouseButton1Click:Connect(function()
                    animate(btn, TweenInfo.new(0.08), { BackgroundColor3 = NexusUI.Theme.Accent })
                    task.wait(0.08)
                    animate(btn, TweenInfo.new(0.1), { BackgroundColor3 = NexusUI.Theme.Element })
                    if callback then callback() end
                end)
            end

            function Section:AddTextbox(text, placeholder, callback)
                local boxFrame = create("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = elementList })
                create("TextLabel", {
                    Size = UDim2.new(0.5, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = NexusUI.Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = boxFrame,
                })

                local textBox = create("TextBox", {
                    Size = UDim2.new(0.5, 0, 0, 22),
                    Position = UDim2.new(0.5, 0, 0.5, -11),
                    BackgroundColor3 = NexusUI.Theme.Element,
                    BorderSizePixel = 0,
                    Text = "",
                    PlaceholderText = placeholder or "Type here...",
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = NexusUI.Theme.TextPrimary,
                    PlaceholderColor3 = NexusUI.Theme.TextSecondary,
                    ClearTextOnFocus = false,
                    Parent = boxFrame,
                })

                textBox.FocusLost:Connect(function(enterPressed)
                    if callback then callback(textBox.Text, enterPressed) end
                end)
            end

            function Section:AddToggle(text, default, callback)
                local state = default or false
                local toggleFrame = create("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = elementList })
                create("TextLabel", {
                    Size = UDim2.new(0.7, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = NexusUI.Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = toggleFrame,
                })

                local switch = create("TextButton", {
                    Size = UDim2.fromOffset(14, 14),
                    Position = UDim2.new(1, -18, 0.5, -7),
                    BackgroundColor3 = state and NexusUI.Theme.Accent or NexusUI.Theme.Element,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = toggleFrame,
                })

                switch.MouseButton1Click:Connect(function()
                    state = not state
                    animate(switch, TWEEN_FAST, { BackgroundColor3 = state and NexusUI.Theme.Accent or NexusUI.Theme.Element })
                    if callback then callback(state) end
                end)
            end

            function Section:AddSlider(text, min, max, default, callback)
                min, max = min or 0, max or 100
                default = math.clamp(default or min, min, max)
                local sliderFrame = create("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = elementList })
                local label = create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Text = text .. " : " .. tostring(default),
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = NexusUI.Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = sliderFrame,
                })

                local track = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.fromOffset(0, 22),
                    BackgroundColor3 = NexusUI.Theme.Element,
                    BorderSizePixel = 0,
                    Parent = sliderFrame,
                })

                local fill = create("Frame", {
                    Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = NexusUI.Theme.Accent,
                    BorderSizePixel = 0,
                    Parent = track,
                })

                local sliding = false
                local function updateSlider(input)
                    local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    local value = math.floor(min + (max - min) * percent)
                    fill.Size = UDim2.new(percent, 0, 1, 0)
                    label.Text = text .. " : " .. tostring(value)
                    if callback then callback(value) end
                end

                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        updateSlider(input)
                    end
                end)
                track.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateSlider(input)
                    end
                end)
            end

            function Section:AddKeybind(text, defaultKey, callback)
                local currentKey = defaultKey or Enum.KeyCode.RightControl
                local binding = false

                local keybindFrame = create("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = elementList })
                create("TextLabel", {
                    Size = UDim2.new(0.6, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = NexusUI.Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = keybindFrame,
                })

                local keyBtn = create("TextButton", {
                    Size = UDim2.new(0.4, 0, 0, 22),
                    Position = UDim2.new(0.6, 0, 0.5, -11),
                    BackgroundColor3 = NexusUI.Theme.Element,
                    BorderSizePixel = 0,
                    Text = currentKey.Name,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 10,
                    TextColor3 = NexusUI.Theme.TextSecondary,
                    AutoButtonColor = false,
                    Parent = keybindFrame,
                })

                keyBtn.MouseButton1Click:Connect(function()
                    binding = true
                    keyBtn.Text = "..."
                    keyBtn.TextColor3 = NexusUI.Theme.Accent
                end)

                local keyConnection = UserInputService.InputBegan:Connect(function(input, gpe)
                    if binding and not gpe then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            currentKey = input.KeyCode
                            keyBtn.Text = currentKey.Name
                            keyBtn.TextColor3 = NexusUI.Theme.TextSecondary
                            binding = false
                            if callback then callback(currentKey) end
                        end
                    end
                end)
                table.insert(Window.Connections, keyConnection)
            end

            return Section
        end

        return Tab
    end

    -- Automatically Generate Default "Main" and "Settings" Tabs
    local mainTab = Window:CreateTab("Main")
    local settingsTab = Window:CreateTab("Settings")

    local settingsSection = settingsTab:CreateSection("Menu Control")
    settingsSection:AddKeybind("Toggle Menu Key", Enum.KeyCode.RightControl, function(newKey)
        Window.ToggleKey = newKey
    end)
    settingsSection:AddButton("Unload UI", function()
        Window:Unload()
    end)

    Window.MainTab = mainTab
    Window.SettingsTab = settingsTab

    return Window
end

return NexusUI
