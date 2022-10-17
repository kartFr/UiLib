local UiLibrary = {}
UiLibrary.__index = UiLibrary

local ContextActionService = game:GetService('ContextActionService')
local UserInputService = game:GetService('UserInputService')

local binds = {}
local secondaryBinds = {
    [Enum.KeyCode.LeftControl.Name] = 'LCtrl',
    [Enum.KeyCode.LeftAlt.Name] = 'LAlt',
    [Enum.KeyCode.RightAlt.Name] = 'RAlt',
    [Enum.KeyCode.Tab.Name] = 'Tab'
}
local bindBlacklist = {
    Enum.KeyCode.Slash.Name,
    Enum.KeyCode.W.Name,
    Enum.KeyCode.A.Name,
    Enum.KeyCode.S.Name,
    Enum.KeyCode.D.Name,
    Enum.KeyCode.LeftShift.Name,
    Enum.KeyCode.RightShift.Name,
    Enum.KeyCode.Backspace.Name,
    Enum.KeyCode.Space.Name,
    Enum.KeyCode.Unknown.Name,
    Enum.KeyCode.Backquote.Name,
    Enum.KeyCode.RightControl.Name
}

local Gui = {}
Gui.__index = Gui

function UiLibrary.new(name)
    local assets = game:GetObjects('rbxassetid://11260223308')[1]
    local mainGui = assets.ScreenGui:Clone()
    local hiding = true
    local dragConnections = {}

    if syn then
        syn.protect_gui(mainGui)
        mainGui.Parent = game.CoreGui
    elseif gethui then
        mainGui.Parent = gethui()
    else
        mainGui.Parent = game.CoreGui
    end

    mainGui.Frame.TopBar.GuiName.Text = name

    mainGui.Frame.TopBar.MouseButton1Down:Connect(function(X,Y)
        local Offset = UDim2.new(0, mainGui.Frame.AbsolutePosition.X - X + 250, 0, mainGui.Frame.AbsolutePosition.Y - Y + 223)
        dragConnections[#dragConnections + 1] = UserInputService.InputChanged:Connect(function(inputObject, gameProccessed)
            if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                mainGui.Frame.Position = UDim2.new(0, inputObject.Position.X, 0, inputObject.Position.Y) + Offset
            end
        end)

        dragConnections[#dragConnections + 1] = UserInputService.InputEnded:Connect(function(inputObject, gameProccessed)
            if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
                for i,v in pairs(dragConnections) do
                    v:Disconnect()
                    dragConnections[i] = nil
                end
            end
        end)

        dragConnections[#dragConnections + 1] = UserInputService.WindowFocusReleased:Connect(function()
            for i,v in pairs(dragConnections) do
                v:Disconnect()
                dragConnections[i] = nil
            end
        end)
    end)

    ContextActionService:BindAction('HideGui',function(actionName, inputState, inputObject)
        if inputState == Enum.UserInputState.Begin then
            hiding = not hiding
            mainGui.Enabled = hiding
        end
    end, false, Enum.KeyCode.RightControl)

    return setmetatable({
        assets = assets,
        gui = mainGui,
        tabs = {},
        scrollingFrames = {}
    }, Gui)
end

function UiLibrary.AddBlacklistedKeybinds(binds)
    for i,v in pairs(binds) do
        table.insert(bindBlacklist, v)
    end
end

function UiLibrary.RemoveBlacklistedKeybinds(binds)
    for i,v in pairs(binds) do
        local bindInTable = table.find(bindBlacklist, v)
        if bindInTable then
            bindBlacklist[bindInTable] = nil
        end
    end
end

local tab = {}
tab.__index = tab

