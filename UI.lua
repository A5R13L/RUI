local Library = {
    Signals = {},
    Toggle = true,
    FirstTab = nil,
    TabCount = 0,
    ColorTable = {}
}

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")

function Library:Create(Class, Options)
    if type(Class) == "string" then
        Class = Instance.new(Class)
    end

    for Property, Value in pairs(Options) do
        Class[Property] = Value
    end

    return Class
end

function Library:AddSignal(Signal)
    self.Signals[#self.Signals + 1] = Signal
end

function Library:Unload()
    for _, Signal in ipairs(self.Signals) do
        Signal:Disconnect()
    end

    self.Signals = {}

    if self.OnUnload then
        self:OnUnload()
    end
end

local function MakeDraggable(ClickObject, Object)
    local Dragging = nil
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    Library:AddSignal(ClickObject.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = Input.Position
            StartPosition = Object.Position

            Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end))

    Library:AddSignal(ClickObject.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
            DragInput = Input
        end
    end))

    Library:AddSignal(UserInputService.InputChanged:Connect(function(Input)
        if Input == DragInput and Dragging then
            local Delta = Input.Position - DragStart
            Object.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
        end
    end))
end

Library.NotificationDock = Library:Create("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 20, 0, 20),
    Size = UDim2.new(0, 300, 0, 200),
    ZIndex = 100
})

if syn and syn.protect_gui then
    syn.protect_gui(Library.NotificationDock)
end

Library.NotificationDock.Parent = CoreGui

Library:Create("UIListLayout", {
    Padding = UDim.new(0, 4),
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = Library.NotificationDock
})

function Library:TextSize(Text, Font, Size)
    return TextService:GetTextSize(Text, Size, Font, Vector2.new(1920, 1080))
end

function Library:Notify(Text, Time)
    local Size = self:TextSize(Text, Enum.Font.Code, 14)

    local Outer = self:Create("Frame", {
        BorderColor3 = Color3.new(0, 0, 0),
        Position = UDim2.new(0, 100, 0, 10),
        Size = UDim2.new(0, 0, 0, 20),
        ClipsDescendants = true,
        ZIndex = 100,
        Parent = self.NotificationDock
    })

    local Inner = self:Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        BorderColor3 = Color3.new(0, 0, 0),
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 101,
        Parent = Outer
    })

    local Frame = self:Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 102,
        Parent = Inner
    })

    self:Create("UIGradient", {
        Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(27, 27, 27)), ColorSequenceKeypoint.new(1, Color3.fromRGB(52, 52, 52))}),
        Rotation = -90,
        Parent = Frame
    })

    local Label = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextColor3 = Color3.new(0.8, 0.8, 0.8),
        TextSize = 16,
        TextStrokeTransparency = 0
    })

    local LeftColor = self:Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(0, 150, 255),
        BorderSizePixel = 0,
        Position = UDim2.new(0, -1, 0, -1),
        Size = UDim2.new(0, 3, 1, 2),
        ZIndex = 104,
        Parent = Outer
    })

    Outer:TweenSize(UDim2.new(0, Size.x + 8 + 4, 0, 20), "Out", "Quad", 0.4, true)

    task.spawn(function()
        wait(Time or 5)
        Outer:TweenSize(UDim2.new(0, 0, 0, 20), "Out", "Quad", 0.4, true)
        wait(0.4)
        Outer:Destroy()
    end)
end

