local UiLibrary = {}
UiLibrary.__index = UiLibrary

local ContextActionService = game:GetService('ContextActionService')
local UserInputService = game:GetService('UserInputService')

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

function SectionElement:CreateToggle(elements)
    --[[
        name = string
        callback = function
        default = boolean?
    ]]--
    local toggleGui = self.assets.Toggle:Clone()
    local toggleTable = {
        boolean = elements.default or false,
        toggleGui = toggleGui,
        callback = elements.callback,
        assets = self.assets,
        section = self.section,
        scrollingFrame = self.scrollingFrame
    }

    if toggleTable.boolean ~= false then
        setToggleColor(toggleTable.toggleGui, toggleTable.boolean)
    end

    toggleGui.TextLabel.Text = elements.name
    toggleGui.Parent = self.section.Frame.Holder
    self.section.Size = UDim2.new(1, 0, 0, self.section.Frame.Holder.UIListLayout.AbsoluteContentSize.Y + 17)
    self.scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, getShortestSide(self.scrollingFrame, false).UIListLayout.AbsoluteContentSize.Y + 12)

    toggleGui.ImageButton.MouseButton1Down:Connect(function()
        toggleTable.boolean = not toggleTable.boolean
        setToggleColor(toggleGui, toggleTable.boolean)
        toggleTable.callback(toggleTable.boolean, toggleTable.sliderValue)
    end)

    toggleGui.ImageButton.MouseEnter:Connect(function()
        toggleTable.toggleGui.ImageButton.Border.ImageColor3 = Color3.fromRGB(255, 255, 255)
    end)

    toggleGui.ImageButton.MouseLeave:Connect(function()
        toggleTable.toggleGui.ImageButton.Border.ImageColor3 = Color3.fromRGB(41, 41, 41)
    end)

    return setmetatable(toggleTable, ToggleElement)
end

function ToggleElement:Set(boolean)
    if boolean ~= self.boolean then
        self.boolean = boolean
        setToggleColor(self.toggleGui, self.boolean)
        self.callback(self.boolean, self.value)
    end
end