function Gui:CreateTab(name)
    local tabButton = self.assets.Tab:Clone()
    local scrollingFrame = self.assets.TabFrame:Clone()

    tabButton.Text = name
    tabButton.Parent = self.gui.Frame.Tabs.Holder
    scrollingFrame.Parent = self.gui.Frame.Frames
    self.scrollingFrames[tabButton] = scrollingFrame


    table.insert(self.tabs, tabButton)

    for i,v in pairs(self.tabs) do
        v.Size = UDim2.new(1/#self.tabs, 0, 1, 0)
    end

    if #self.tabs == 1 then
        tabButton.TextColor3 = Color3.fromRGB(27, 27, 27)
        tabButton.BackgroundColor3 = Color3.new(1, 1, 1)
        self.CurrentTab = tabButton
    else
        scrollingFrame.Visible = false
    end

    tabButton.MouseButton1Down:Connect(function()
        if self.CurrentTab then
            self.CurrentTab.TextColor3 = Color3.new(1, 1, 1)
            self.CurrentTab.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
            self.scrollingFrames[self.CurrentTab].Visible = false
            self.CurrentTab = tabButton
        end

        tabButton.TextColor3 = Color3.fromRGB(27, 27, 27)
        tabButton.BackgroundColor3 = Color3.new(1, 1, 1)
        self.scrollingFrames[tabButton].Visible = true
    end)
    return setmetatable({
        scrollingFrame = scrollingFrame,
        assets = self.assets
    }, tab)
end

local SectionElement = {}
SectionElement.__index = SectionElement

local function getShortestSide(scrollingFrame, bool)
    if scrollingFrame.Left.UIListLayout.AbsoluteContentSize.Y <= scrollingFrame.Right.UIListLayout.AbsoluteContentSize.Y then
        if not bool then
            return scrollingFrame.Right
        else
            return scrollingFrame.Left
        end
    else
        if not bool then
            return scrollingFrame.Left
        else
            return scrollingFrame.Right
        end
    end
end

function tab:CreateSection(name)
    local sectionGui = self.assets.Section:Clone()

    sectionGui.Parent = getShortestSide(self.scrollingFrame, true)
    sectionGui.Frame.NameGui.TextLabel.Text = name
    sectionGui.Frame.NameGui.Size = UDim2.new(0, sectionGui.Frame.NameGui.TextLabel.TextBounds.X + 6, 0, 20)
    sectionGui.Frame.Frame.Border.Size = UDim2.new(0, sectionGui.Frame.NameGui.TextLabel.TextBounds.X + 8, 0, 22)

    return setmetatable({
        section = sectionGui,
        assets = self.assets,
        scrollingFrame = self.scrollingFrame
    }, SectionElement)
end

local ToggleElement = {}
ToggleElement.__index = ToggleElement

local function setToggleColor(toggleGui, boolean)
    if boolean then
        toggleGui.ImageButton.BackgroundColor3 = Color3.new(1, 1, 1)
    else
        toggleGui.ImageButton.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
    end
end

function SectionElement:CreateToggle(name, callback)
    local toggleGui = self.assets.Toggle:Clone()
    local toggleTable = {
        boolean = false,
        toggleGui = toggleGui,
        callback = callback,
        assets = self.assets,
        section = self.section,
        scrollingFrame = self.scrollingFrame
    }

    toggleGui.TextLabel.Text = name
    toggleGui.Parent = self.section.Frame.Holder
    self.section.Size = UDim2.new(1, 0, 0, self.section.Frame.Holder.UIListLayout.AbsoluteContentSize.Y + 17)
    self.scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, getShortestSide(self.scrollingFrame, false).UIListLayout.AbsoluteContentSize.Y + 12)

    toggleGui.ImageButton.MouseButton1Down:Connect(function()
        toggleTable.boolean = not toggleTable.boolean
        setToggleColor(toggleGui, toggleTable.boolean)
        callback(toggleTable.boolean, toggleTable.sliderValue)
    end)

    return setmetatable(toggleTable, ToggleElement)
end

function ToggleElement:SetToggle(boolean)
    self.boolean = not boolean
    setToggleColor(self.toggleGui, self.boolean)
end