function Library:CreateWindow(Config)
    local WindowInit = {}
    local Folder = game:GetObjects("rbxassetid://7141683860")[1]
    local Screen = Folder.Bracket:Clone()
    local Main = Screen.Main
    local Holder = Main.Holder
    local Topbar = Main.Topbar
    local TContainer = Holder.TContainer
    local TBContainer = Holder.TBContainer.Holder

    if syn and syn.protect_gui then
        syn.protect_gui(Screen)
    end

    Screen.Name = HttpService:GenerateGUID(false)
    Screen.Parent = CoreGui
    Topbar.WindowName.Text = Config.WindowName
    MakeDraggable(Topbar, Main)

    local function CloseAll()
        for _, Tab in pairs(TContainer:GetChildren()) do
            if Tab:IsA("ScrollingFrame") then
                Tab.Visible = false
            end
        end
    end

    local function ResetAll()
        for _, TabButton in pairs(TBContainer:GetChildren()) do
            if TabButton:IsA("TextButton") then
                TabButton.BackgroundTransparency = 1
            end
        end

        for _, TabButton in pairs(TBContainer:GetChildren()) do
            if TabButton:IsA("TextButton") then
                TabButton.Size = UDim2.new(0, 480 / Library.TabCount, 1, 0)
            end
        end

        for _, Pallete in pairs(Screen:GetChildren()) do
            if Pallete:IsA("Frame") and Pallete.Name ~= "Main" then
                Pallete.Visible = false
            end
        end
    end

    local function KeepFirst()
        for _, Tab in pairs(TContainer:GetChildren()) do
            if Tab:IsA("ScrollingFrame") then
                if Tab.Name == Library.FirstTab .. " T" then
                    Tab.Visible = true
                else
                    Tab.Visible = false
                end
            end
        end

        for _, TabButton in pairs(TBContainer:GetChildren()) do
            if TabButton:IsA("TextButton") then
                if TabButton.Name == Library.FirstTab .. " TB" then
                    TabButton.BackgroundTransparency = 0
                else
                    TabButton.BackgroundTransparency = 1
                end
            end
        end
    end

    local function Toggle(State)
        if State then
            Main.Visible = true
        elseif not State then
            for _, Pallete in pairs(Screen:GetChildren()) do
                if Pallete:IsA("Frame") and Pallete.Name ~= "Main" then
                    Pallete.Visible = false
                end
            end

            Screen.ToolTip.Visible = false
            Main.Visible = false
        end

        Library.Toggle = State
    end

    local function ChangeColor(Color)
        Config.Color = Color

        for i, v in pairs(Library.ColorTable) do
            if v.BackgroundColor3 ~= Color3.fromRGB(50, 50, 50) then
                v.BackgroundColor3 = Color
            end
        end
    end

    function WindowInit:Toggle(State)
        Toggle(State)
    end

    function WindowInit:ChangeColor(Color)
        ChangeColor(Color)
    end

    function WindowInit:SetBackground(ImageId)
        Holder.Image = "rbxassetid://" .. ImageId
    end

    function WindowInit:SetBackgroundColor(Color)
        Holder.ImageColor3 = Color
    end

    function WindowInit:SetBackgroundTransparency(Transparency)
        Holder.ImageTransparency = Transparency
    end

    function WindowInit:SetTileOffset(Offset)
        Holder.TileSize = UDim2.new(0, Offset, 0, Offset)
    end

    function WindowInit:SetTileScale(Scale)
        Holder.TileSize = UDim2.new(Scale, 0, Scale, 0)
    end

    Library:AddSignal(RunService.RenderStepped:Connect(function()
        if Library.Toggle then
            Screen.ToolTip.Position = UDim2.new(0, UserInputService:GetMouseLocation().X + 10, 0, UserInputService:GetMouseLocation().Y - 5)
        end
    end))

    Library:AddSignal(UserInputService.InputBegan:Connect(function(Input, Processed)
        if Input.KeyCode == Enum.KeyCode.RightControl and not Processed then
            WindowInit:Toggle(not Main.Visible)
        end
    end))

    function WindowInit:CreateTab(Name)
        local TabInit = {}
        local Tab = Folder.Tab:Clone()
        local TabButton = Folder.TabButton:Clone()
        Tab.Name = Name .. " T"
        Tab.Parent = TContainer
        TabButton.Name = Name .. " TB"
        TabButton.Parent = TBContainer
        TabButton.Title.Text = Name
        TabButton.BackgroundColor3 = Config.Color
        table.insert(Library.ColorTable, TabButton)
        Library.TabCount = Library.TabCount + 1

        if Library.TabCount == 1 then
            Library.FirstTab = Name
        end

        CloseAll()
        ResetAll()
        KeepFirst()

        local function GetSide(Longest)
            if Longest then
                if Tab.LeftSide.ListLayout.AbsoluteContentSize.Y > Tab.RightSide.ListLayout.AbsoluteContentSize.Y then
                    return Tab.LeftSide
                else
                    return Tab.RightSide
                end
            else
                if Tab.LeftSide.ListLayout.AbsoluteContentSize.Y > Tab.RightSide.ListLayout.AbsoluteContentSize.Y then
                    return Tab.RightSide
                else
                    return Tab.LeftSide
                end
            end
        end

        TabButton.MouseButton1Click:Connect(function()
            CloseAll()
            ResetAll()
            Tab.Visible = true
            TabButton.BackgroundTransparency = 0
        end)

        Tab.LeftSide.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if GetSide(true).Name == Tab.LeftSide.Name then
                Tab.CanvasSize = UDim2.new(0, 0, 0, Tab.LeftSide.ListLayout.AbsoluteContentSize.Y + 15)
            else
                Tab.CanvasSize = UDim2.new(0, 0, 0, Tab.RightSide.ListLayout.AbsoluteContentSize.Y + 15)
            end
        end)

        Tab.RightSide.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if GetSide(true).Name == Tab.LeftSide.Name then
                Tab.CanvasSize = UDim2.new(0, 0, 0, Tab.LeftSide.ListLayout.AbsoluteContentSize.Y + 15)
            else
                Tab.CanvasSize = UDim2.new(0, 0, 0, Tab.RightSide.ListLayout.AbsoluteContentSize.Y + 15)
            end
        end)

        function TabInit:CreateSection(Name)
            local SectionInit = {}
            local Section = Folder.Section:Clone()
            Section.Name = Name .. " S"
            Section.Parent = GetSide(false)
            Section.Title.Text = Name
            Section.Title.Size = UDim2.new(0, Section.Title.TextBounds.X + 10, 0, 2)

            Section.Container.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Section.Size = UDim2.new(1, 0, 0, Section.Container.ListLayout.AbsoluteContentSize.Y + 15)
            end)

            function SectionInit:CreateLabel(Name)
                local LabelInit = {}
                local Label = Folder.Label:Clone()
                Label.Name = Name .. " L"
                Label.Parent = Section.Container
                Label.Text = Name
                Label.Size = UDim2.new(1, -10, 0, Label.TextBounds.Y)

                function LabelInit:UpdateText(Text)
                    Label.Text = Text
                    Label.Size = UDim2.new(1, -10, 0, Label.TextBounds.Y)
                end

                return LabelInit
            end

            function SectionInit:CreateButton(Name, Callback)
                local ButtonInit = {}
                local Button = Folder.Button:Clone()
                Button.Name = Name .. " B"
                Button.Parent = Section.Container
                Button.Title.Text = Name
                Button.Size = UDim2.new(1, -10, 0, Button.Title.TextBounds.Y + 5)
                table.insert(Library.ColorTable, Button)

                Button.MouseButton1Down:Connect(function()
                    Button.BackgroundColor3 = Config.Color
                end)

                Button.MouseButton1Up:Connect(function()
                    Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                end)

                Button.MouseLeave:Connect(function()
                    Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                end)

                Button.MouseButton1Click:Connect(function()
                    Callback()
                end)

                function ButtonInit:AddToolTip(Name)
                    if tostring(Name):gsub(" ", "") ~= "" then
                        Button.MouseEnter:Connect(function()
                            Screen.ToolTip.Text = Name
                            Screen.ToolTip.Size = UDim2.new(0, Screen.ToolTip.TextBounds.X + 5, 0, Screen.ToolTip.TextBounds.Y + 5)
                            Screen.ToolTip.Visible = true
                        end)

                        Button.MouseLeave:Connect(function()
                            Screen.ToolTip.Visible = false
                        end)
                    end
                end

                return ButtonInit
            end

            function SectionInit:CreateTextBox(Name, PlaceHolder, NumbersOnly, Callback)
                local TextBoxInit = {}
                local TextBox = Folder.TextBox:Clone()
                TextBox.Name = Name .. " T"
                TextBox.Parent = Section.Container
                TextBox.Title.Text = Name
                TextBox.Background.Input.PlaceholderText = PlaceHolder
                TextBox.Title.Size = UDim2.new(1, 0, 0, TextBox.Title.TextBounds.Y + 5)
                TextBox.Size = UDim2.new(1, -10, 0, TextBox.Title.TextBounds.Y + 25)

                TextBox.Background.Input.FocusLost:Connect(function()
                    if NumbersOnly and tonumber(TextBox.Background.Input.Text) ~= nil then
                        Callback(tonumber(TextBox.Background.Input.Text))
                        TextBox.Background.Input.Text = ""
                    elseif not NumbersOnly then
                        Callback(TextBox.Background.Input.Text)
                        TextBox.Background.Input.Text = ""
                    end
                end)

                function TextBoxInit:SetValue(String)
                    Callback(String)
                    TextBox.Background.Input.Text = String
                end

                function TextBoxInit:AddToolTip(Name)
                    if tostring(Name):gsub(" ", "") ~= "" then
                        TextBox.MouseEnter:Connect(function()
                            Screen.ToolTip.Text = Name
                            Screen.ToolTip.Size = UDim2.new(0, Screen.ToolTip.TextBounds.X + 5, 0, Screen.ToolTip.TextBounds.Y + 5)
                            Screen.ToolTip.Visible = true
                        end)

                        TextBox.MouseLeave:Connect(function()
                            Screen.ToolTip.Visible = false
                        end)
                    end
                end

                return TextBoxInit
            end

            function SectionInit:CreateToggle(Name, Default, Callback)
                local DefaultLocal = Default or false
                local ToggleInit = {}
                local Toggle = Folder.Toggle:Clone()
                Toggle.Name = Name .. " T"
                Toggle.Parent = Section.Container
                Toggle.Title.Text = Name
                Toggle.Size = UDim2.new(1, -10, 0, Toggle.Title.TextBounds.Y + 5)
                table.insert(Library.ColorTable, Toggle.Toggle)
                local ToggleState = false

                local function SetState(State)
                    if State then
                        Toggle.Toggle.BackgroundColor3 = Config.Color
                    elseif not State then
                        Toggle.Toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    end

                    ToggleState = State
                    Callback(State)
                end

                Toggle.MouseButton1Click:Connect(function()
                    ToggleState = not ToggleState
                    SetState(ToggleState)
                end)

                function ToggleInit:AddToolTip(Name)
                    if tostring(Name):gsub(" ", "") ~= "" then
                        Toggle.MouseEnter:Connect(function()
                            Screen.ToolTip.Text = Name
                            Screen.ToolTip.Size = UDim2.new(0, Screen.ToolTip.TextBounds.X + 5, 0, Screen.ToolTip.TextBounds.Y + 5)
                            Screen.ToolTip.Visible = true
                        end)

                        Toggle.MouseLeave:Connect(function()
                            Screen.ToolTip.Visible = false
                        end)
                    end
                end

                if Default == nil then
                    function ToggleInit:SetState(State)
                        SetState(State)
                    end
                else
                    SetState(DefaultLocal)
                end

                function ToggleInit:GetState(State)
                    return ToggleState
                end

                function ToggleInit:CreateKeybind(Bind, Callback, IgnoreState)
                    local KeybindInit = {}
                    Bind = Bind or "NONE"
                    local WaitingForBind = false
                    local Selected = Bind

                    local Blacklist = {"W", "A", "S", "D", "Slash", "Tab", "Backspace", "Escape", "Space", "Delete", "Unknown", "Backquote"}

                    Toggle.Keybind.Visible = true
                    Toggle.Keybind.Text = "[ " .. Bind .. " ]"

                    Toggle.Keybind.MouseButton1Click:Connect(function()
                        Toggle.Keybind.Text = "[ ... ]"
                        WaitingForBind = true
                    end)

                    Toggle.Keybind:GetPropertyChangedSignal("TextBounds"):Connect(function()
                        Toggle.Keybind.Size = UDim2.new(0, Toggle.Keybind.TextBounds.X, 1, 0)
                        Toggle.Title.Size = UDim2.new(1, -Toggle.Keybind.Size.X.Offset - 15, 1, 0)
                    end)

                    Library:AddSignal(UserInputService.InputBegan:Connect(function(Input)
                        if WaitingForBind and Input.UserInputType == Enum.UserInputType.Keyboard then
                            local Key = tostring(Input.KeyCode):gsub("Enum.KeyCode.", "")

                            if not table.find(Blacklist, Key) then
                                Toggle.Keybind.Text = "[ " .. Key .. " ]"
                                Selected = Key
                            else
                                Toggle.Keybind.Text = "[ NONE ]"
                                Selected = "NONE"
                            end

                            WaitingForBind = false
                        elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                            local Key = tostring(Input.KeyCode):gsub("Enum.KeyCode.", "")

                            if Key == Selected then
                                if not IgnoreState then
                                    ToggleState = not ToggleState
                                    SetState(ToggleState)
                                end

                                if Callback then
                                    Callback(Key, true)
                                end
                            end
                        end
                    end))

                    Library:AddSignal(UserInputService.InputEnded:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.Keyboard then
                            local Key = tostring(Input.KeyCode):gsub("Enum.KeyCode.", "")

                            if Key == Selected then
                                if Callback then
                                    Callback(Key, false)
                                end
                            end
                        end
                    end))

                    function KeybindInit:SetBind(Key)
                        Toggle.Keybind.Text = "[ " .. Key .. " ]"
                        Selected = Key
                    end

                    function KeybindInit:GetBind()
                        return Selected
                    end

                    return KeybindInit
                end

                return ToggleInit
            end

            function SectionInit:CreateSlider(Name, Min, Max, Default, Precise, Callback, OddOnly)
                local DefaultLocal = Default or 50
                local SliderInit = {}
                local Slider = Folder.Slider:Clone()
                Slider.Name = Name .. " S"
                Slider.Parent = Section.Container
                Slider.Title.Text = Name
                Slider.Slider.Bar.Size = UDim2.new(Min / Max, 0, 1, 0)
                Slider.Slider.Bar.BackgroundColor3 = Config.Color
                Slider.Value.PlaceholderText = tostring(Min / Max)
                Slider.Title.Size = UDim2.new(1, 0, 0, Slider.Title.TextBounds.Y + 5)
                Slider.Size = UDim2.new(1, -10, 0, Slider.Title.TextBounds.Y + 15)
                table.insert(Library.ColorTable, Slider.Slider.Bar)
                local GlobalSliderValue = 0
                local Dragging = false

                local function Sliding(Input)
                    local Position = UDim2.new(math.clamp((Input.Position.X - Slider.Slider.AbsolutePosition.X) / Slider.Slider.AbsoluteSize.X, 0, 1), 0, 1, 0)
                    Slider.Slider.Bar.Size = Position
                    local SliderPrecise = ((Position.X.Scale * Max) / Max) * (Max - Min) + Min
                    local SliderNonPrecise = math.floor(((Position.X.Scale * Max) / Max) * (Max - Min) + Min)
                    local SliderValue = Precise and SliderNonPrecise or SliderPrecise

                    if OddOnly and SliderValue % 2 == 0 then
                        SliderValue = SliderValue + 1

                        if SliderValue > Max then
                            SliderValue = SliderValue - 1
                        end
                    end

                    SliderValue = tonumber(string.format("%.2f", SliderValue))
                    GlobalSliderValue = SliderValue
                    Slider.Value.PlaceholderText = tostring(SliderValue)
                    Callback(GlobalSliderValue)
                end

                local function SetValue(Value)
                    GlobalSliderValue = Value
                    Slider.Slider.Bar.Size = UDim2.new(Value / Max, 0, 1, 0)
                    Slider.Value.PlaceholderText = Value
                    Callback(Value)
                end

                Slider.Value.FocusLost:Connect(function()
                    if not tonumber(Slider.Value.Text) then
                        Slider.Value.Text = GlobalSliderValue
                    elseif Slider.Value.Text == "" or tonumber(Slider.Value.Text) <= Min then
                        Slider.Value.Text = Min
                    elseif Slider.Value.Text == "" or tonumber(Slider.Value.Text) >= Max then
                        Slider.Value.Text = Max
                    end

                    GlobalSliderValue = Slider.Value.Text
                    Slider.Slider.Bar.Size = UDim2.new(Slider.Value.Text / Max, 0, 1, 0)
                    Slider.Value.PlaceholderText = Slider.Value.Text
                    Callback(tonumber(Slider.Value.Text))
                    Slider.Value.Text = ""
                end)

                Slider.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Sliding(Input)
                        Dragging = true
                    end
                end)

                Slider.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Dragging = false
                    end
                end)

                Library:AddSignal(UserInputService.InputBegan:Connect(function(Input)
                    if Input.KeyCode == Enum.KeyCode.LeftControl then
                        Slider.Value.ZIndex = 4
                    end
                end))

                Library:AddSignal(UserInputService.InputEnded:Connect(function(Input)
                    if Input.KeyCode == Enum.KeyCode.LeftControl then
                        Slider.Value.ZIndex = 3
                    end
                end))

                Library:AddSignal(UserInputService.InputChanged:Connect(function(Input)
                    if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                        Sliding(Input)
                    end
                end))

                function SliderInit:AddToolTip(Name)
                    if tostring(Name):gsub(" ", "") ~= "" then
                        Slider.MouseEnter:Connect(function()
                            Screen.ToolTip.Text = Name
                            Screen.ToolTip.Size = UDim2.new(0, Screen.ToolTip.TextBounds.X + 5, 0, Screen.ToolTip.TextBounds.Y + 5)
                            Screen.ToolTip.Visible = true
                        end)

                        Slider.MouseLeave:Connect(function()
                            Screen.ToolTip.Visible = false
                        end)
                    end
                end

                if Default == nil then
                    function SliderInit:SetValue(Value)
                        GlobalSliderValue = Value
                        Slider.Slider.Bar.Size = UDim2.new(Value / Max, 0, 1, 0)
                        Slider.Value.PlaceholderText = Value
                        Callback(Value)
                    end
                else
                    SetValue(DefaultLocal)
                end

                function SliderInit:GetValue(Value)
                    return GlobalSliderValue
                end

                return SliderInit
            end

            function SectionInit:CreateDropdown(Name, OptionTable, Callback, InitialValue)
                local DropdownInit = {}
                local Dropdown = Folder.Dropdown:Clone()
                Dropdown.Name = Name .. " D"
                Dropdown.Parent = Section.Container
                Dropdown.Title.Text = Name
                Dropdown.Title.Size = UDim2.new(1, 0, 0, Dropdown.Title.TextBounds.Y + 5)
                Dropdown.Container.Position = UDim2.new(0, 0, 0, Dropdown.Title.TextBounds.Y + 5)
                Dropdown.Size = UDim2.new(1, -10, 0, Dropdown.Title.TextBounds.Y + 25)
                DropdownInit.__Dropdown = Dropdown
                local DropdownToggle = false

                Dropdown.MouseButton1Click:Connect(function()
                    DropdownToggle = not DropdownToggle

                    if DropdownToggle then
                        Dropdown.Size = UDim2.new(1, -10, 0, Dropdown.Container.Holder.Container.ListLayout.AbsoluteContentSize.Y + Dropdown.Title.TextBounds.Y + 30)
                        Dropdown.Container.Holder.Visible = true
                    else
                        Dropdown.Size = UDim2.new(1, -10, 0, Dropdown.Title.TextBounds.Y + 25)
                        Dropdown.Container.Holder.Visible = false
                    end
                end)

                function DropdownInit:AddToolTip(Name)
                    if tostring(Name):gsub(" ", "") ~= "" then
                        Dropdown.MouseEnter:Connect(function()
                            Screen.ToolTip.Text = Name
                            Screen.ToolTip.Size = UDim2.new(0, Screen.ToolTip.TextBounds.X + 5, 0, Screen.ToolTip.TextBounds.Y + 5)
                            Screen.ToolTip.Visible = true
                        end)

                        Dropdown.MouseLeave:Connect(function()
                            Screen.ToolTip.Visible = false
                        end)
                    end
                end

                function DropdownInit:GetOption()
                    return Dropdown.Container.Value.Text
                end

                function DropdownInit:SetOption(Name, UseCallback)
                    Dropdown.Container.Value.Text = Name
                    if not UseCallback then return end
                    Callback(Name)
                end

                function DropdownInit:SetOptions(Options)
                    if not Options then
                        Options = OptionTable
                    end

                    if type(Options) == "function" then
                        Options = Options()
                    end

                    for _, Option in pairs(Dropdown.Container.Holder.Container:GetChildren()) do
                        if Option:IsA("TextButton") then
                            Option:Destroy()
                        end
                    end

                    for _, OptionName in pairs(Options) do
                        local Option = Folder.Option:Clone()
                        Option.Name = OptionName
                        Option.Parent = Dropdown.Container.Holder.Container
                        Option.Title.Text = OptionName
                        Option.BackgroundColor3 = Config.Color
                        Option.Size = UDim2.new(1, 0, 0, Option.Title.TextBounds.Y + 5)
                        Dropdown.Container.Holder.Size = UDim2.new(1, -5, 0, Dropdown.Container.Holder.Container.ListLayout.AbsoluteContentSize.Y)
                        table.insert(Library.ColorTable, Option)

                        Option.MouseButton1Down:Connect(function()
                            Option.BackgroundTransparency = 0
                        end)

                        Option.MouseButton1Up:Connect(function()
                            Option.BackgroundTransparency = 1
                        end)

                        Option.MouseLeave:Connect(function()
                            Option.BackgroundTransparency = 1
                        end)

                        Option.MouseButton1Click:Connect(function()
                            Dropdown.Container.Value.Text = OptionName
                            Callback(OptionName)
                            DropdownToggle = false
                            Dropdown.Size = UDim2.new(1, -10, 0, Dropdown.Title.TextBounds.Y + 25)
                            Dropdown.Container.Holder.Visible = false
                        end)
                    end
                end

                DropdownInit:SetOptions(OptionTable)

                function DropdownInit:RemoveOption(Name)
                    for _, Option in pairs(Dropdown.Container.Holder.Container:GetChildren()) do
                        if Option:IsA("TextButton") and string.find(Option.Name, Name) then
                            Option:Destroy()
                        end
                    end

                    Dropdown.Container.Holder.Size = UDim2.new(1, -5, 0, Dropdown.Container.Holder.Container.ListLayout.AbsoluteContentSize.Y)
                    Dropdown.Size = UDim2.new(1, -10, 0, Dropdown.Container.Holder.Container.ListLayout.AbsoluteContentSize.Y + Dropdown.Title.TextBounds.Y + 30)
                end

                function DropdownInit:ClearOptions()
                    for _, Option in pairs(Dropdown.Container.Holder.Container:GetChildren()) do
                        if Option:IsA("TextButton") then
                            Option:Destroy()
                        end
                    end

                    Dropdown.Container.Holder.Size = UDim2.new(1, -5, 0, Dropdown.Container.Holder.Container.ListLayout.AbsoluteContentSize.Y)
                    Dropdown.Size = UDim2.new(1, -10, 0, Dropdown.Container.Holder.Container.ListLayout.AbsoluteContentSize.Y + Dropdown.Title.TextBounds.Y + 30)
                end

                if InitialValue then
                    DropdownInit:SetOption(InitialValue, false)
                end

                return DropdownInit
            end

            function SectionInit:CreateColorpicker(Name, Callback)
                local ColorpickerInit = {}
                local Colorpicker = Folder.Colorpicker:Clone()
                local Pallete = Folder.Pallete:Clone()
                Colorpicker.Name = Name .. " CP"
                Colorpicker.Parent = Section.Container
                Colorpicker.Title.Text = Name
                Colorpicker.Size = UDim2.new(1, -10, 0, Colorpicker.Title.TextBounds.Y + 5)
                Pallete.Name = Name .. " P"
                Pallete.Parent = Screen

                local ColorTable = {
                    Hue = 1,
                    Saturation = 0,
                    Value = 0
                }

                local ColorRender = nil
                local HueRender = nil
                local ColorpickerRender = nil

                local function UpdateColor()
                    Colorpicker.Color.BackgroundColor3 = Color3.fromHSV(ColorTable.Hue, ColorTable.Saturation, ColorTable.Value)
                    Pallete.GradientPallete.BackgroundColor3 = Color3.fromHSV(ColorTable.Hue, 1, 1)
                    Pallete.Input.InputBox.PlaceholderText = "RGB: " .. math.round(Colorpicker.Color.BackgroundColor3.R * 255) .. "," .. math.round(Colorpicker.Color.BackgroundColor3.G * 255) .. "," .. math.round(Colorpicker.Color.BackgroundColor3.B * 255)
                    Callback(Colorpicker.Color.BackgroundColor3)
                end

                Colorpicker.MouseButton1Click:Connect(function()
                    if not Pallete.Visible then
                        ColorpickerRender = RunService.RenderStepped:Connect(function()
                            Pallete.Position = UDim2.new(0, Colorpicker.Color.AbsolutePosition.X - 129, 0, Colorpicker.Color.AbsolutePosition.Y + 52)
                        end)

                        Pallete.Visible = true
                    else
                        Pallete.Visible = false
                        ColorpickerRender:Disconnect()
                    end
                end)

                Pallete.GradientPallete.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if ColorRender then
                            ColorRender:Disconnect()
                        end

                        ColorRender = RunService.RenderStepped:Connect(function()
                            local Mouse = UserInputService:GetMouseLocation()
                            local ColorX = math.clamp(Mouse.X - Pallete.GradientPallete.AbsolutePosition.X, 0, Pallete.GradientPallete.AbsoluteSize.X) / Pallete.GradientPallete.AbsoluteSize.X
                            local ColorY = math.clamp((Mouse.Y - 37) - Pallete.GradientPallete.AbsolutePosition.Y, 0, Pallete.GradientPallete.AbsoluteSize.Y) / Pallete.GradientPallete.AbsoluteSize.Y
                            Pallete.GradientPallete.Dot.Position = UDim2.new(ColorX, 0, ColorY, 0)
                            ColorTable.Saturation = ColorX
                            ColorTable.Value = 1 - ColorY
                            UpdateColor()
                        end)
                    end
                end)

                Pallete.GradientPallete.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if ColorRender then
                            ColorRender:Disconnect()
                        end
                    end
                end)

                Pallete.ColorSlider.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if HueRender then
                            HueRender:Disconnect()
                        end

                        HueRender = RunService.RenderStepped:Connect(function()
                            local Mouse = UserInputService:GetMouseLocation()
                            local HueX = math.clamp(Mouse.X - Pallete.ColorSlider.AbsolutePosition.X, 0, Pallete.ColorSlider.AbsoluteSize.X) / Pallete.ColorSlider.AbsoluteSize.X
                            ColorTable.Hue = 1 - HueX
                            UpdateColor()
                        end)
                    end
                end)

                Pallete.ColorSlider.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if HueRender then
                            HueRender:Disconnect()
                        end
                    end
                end)

                function ColorpickerInit:UpdateColor(Color)
                    local Hue, Saturation, Value = Color:ToHSV()
                    Colorpicker.Color.BackgroundColor3 = Color3.fromHSV(Hue, Saturation, Value)
                    Pallete.GradientPallete.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
                    Pallete.Input.InputBox.PlaceholderText = "RGB: " .. math.round(Colorpicker.Color.BackgroundColor3.R * 255) .. "," .. math.round(Colorpicker.Color.BackgroundColor3.G * 255) .. "," .. math.round(Colorpicker.Color.BackgroundColor3.B * 255)

                    ColorTable = {
                        Hue = Hue,
                        Saturation = Saturation,
                        Value = Value
                    }

                    Callback(Color)
                end

                Pallete.Input.InputBox.FocusLost:Connect(function(Enter)
                    if Enter then
                        local ColorString = string.split(string.gsub(Pallete.Input.InputBox.Text, " ", ""), ",")
                        ColorpickerInit:UpdateColor(Color3.fromRGB(ColorString[1], ColorString[2], ColorString[3]))
                        Pallete.Input.InputBox.Text = ""
                    end
                end)

                function ColorpickerInit:AddToolTip(Name)
                    if tostring(Name):gsub(" ", "") ~= "" then
                        Colorpicker.MouseEnter:Connect(function()
                            Screen.ToolTip.Text = Name
                            Screen.ToolTip.Size = UDim2.new(0, Screen.ToolTip.TextBounds.X + 5, 0, Screen.ToolTip.TextBounds.Y + 5)
                            Screen.ToolTip.Visible = true
                        end)

                        Colorpicker.MouseLeave:Connect(function()
                            Screen.ToolTip.Visible = false
                        end)
                    end
                end

                return ColorpickerInit
            end

            return SectionInit
        end

        return TabInit
    end

    return WindowInit
end

return Library