local function setupBind(self)
    if self.secondaryInput then
        self.keybindGui.Button.Text = secondaryBinds[self.secondaryInput].. ' + '.. self.primaryInput
    else
        self.keybindGui.Button.Text = self.primaryInput
    end

    local secondaryInputDown

    self.bindConnections[#self.bindConnections + 1] = UserInputService.InputBegan:Connect(function(inputObject, gameProccessed)
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
        self.bindConnections[#self.bindConnections + 1] = UserInputService.InputEnded:Connect(function(inputObject, gameProccessed)
            if not gameProccessed then
                if inputObject.KeyCode.Name == self.secondaryInput then
                    secondaryInputDown = false
                end
            end
        end)
    end
end

function ToggleElement:AddKeybind(elements)
    --[[
        elements:
        default = {Secondary Bind, Primary Bind)?
        callback = function?
    ]]
    self.keybindGui = self.assets.KeyBind:Clone()
    self.keybindGui.Parent = self.toggleGui
    self.bindCallback = elements.callback
    self.bindConnections = {}

    self.keybindGui.Button.MouseButton1Down:Connect(function()
        if #self.bindConnections >= 1 then
            for i,v in pairs(self.bindConnections) do
                v:Disconnect()
                self.bindConnections[i] = nil
            end
        end

        self.keybindGui.Button.Text = '...'
        self.secondaryInput = nil
        self.primaryInput = nil
        local getInputs
        
        getInputs = UserInputService.InputBegan:Connect(function(inputObject, gameProccessed)
            if not gameProccessed then
                if secondaryBinds[inputObject.KeyCode.Name] then
                    self.secondaryInput  = inputObject.KeyCode.Name
                    self.keybindGui.Button.Text = secondaryBinds[self.secondaryInput ].. ' + ...'
                elseif not table.find(bindBlacklist, inputObject.KeyCode.Name) then
                    self.primaryInput = inputObject.KeyCode.Name
                end

             
                if self.primaryInput then
                    getInputs:Disconnect()
                    setupBind(self)

                    if self.bindCallback then
                        self.bindCallback({self.primaryInput, self.secondaryInput})
                    end
                end
            end
        end)
    end)

    self.keybindGui.Button.MouseButton2Down:Connect(function()
        self.keybindGui.Button.Text = 'None'
        self.secondaryInput = nil
        self.primaryInput = nil

        if self.bindCallback then
            self.bindCallback()
        end

        if #self.bindConnections >= 1 then
            for i,v in pairs(self.bindConnections) do
                v:Disconnect()
                self.bindConnections[i] = nil
            end
        end
    end)

    if elements.default and typeof(elements.default) == 'table' then
        for i,v in pairs(elements.default) do
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
            setupBind(self)
        end
    end

    return self
end

function ToggleElement:SetBind(bindsToSet)
    if self.keybindGui then
        if bindsToSet and typeof(bindsToSet) == 'table' then
            if #self.bindConnections >= 1 then
                for i,v in pairs(self.bindConnections) do
                    v:Disconnect()
                    self.bindConnections[i] = nil
                end
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
                setupBind(self)

                if self.bindCallback then
                    self.bindCallback({self.primaryInput, self.secondaryInput})
                end
            end
        end
    end
end

function ToggleElement:GetKeybind()
    if self.keybindGui then
        return {self.primaryInput, self.secondaryInput}
    end
end

local function round(number, decimalPlaces)
    local power = math.pow(10, decimalPlaces)
    return math.round(number * power) / power 
end

local function createSlider(self, callback)
    local sliderConnections = {}

    self.sliderGui.Frame.Size = UDim2.new((self.sliderValue - self.extrema[1]) / (self.extrema[2] - self.extrema[1]), 0, 1, 0)
    self.sliderGui.TextLabel.Text = self.sliderValue..' / '..self.extrema[2]

    self.sliderGui.TextLabel.MouseButton1Down:Connect(function(X)
        for i,v in pairs(sliderConnections) do
            v:Disconnect()
            sliderConnections[i] = nil
        end

        self.sliding = true
        local previousSliderValue = self.sliderValue
        self.sliderValue = round((X - self.sliderGui.Frame.AbsolutePosition.x) / self.sliderGui.TextLabel.AbsoluteSize.X * (self.extrema[2] - self.extrema[1]) + self.extrema[1], self.decimalPlaces)
        
        if self.sliderValue ~= previousSliderValue then
            self.sliderGui.Frame.Size = UDim2.new((self.sliderValue - self.extrema[1]) / (self.extrema[2] - self.extrema[1]), 0, 1, 0)
            self.sliderGui.TextLabel.Text = self.sliderValue..' / '..self.extrema[2]
            callback(self.sliderValue)
        end

        sliderConnections[#sliderConnections + 1] = UserInputService.InputChanged:Connect(function(inputObject, gameProccessed)
            if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                local precentage = math.clamp((inputObject.Position.X - self.sliderGui.Frame.AbsolutePosition.X) / self.sliderGui.TextLabel.AbsoluteSize.X, 0, 1)
                local previousSliderValue = self.sliderValue
                self.sliderValue = round(precentage * (self.extrema[2] - self.extrema[1]) + self.extrema[1], self.decimalPlaces)
        
                if previousSliderValue ~= self.sliderValue then
                    self.sliderGui.Frame.Size = UDim2.new((self.sliderValue - self.extrema[1]) / (self.extrema[2] - self.extrema[1]), 0, 1, 0)
                    self.sliderGui.TextLabel.Text = self.sliderValue..' / '..self.extrema[2]
                    callback(self.sliderValue)
                end
            end
        end)

        sliderConnections[#sliderConnections + 1] = UserInputService.InputEnded:Connect(function(inputObject, gameProccessed)
            if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
                self.sliding = false

                if not self.selected then
                    self.sliderGui.Border.ImageColor3 = Color3.fromRGB(41, 41, 41)
                end

                for i,v in pairs(sliderConnections) do
                    v:Disconnect()
                    sliderConnections[i] = nil
                end
            end
        end)

        sliderConnections[#sliderConnections + 1] = UserInputService.WindowFocusReleased:Connect(function()
            self.sliding = false

            if not self.selected then
                self.sliderGui.Border.ImageColor3 = Color3.fromRGB(41, 41, 41)
            end

            for i,v in pairs(sliderConnections) do
                v:Disconnect()
                sliderConnections[i] = nil
            end
        end)
    end)

    self.sliderGui.TextLabel.MouseEnter:Connect(function()
        self.selected = true
        self.sliderGui.Border.ImageColor3 = Color3.fromRGB(255,255,255)
    end)

    self.sliderGui.TextLabel.MouseLeave:Connect(function()
        self.selected = false
        if not self.sliding then
            self.sliderGui.Border.ImageColor3 = Color3.fromRGB(41, 41, 41)
        end
    end)
end

function ToggleElement:AddSlider(elements)
    --[[
        elements:
        minimum = number
        maximum = number
        default = number
        decimalPlaces = number?
        callback = function
    ]]--
    self.sliderGui = self.assets.SliderElement:Clone()
    self.extrema = {elements.minimum, elements.maximum}
    self.decimalPlaces = elements.decimalPlaces or 0
    self.sliderValue = round(elements.default, self.decimalPlaces)
    
    self.sliderGui.Parent = self.toggleGui
    self.toggleGui.Size = UDim2.new(1, 0, 0, 40)
    self.section.Size = UDim2.new(1, 0, 0, self.section.Frame.Holder.UIListLayout.AbsoluteContentSize.Y + 17)
    self.scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, getShortestSide(self.scrollingFrame, false).UIListLayout.AbsoluteContentSize.Y + 12)

    createSlider(self, function(value)
        self.callback(self.boolean, value)
    end)

    return self