local function setupBind(self)
    if self.secondaryInput then
        self.keybindGui.Button.Text = secondaryBinds[self.secondaryInput].. ' + '.. self.primaryInput
    else
        self.keybindGui.Button.Text = self.primaryInput
    end

    local secondaryInputDown

    binds[self.toggleGui][#binds[self.toggleGui] + 1] = UserInputService.InputBegan:Connect(function(inputObject, gameProccessed)
        if not gameProccessed then
           if self.secondaryInput then
                if inputObject.KeyCode.Name == self.secondaryInput then
                    secondaryInputDown = true
                end

                if secondaryInputDown and inputObject.KeyCode.Name == self.primaryInput then
                    self.boolean = not self.boolean
                    setToggleColor(self.toggleGui, self.boolean)
                    self.callback(self.boolean, self.sliderValue)
                end
            else
                if inputObject.KeyCode.Name == self.primaryInput then
                    self.boolean = not self.boolean
                    setToggleColor(self.toggleGui, self.boolean)
                    self.callback(self.boolean, self.sliderValue)
                end
           end
        end
    end)

    if self.secondaryInput then
        binds[self.toggleGui][#binds[self.toggleGui] + 1] = UserInputService.InputEnded:Connect(function(inputObject, gameProccessed)
            if not gameProccessed then
                if inputObject.KeyCode.Name == self.secondaryInput then
                    secondaryInputDown = false
                end
            end
        end)
    end
end

function ToggleElement:AddKeybind(bindsToSet, callback)
    local bindset = false
    self.bindCallback = callback

    if bindsToSet then
        if #bindsToSet >= 2 then
            for i,v in pairs(bindsToSet) do
                if secondaryBinds[v] then
                    self.secondaryInput = v
                end

                if not table.find(bindBlacklist, v) then
                    self.primaryInput = v
                end
            end

            if self.secondaryInput and not self.primaryInput then
                self.secondaryInput = nil
            else
                bindset = true
                self.bindCallback({self.secondaryInput, self.primaryInput})
                setupBind(self)
            end
        end
    end

    if not bindset then
        self.keybindGui = self.assets.KeyBind:Clone()
        self.keybindGui.Parent = self.toggleGui

        self.keybindGui.Button.MouseButton1Down:Connect(function()
            if binds[self.toggleGui] then
                for i,v in pairs(binds[self.toggleGui]) do
                    v:Disconnect()
                end
                binds[self.toggleGui] = {}
            end

            self.keybindGui.Button.Text = '...'
            self.secondaryInput = nil
            self.primaryInput = nil
            local getInputs
            binds[self.toggleGui] = {}
            
            getInputs = UserInputService.InputBegan:Connect(function(inputObject, gameProccessed)
                if not gameProccessed then
                    if secondaryBinds[inputObject.KeyCode.Name] then
                        self.secondaryInput  = inputObject.KeyCode.Name
                        self.keybindGui.Button.Text = secondaryBinds[self.secondaryInput ].. ' + ...'
                    elseif not table.find(bindBlacklist, inputObject.KeyCode.Name) then
                        self.primaryInput = inputObject.KeyCode.Name
                        self.primaryInput = self.primaryInput
                    end

                    if self.primaryInput then
                        getInputs:Disconnect()
                        self.bindCallback({self.secondaryInput, self.primaryInput})
                        setupBind(self)
                    end
                end
            end)
        end)

        self.keybindGui.Button.MouseButton2Down:Connect(function()
            self.keybindGui.Button.Text = 'NONE'
            self.secondaryInput = nil
            self.primaryInput = nil

            self.bindCallback()

            if binds[self.toggleGui] then
                for i,v in pairs(binds[self.toggleGui]) do
                    v:Disconnect()
                end

                binds[self.toggleGui] = {}
            end
        end)
    end

    return self
end

function ToggleElement:SetKeybind(bindsToSet)
    if #bindsToSet >= 2 then
        if binds[self.toggleGui] then
            for i,v in pairs(binds[self.toggleGui]) do
                v:Disconnect()
            end

            binds[self.toggleGui] = {}
        end

        self.secondaryInput = nil
        self.primaryInput = nil

        for i,v in pairs(bindsToSet) do
            if secondaryBinds[v] then
                self.secondaryInput = v
            end

            if not table.find(bindBlacklist, v) then
                self.primaryInput = v
            end
        end

        if self.secondaryInput and not self.primaryInput then
            self.secondaryInput = nil
            return
        else
            self.bindCallback({self.secondaryInput, self.primaryInput})
            setupBind(self)
        end
    end
end

function ToggleElement:GetKeybind()
    return {self.secondaryInput, self.primaryInput}
end

function ToggleElement:AddSlider(default, minMax)
    self.sliderGui = self.assets.ToggleSlider:Clone()
    self.minMax = minMax
    local sliderConnections = {}

    self.sliderGui.Frame.Size = UDim2.new((default - self.minMax[1]) / (self.minMax[2] - self.minMax[1]), 0, 1, 0)
    self.sliderValue = default
    self.sliderGui.TextLabel.Text = self.sliderValue..' / '..self.minMax[2]
    self.toggleGui.Size = UDim2.new(1, 0, 0, 40)
    self.section.Size = UDim2.new(1, 0, 0, self.section.Frame.Holder.UIListLayout.AbsoluteContentSize.Y + 17)
    self.scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, getShortestSide(self.scrollingFrame, false).UIListLayout.AbsoluteContentSize.Y + 12)
    self.sliderGui.Parent = self.toggleGui

    self.sliderGui.TextLabel.MouseButton1Down:Connect(function(X)
        for i,v in pairs(sliderConnections) do
            v:Disconnect()
            sliderConnections[i] = nil
        end

        self.sliderGui.Frame.Size = UDim2.new((X - self.sliderGui.Frame.AbsolutePosition.X) / self.sliderGui.TextLabel.AbsoluteSize.X, 0, 1, 0)
        self.sliderValue = math.round((X - self.sliderGui.Frame.AbsolutePosition.x) / self.sliderGui.TextLabel.AbsoluteSize.X * (self.minMax[2] - self.minMax[1]) + self.minMax[1])
        self.sliderGui.TextLabel.Text = self.sliderValue..' / '..self.minMax[2]
        self.callback(self.boolean, self.sliderValue)
        sliderConnections[#sliderConnections + 1] = UserInputService.InputChanged:Connect(function(inputObject, gameProccessed)
            if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                local precentage = math.clamp((inputObject.Position.X - self.sliderGui.Frame.AbsolutePosition.X) / self.sliderGui.TextLabel.AbsoluteSize.X, 0, 1)
                local previousSliderValue = self.sliderValue
                self.sliderValue = math.round(precentage * (self.minMax[2] - self.minMax[1]) + self.minMax[1])

                if previousSliderValue ~= self.sliderValue then
                    self.sliderGui.Frame.Size = UDim2.new(precentage, 0, 1, 0)
                    self.sliderGui.TextLabel.Text = self.sliderValue..' / '..self.minMax[2]
                    self.callback(self.boolean, self.sliderValue)
                end
            end
        end)

        sliderConnections[#sliderConnections + 1] = UserInputService.InputEnded:Connect(function(inputObject, gameProccessed)
            if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
                for i,v in pairs(sliderConnections) do
                    v:Disconnect()
                    sliderConnections[i] = nil
                end
            end
        end)

        sliderConnections[#sliderConnections + 1] = UserInputService.WindowFocusReleased:Connect(function()
            for i,v in pairs(sliderConnections) do
                v:Disconnect()
                sliderConnections[i] = nil
            end
        end)
    end)
    return self
end

function ToggleElement:SetSlider(number)
    if self.sliderValue then
        local number = math.clamp(number, self.minMax[1], self.minMax[2])

        self.sliderGui.Frame.Size = UDim2.new((number - self.minMax[1]) / (self.minMax[2] - self.minMax[1]), 0, 1, 0)
        self.sliderValue = number
        self.sliderGui.TextLabel.Text = self.sliderValue..' / '..self.minMax[2]
        self.callback(self.boolean, self.sliderValue)
    end
end

local SliderElement = {}
SliderElement.__index = SliderElement