end

local function setSlider(self, number)
    if self.sliderGui then
        local number = round(math.clamp(number, self.extrema[1], self.extrema[2]), self.decimalPlaces)

        self.sliderGui.Frame.Size = UDim2.new((number - self.extrema[1]) / (self.extrema[2] - self.extrema[1]), 0, 1, 0)
        self.sliderValue = number
        self.sliderGui.TextLabel.Text = self.sliderValue..' / '..self.extrema[2]
        self.callback(self.boolean, self.sliderValue)
    end
end

function ToggleElement:SetSlider(number)
    setSlider(self, number)
end

local SliderElement = {}
SliderElement.__index = SliderElement

function SectionElement:CreateSlider(elements)
    --[[
        elements:
        name = string
        minimum = number
        maximum = number
        default = number
        decimalPlaces = number?
    ]]--
    local sliderGui = self.assets.Slider:Clone()
    local sliderElement = self.assets.SliderElement:Clone()

    self.section.Size = UDim2.new(1, 0, 0, self.section.Frame.Holder.UIListLayout.AbsoluteContentSize.Y + 17)
    self.scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, getShortestSide(self.scrollingFrame, false).UIListLayout.AbsoluteContentSize.Y + 12)
    sliderGui.TextLabel.Text = elements.name
    sliderGui.Parent = self.section.Frame.Holder
    SliderElement.Parent = sliderGui

    local self = {}

    self.sliderGui = sliderElement
    self.extrema = {elements.minimum, elements.maximum}
    self.callback = elements.callback
    self.decimalPlaces = elements.decimalPlaces or 0

    createSlider(self, elements.callback)

    return setmetatable(self, SliderElement)
end

function SliderElement:Set(number)
    setSlider(self, number)
end

function SectionElement:CreateButton(elements)
    --[[
        elements:
        name = string
        callback = function
    ]]
    local button = self.assets.Button:Clone()

    button.ImageButton.Text = elements.name
    button.Parent = self.section.Frame.Holder
    self.section.Size = UDim2.new(1, 0, 0, self.section.Frame.Holder.UIListLayout.AbsoluteContentSize.Y + 17)
    self.scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, getShortestSide(self.scrollingFrame, false).UIListLayout.AbsoluteContentSize.Y + 12)

    button.ImageButton.MouseButton1Down:Connect(function()
        button.ImageButton.TextColor3 = Color3.fromRGB(27, 27, 27)
        button.ImageButton.BackgroundColor3 = Color3.new(1, 1, 1)
        elements.callback()
    end)

    button.ImageButton.MouseButton1Up:Connect(function()
        button.ImageButton.TextColor3 = Color3.new(1, 1, 1)
        button.ImageButton.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
    end)

    button.ImageButton.MouseEnter:Connect(function()
        button.ImageButton.Border.ImageColor3 = Color3.fromRGB(255, 255, 255)
    end)

    button.ImageButton.MouseLeave:Connect(function()
        button.ImageButton.TextColor3 = Color3.new(1, 1, 1)
        button.ImageButton.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
        button.ImageButton.Border.ImageColor3 = Color3.fromRGB(41, 41, 41)
    end)
end

return UiLibrary