function SectionElement:CreateSlider(name, default, minMax, callback)
    local slider = {}
    slider.sliderGui = self.assets.Slider:Clone()
    slider.minMax = minMax
    slider.callback = callback
    local sliderConnections = {}
    
    slider.sliderGui.Slider.Frame.Size = UDim2.new((default - slider.minMax[1]) / (slider.minMax[2] - slider.minMax[1]), 0, 1, 0)
    slider.sliderValue = default
    slider.sliderGui.Slider.TextLabel.Text = slider.sliderValue..' / '..slider.minMax[2]
    slider.sliderGui.TextLabel.Text = name
    slider.sliderGui.Parent = self.section.Frame.Holder
    self.section.Size = UDim2.new(1, 0, 0, self.section.Frame.Holder.UIListLayout.AbsoluteContentSize.Y + 17)
    self.scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, getShortestSide(self.scrollingFrame, false).UIListLayout.AbsoluteContentSize.Y + 12)

    slider.sliderGui.Slider.TextLabel.MouseButton1Down:Connect(function(X)
        for i,v in pairs(sliderConnections) do
            v:Disconnect()
            sliderConnections[i] = nil
        end

        slider.sliderGui.Slider.Frame.Size = UDim2.new((X - slider.sliderGui.Slider.Frame.AbsolutePosition.X) / slider.sliderGui.TextLabel.AbsoluteSize.X, 0, 1, 0)
        slider.sliderValue = math.round((X - slider.sliderGui.Slider.Frame.AbsolutePosition.x) / slider.sliderGui.TextLabel.AbsoluteSize.X * (slider.minMax[2] - slider.minMax[1]) + slider.minMax[1])
        slider.sliderGui.Slider.TextLabel.Text = slider.sliderValue..' / '..slider.minMax[2]
        slider.callback(slider.boolean, slider.sliderValue)
        sliderConnections[1] = UserInputService.InputChanged:Connect(function(inputObject, gameProccessed)
            if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                local precentage = math.clamp((inputObject.Position.X - slider.sliderGui.Slider.Frame.AbsolutePosition.X) / slider.sliderGui.TextLabel.AbsoluteSize.X, 0, 1)
                local previousSliderValue = slider.sliderValue
                slider.sliderValue = math.round(precentage * (slider.minMax[2] - slider.minMax[1]) + slider.minMax[1])

                if previousSliderValue ~= slider.sliderValue then
                    slider.sliderGui.Slider.Frame.Size = UDim2.new(precentage, 0, 1, 0)
                    slider.sliderGui.Slider.TextLabel.Text = slider.sliderValue..' / '..slider.minMax[2]
                    slider.callback(slider.sliderValue)
                end
            end
        end)

        sliderConnections[2] = UserInputService.InputEnded:Connect(function(inputObject, gameProccessed)
            if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
                for i,v in pairs(sliderConnections) do
                    v:Disconnect()
                    sliderConnections[i] = nil
                end
            end
        end)

        sliderConnections[3] = UserInputService.WindowFocusReleased:Connect(function()
            for i,v in pairs(sliderConnections) do
                v:Disconnect()
                sliderConnections[i] = nil
            end
        end)
    end)

    return setmetatable(slider, SliderElement)
end

function SliderElement:SetSlider(number)
    local number = math.clamp(number, self.minMax[1], self.minMax[2])

    self.sliderGui.Slider.Frame.Size = UDim2.new((number - self.minMax[1]) / (self.minMax[2] - self.minMax[1]), 0, 1, 0)
    self.sliderValue = number
    self.sliderGui.Slider.TextLabel.Text = self.sliderValue..' / '..self.minMax[2]
    self.callback(self.sliderValue)
end

function SectionElement:CreateButton(name, callback)
    local button = self.assets.Button:Clone()

    button.ImageButton.Text = name
    button.Parent = self.section.Frame.Holder
    self.section.Size = UDim2.new(1, 0, 0, self.section.Frame.Holder.UIListLayout.AbsoluteContentSize.Y + 17)
    self.scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, getShortestSide(self.scrollingFrame, false).UIListLayout.AbsoluteContentSize.Y + 12)

    button.ImageButton.MouseButton1Down:Connect(function()
        button.ImageButton.TextColor3 = Color3.fromRGB(27, 27, 27)
        button.ImageButton.BackgroundColor3 = Color3.new(1, 1, 1)
        callback()
    end)

    button.ImageButton.MouseButton1Up:Connect(function()
        button.ImageButton.TextColor3 = Color3.new(1, 1, 1)
        button.ImageButton.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
    end)

    button.ImageButton.MouseLeave:Connect(function()
        button.ImageButton.TextColor3 = Color3.new(1, 1, 1)
        button.ImageButton.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
    end)
end

return UiLibrary
