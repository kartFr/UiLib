local UiLibrary = {}
UiLibrary.__index = UiLibrary

local ContextActionService = game:GetService('ContextActionService')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')

local currentColorPicker
local currentColorPickerButton
local colorPickerConnections = {}
local tempColorPickerConnections = {}
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
        _assets = assets,
        _gui = mainGui,
        _tabs = {},
        _scrollingframes = {},
        flags = {}
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
    local tab_button = self._assets.Tab:Clone()
    local scrollingframe = self._assets.Window:Clone()

    tab_button.Text = name
    tab_button.Parent = self._gui.Frame.Tabs.Holder
    scrollingframe.Parent = self._gui.Frame.Windows
    self._scrollingframes[tab_button] = scrollingframe

    table.insert(self._tabs, tab_button)

    for i,v in pairs(self._tabs) do
        v.Size = UDim2.new(1/#self._tabs, 0, 1, 0)
    end

    if #self._tabs == 1 then
        tab_button.TextColor3 = Color3.fromRGB(27, 27, 27)
        tab_button.BackgroundColor3 = Color3.new(1, 1, 1)
        self.CurrentTab = tab_button
    else
        scrollingframe.Visible = false
    end

    tab_button.MouseButton1Down:Connect(function()
        if self.CurrentTab then
            self.CurrentTab.TextColor3 = Color3.new(1, 1, 1)
            self.CurrentTab.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
            self._scrollingframes[self.CurrentTab].Visible = false
            self.CurrentTab = tab_button
        end

        tab_button.TextColor3 = Color3.fromRGB(27, 27, 27)
        tab_button.BackgroundColor3 = Color3.new(1, 1, 1)
        self._scrollingframes[tab_button].Visible = true
    end)
    return setmetatable({
        _scrollingframe = scrollingframe,
        _assets = self._assets,
        _gui = self._gui,
        _flags = self.flags
    }, tab)
end

local SectionElement = {}
SectionElement.__index = SectionElement

local function getShortestSide(_scrollingframe, bool)
    if _scrollingframe.Left.UIListLayout.AbsoluteContentSize.Y <= _scrollingframe.Right.UIListLayout.AbsoluteContentSize.Y then
        if not bool then
            return _scrollingframe.Right
        else
            return _scrollingframe.Left
        end
    else
        if not bool then
            return _scrollingframe.Left
        else
            return _scrollingframe.Right
        end
    end
end

function tab:CreateSection(name)
    local sectionGui = self._assets.Section:Clone()

    sectionGui.Parent = getShortestSide(self._scrollingframe, true)
    sectionGui.Frame.NameGui.TextLabel.Text = name
    sectionGui.Frame.NameGui.Size = UDim2.new(0, sectionGui.Frame.NameGui.TextLabel.TextBounds.X + 6, 0, 20)
    sectionGui.Frame.Frame.Border.Size = UDim2.new(0, sectionGui.Frame.NameGui.TextLabel.TextBounds.X + 8, 0, 21)

    return setmetatable({
        _section = sectionGui,
        _assets = self._assets,
        _scrollingframe = self._scrollingframe,
        _gui = self._gui,
        _flags = self._flags
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

function SectionElement:CreateToggle(config)
    --[[
        name = string
        callback = Function
        default = Boolean?
        callbackOnCreation = Boolean?
        flag = String?
    ]]--
    local toggleGui = self._assets.Toggle:Clone()
    local toggleTable = {
        _boolean = config.default or false,
        _toggleGui = toggleGui,
        _callback = config.callback,
        _assets = self._assets,
        _section = self._section,
        _scrollingframe = self._scrollingframe,
        _flagName = config.flag,
        _flags = self._flags
    }

    if toggleTable._boolean ~= false then
        setToggleColor(toggleTable._toggleGui, toggleTable._boolean)
    end

    if toggleTable._flagName then
        self._flags[toggleTable._flagName] = toggleTable._boolean
    end

    toggleGui.TextLabel.Text = config.name
    toggleGui.Parent = self._section.Frame.Holder
    self._section.Size = UDim2.new(1, 0, 0, self._section.Frame.Holder.UIListLayout.AbsoluteContentSize.Y + 17)
    self._scrollingframe.CanvasSize = UDim2.new(0, 0, 0, getShortestSide(self._scrollingframe, false).UIListLayout.AbsoluteContentSize.Y + 12)

    toggleGui.ImageButton.MouseButton1Down:Connect(function()
        toggleTable._boolean = not toggleTable._boolean

        if toggleTable._flagName then
            self._flags[toggleTable._flagName] = toggleTable._boolean
        end
        
        setToggleColor(toggleGui, toggleTable._boolean)
        toggleTable._callback(toggleTable._boolean)
    end)

    toggleGui.ImageButton.MouseEnter:Connect(function()
        toggleTable._toggleGui.ImageButton.Border.ImageColor3 = Color3.fromRGB(255, 255, 255)
    end)

    toggleGui.ImageButton.MouseLeave:Connect(function()
        toggleTable._toggleGui.ImageButton.Border.ImageColor3 = Color3.fromRGB(41, 41, 41)
    end)

    if config.callbackOnCreation then
        task.spawn(config.callback, toggleTable._boolean)
    end

    return setmetatable(toggleTable, ToggleElement)
end

function ToggleElement:Set(boolean)
    if typeof(boolean) == "boolean" then
        self._boolean = boolean

        if self._flagName then
            self._flags[self._flagName] = self._boolean
        end

        setToggleColor(self._toggleGui, self._boolean)
        self._callback(self._boolean)
    end
end

local function setupBind(self)
    if self._secondaryInput then
        self._keybindGui.Button.Text = secondaryBinds[self._secondaryInput].. ' + '.. self._primaryInput
    else
        self._keybindGui.Button.Text = self._primaryInput
    end

    if self._bindFlag then
        self._flags[self._bindFlag] = {self._primaryInput, self._secondaryInput}
    end

    local secondaryInputDown

    self._bindConnections[#self._bindConnections + 1] = UserInputService.InputBegan:Connect(function(inputObject, gameProccessed)
        if not gameProccessed then
           if self._secondaryInput then
                if inputObject.KeyCode.Name == self._secondaryInput then
                    secondaryInputDown = true
                end

                if secondaryInputDown and inputObject.KeyCode.Name == self._primaryInput then
                    self._boolean = not self._boolean

                    if self._flagName then
                        self._flags[self._flagName] = self._boolean
                    end

                    setToggleColor(self._toggleGui, self._boolean)
                    self._callback(self._boolean)
                end
            else
                if inputObject.KeyCode.Name == self._primaryInput then
                    self._boolean = not self._boolean

                    if self._flagName then
                        self._flags[self._flagName] = self._boolean
                    end

                    setToggleColor(self._toggleGui, self._boolean)
                    self._callback(self._boolean)
                end
           end
        end
    end)

    if self._secondaryInput then
        self._bindConnections[#self._bindConnections + 1] = UserInputService.InputEnded:Connect(function(inputObject, gameProccessed)
            if not gameProccessed then
                if inputObject.KeyCode.Name == self._secondaryInput then
                    secondaryInputDown = false
                end
            end
        end)
    end
end

function ToggleElement:AddKeybind(config)
    --[[
        config:
        default = {Secondary Bind, Primary Bind)?
        callback = Function?
        flag = String?
    ]]
    self._keybindGui = self._assets.KeyBind:Clone()
    self._keybindGui.Parent = self._toggleGui
    self._bindCallback = config.callback
    self._bindConnections = {}
    self._bindFlag = config.flag
    local getInputs

    self._keybindGui.Button.MouseButton1Down:Connect(function()
        if #self._bindConnections >= 1 then
            for i,v in pairs(self._bindConnections) do
                v:Disconnect()
                self._bindConnections[i] = nil
            end
        end

        self._keybindGui.Button.Text = '...'
        self._secondaryInput = nil
        self._primaryInput = nil
        
        getInputs = UserInputService.InputBegan:Connect(function(inputObject, gameProccessed)
            if not gameProccessed then
                if secondaryBinds[inputObject.KeyCode.Name] then
                    self._secondaryInput  = inputObject.KeyCode.Name
                    self._keybindGui.Button.Text = secondaryBinds[self._secondaryInput ].. ' + ...'
                elseif not table.find(bindBlacklist, inputObject.KeyCode.Name) then
                    self._primaryInput = inputObject.KeyCode.Name
                end

             
                if self._primaryInput then
                    getInputs:Disconnect()
                    setupBind(self)

                    if self._bindCallback then
                        self._bindCallback({self._primaryInput, self._secondaryInput})
                    end
                end
            end
        end)
    end)

    self._keybindGui.Button.MouseButton2Down:Connect(function()
        if getInputs then
            getInputs:Disconnect()
        end
        self._keybindGui.Button.Text = 'None'
        self._secondaryInput = nil
        self._primaryInput = nil

        if self._bindCallback then
            self._bindCallback()
        end

        if #self._bindConnections >= 1 then
            for i,v in pairs(self._bindConnections) do
                v:Disconnect()
                self._bindConnections[i] = nil
            end
        end
    end)

    if config.default and typeof(config.default) == 'table' then
        for i,v in pairs(config.default) do
            if secondaryBinds[v] then
                self._secondaryInput = v
            end

            if not table.find(bindBlacklist, v) and not secondaryBinds[v] then
                self._primaryInput = v
            end
        end
        
        if self._secondaryInput and not self._primaryInput then
            self._secondaryInput = nil
        else
            setupBind(self)
        end
    end

    return self
end

function ToggleElement:SetBind(newBind)
    if self._keybindGui and typeof(newBind) == 'table' then
        if #self._bindConnections >= 1 then
            for i,v in pairs(self._bindConnections) do
                v:Disconnect()
                self._bindConnections[i] = nil
            end
        end

        self._secondaryInput = nil
        self._primaryInput = nil

        for i,v in pairs(newBind) do
            if secondaryBinds[v] then
                self._secondaryInput = v
            end

            if not table.find(bindBlacklist, v) and not secondaryBinds[v] then
                self._primaryInput = v
            end
        end

        if self._secondaryInput and not self._primaryInput then
            self._secondaryInput = nil
            return
        else
            setupBind(self)

            if self._bindCallback then
                self._bindCallback({self._primaryInput, self._secondaryInput})
            end
        end
    end
end

local function round(number, decimalPlaces)
    local power = math.pow(10, decimalPlaces)
    return math.round(number * power) / power 
end

local function createSlider(self)
    local sliderConnections = {}

    self._sliderGui.Frame.Size = UDim2.new((self._sliderValue - self._extrema[1]) / (self._extrema[2] - self._extrema[1]), 0, 1, 0)
    self._sliderGui.TextLabel.Text = self._sliderValue..' / '..self._extrema[2]

    self._sliderGui.TextLabel.MouseButton1Down:Connect(function(X)
        for i,v in pairs(sliderConnections) do
            v:Disconnect()
            sliderConnections[i] = nil
        end

        self._sliding = true
        local previousSliderValue = self._sliderValue
        self._sliderValue = round((X - self._sliderGui.Frame.AbsolutePosition.x) / self._sliderGui.TextLabel.AbsoluteSize.X * (self._extrema[2] - self._extrema[1]) + self._extrema[1], self._decimalPlaces)
        if self._sliderValue ~= previousSliderValue then
            self._sliderGui.Frame.Size = UDim2.new((self._sliderValue - self._extrema[1]) / (self._extrema[2] - self._extrema[1]), 0, 1, 0)
            self._sliderGui.TextLabel.Text = self._sliderValue..' / '..self._extrema[2]

            if self._sliderFlagName then
                self._flags[self._sliderFlagName] = self._sliderValue
            end

            self._sliderCallback(self._sliderValue)
        end

        sliderConnections[#sliderConnections + 1] = UserInputService.InputChanged:Connect(function(inputObject, gameProccessed)
            if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                local precentage = math.clamp((inputObject.Position.X - self._sliderGui.Frame.AbsolutePosition.X) / self._sliderGui.TextLabel.AbsoluteSize.X, 0, 1)
                local previousSliderValue = self._sliderValue
                self._sliderValue = round(precentage * (self._extrema[2] - self._extrema[1]) + self._extrema[1], self._decimalPlaces)
        
                if previousSliderValue ~= self._sliderValue then
                    self._sliderGui.Frame.Size = UDim2.new((self._sliderValue - self._extrema[1]) / (self._extrema[2] - self._extrema[1]), 0, 1, 0)
                    self._sliderGui.TextLabel.Text = self._sliderValue..' / '..self._extrema[2]

                    if self._sliderFlagName then
                        self._flags[self._sliderFlagName] = self._sliderValue
                    end

                    self._sliderCallback(self._sliderValue)
                end
            end
        end)

        sliderConnections[#sliderConnections + 1] = UserInputService.InputEnded:Connect(function(inputObject, gameProccessed)
            if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
                self._sliding = false

                if not self._selected then
                    self._sliderGui.Border.ImageColor3 = Color3.fromRGB(41, 41, 41)
                end

                for i,v in pairs(sliderConnections) do
                    v:Disconnect()
                    sliderConnections[i] = nil
                end
            end
        end)

        sliderConnections[#sliderConnections + 1] = UserInputService.WindowFocusReleased:Connect(function()
            self._sliding = false

            if not self._selected then
                self._sliderGui.Border.ImageColor3 = Color3.fromRGB(41, 41, 41)
            end

            for i,v in pairs(sliderConnections) do
                v:Disconnect()
                sliderConnections[i] = nil
            end
        end)
    end)

    self._sliderGui.TextLabel.MouseEnter:Connect(function()
        self._selected = true
        self._sliderGui.Border.ImageColor3 = Color3.fromRGB(255,255,255)
    end)

    self._sliderGui.TextLabel.MouseLeave:Connect(function()
        self._selected = false
        if not self._sliding then
            self._sliderGui.Border.ImageColor3 = Color3.fromRGB(41, 41, 41)
        end
    end)
end

function ToggleElement:AddSlider(config)
    --[[
        config:
        minimum = Number
        maximum = Number
        default = Number
        decimalPlaces = Number?
        callback = Function
        flag = String?
        callbackOnCreation = Boolean?
    ]]--
    self._sliderGui = self._assets.SliderElement:Clone()
    self._extrema = {config.minimum, config.maximum}
    self._decimalPlaces = config.decimalPlaces or 0
    self._sliderCallback = config.callback
    self._sliderValue = round(config.default, self._decimalPlaces)
    self._sliderFlagName = config.flag

    self._sliderGui.Parent = self._toggleGui
    self._toggleGui.Size = UDim2.new(1, 0, 0, 40)
    self._section.Size = UDim2.new(1, 0, 0, self._section.Frame.Holder.UIListLayout.AbsoluteContentSize.Y + 17)
    self._scrollingframe.CanvasSize = UDim2.new(0, 0, 0, getShortestSide(self._scrollingframe, false).UIListLayout.AbsoluteContentSize.Y + 12)

    createSlider(self)

    if self._sliderFlagName then
        self._flags[self._sliderFlagName] = config.default
    end

    if config.callbackOnCreation then
        task.spawn(self._sliderCallback, config.default)
    end

    return self
end

local function setSlider(self, number)
    local number = round(math.clamp(number, self._extrema[1], self._extrema[2]), self._decimalPlaces)

    self._sliderGui.Frame.Size = UDim2.new((number - self._extrema[1]) / (self._extrema[2] - self._extrema[1]), 0, 1, 0)
    self._sliderValue = number
    self._sliderGui.TextLabel.Text = self._sliderValue..' / '..self._extrema[2]
    self._callback(self._boolean, self._sliderValue)
end

function ToggleElement:SetSlider(number)
    if self._sliderGui and typeof(number) == "number" then
        if self._sliderFlagName then
            self._flags[self._sliderFlagName] = number
        end

        task.spawn(setSlider, self, number)
    end
end


local SliderElement = {}
SliderElement.__index = SliderElement

function SectionElement:CreateSlider(config)
    --[[
        config:
        name = String
        minimum = Number
        maximum = Number
        default = Number
        decimalPlaces = Number?
        callback = Function
        callbackOnCreation = Boolean?
        flag = String?
    ]]--
    local sliderGui = self._assets.Slider:Clone()
    local sliderElement = self._assets.SliderElement:Clone()

    sliderGui.TextLabel.Text = config.name
    sliderElement.Parent = sliderGui
    sliderGui.Parent = self._section.Frame.Holder
    self._section.Size = UDim2.new(1, 0, 0, self._section.Frame.Holder.UIListLayout.AbsoluteContentSize.Y + 17)
    self._scrollingframe.CanvasSize = UDim2.new(0, 0, 0, getShortestSide(self._scrollingframe, false).UIListLayout.AbsoluteContentSize.Y + 12)
    
    local slider = {}

    slider._sliderGui = sliderElement
    slider._extrema = {config.minimum, config.maximum}
    slider._sliderCallback = config.callback
    slider._decimalPlaces = config.decimalPlaces or 0
    slider._flags = self._flags
    slider._sliderFlagName = config.flag
    slider._sliderValue = config.default

    createSlider(slider)

    if slider._sliderFlagName then
        slider._flags[slider._sliderFlagName] = config.default
    end

    if config.callbackOnCreation then
        task.spawn(slider._callback, config.default)
    end

    return setmetatable(slider, SliderElement)
end

function SliderElement:Set(number)
    if typeof(number) == "number" then
        if self._sliderFlagName then
            self._flags[self._sliderFlagName] = number
        end
    
        task.spawn(setSlider, self, number)
    end
end

function SliderElement:Get()
    return self._value
end

function SectionElement:CreateButton(config)
    --[[
        config:
        name = String
        callback = Functionz
    ]]
    local button = self._assets.Button:Clone()

    button.ImageButton.Text = config.name
    button.Parent = self._section.Frame.Holder
    self._section.Size = UDim2.new(1, 0, 0, self._section.Frame.Holder.UIListLayout.AbsoluteContentSize.Y + 17)
    self._scrollingframe.CanvasSize = UDim2.new(0, 0, 0, getShortestSide(self._scrollingframe, false).UIListLayout.AbsoluteContentSize.Y + 12)

    button.ImageButton.MouseButton1Down:Connect(function()
        button.ImageButton.TextColor3 = Color3.fromRGB(27, 27, 27)
        button.ImageButton.BackgroundColor3 = Color3.new(1, 1, 1)
        config.callback()
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

local ColorPickerElement = {}
ColorPickerElement.__index = ColorPickerElement

local function updateColorPicker(self)
    local newColor = Color3.fromHSV(self._hue, self._saturation, self._value)

    self._button.ImageButton.BackgroundColor3 = newColor
    currentColorPicker.Frame.Button.PlaceholderText = math.round(newColor.R * 255)..', '..math.round(newColor.G * 255)..', '..math.round(newColor.B * 255)
    currentColorPicker.Gradient.Cursor.Position = UDim2.new(self._saturation, 0, 1 - self._value, 0)
    currentColorPicker.Gradient.UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(self._hue, 1, 1))
    }
end

function SectionElement:CreateColorPicker(config)
    --[[
        config:
        name = String
        callback = Function
        default = Color3
        flag = String?
        callbackOnCreation = Boolean?
    ]]--
    local button = self._assets.Toggle:Clone()
    button.ImageButton.BackgroundColor3 = config.default
    local h,s,v = config.default:ToHSV()
    local mouseLeave = false
    local colorPicker = {
        _callback = config.callback,
        _button = button,
        _hue = h,
        _saturation = s,
        _value = v,
        _flags = self._flags,
        _flagName = config.flag
    }

    button.TextLabel.Text = config.name
    button.Parent = self._section.Frame.Holder
    self._section.Size = UDim2.new(1, 0, 0, self._section.Frame.Holder.UIListLayout.AbsoluteContentSize.Y + 17)
    self._scrollingframe.CanvasSize = UDim2.new(0, 0, 0, getShortestSide(self._scrollingframe, false).UIListLayout.AbsoluteContentSize.Y + 12)
    
    if config.flag then
        self._flags[config.flag] = config.default
    end

    if config.callbackOnCreation then
        task.spawn(config.callback, config.default)
    end

    button.ImageButton.MouseEnter:Connect(function()
        mouseLeave = false
        button.ImageButton.Border.ImageColor3 = Color3.fromRGB(255, 255, 255)
    end)

    button.ImageButton.MouseLeave:Connect(function()
        mouseLeave = true
        if currentColorPickerButton ~= button then
            button.ImageButton.Border.ImageColor3 = Color3.fromRGB(41, 41, 41)
        end
    end)    

    button.ImageButton.MouseButton1Down:Connect(function()
        if currentColorPickerButton == button then
            currentColorPickerButton = nil
            currentColorPicker:Destroy()
            currentColorPicker = nil

            for i,v in pairs(tempColorPickerConnections) do
                v:Disconnect()
                tempColorPickerConnections[i] = nil
            end

            for i,v in pairs(colorPickerConnections) do
                v:Disconnect()
                colorPickerConnections[i] = nil
            end

            if mouseLeave then
                button.ImageButton.Border.ImageColor3 = Color3.fromRGB(255, 255, 255)
            end
        else
            if currentColorPicker then
                currentColorPicker.Visible = false
                currentColorPickerButton.ImageButton.Border.ImageColor3 = Color3.fromRGB(41, 41, 41)

                for i,v in pairs(tempColorPickerConnections) do
                    v:Disconnect()
                    tempColorPickerConnections[i] = nil
                end

                for i,v in pairs(colorPickerConnections) do
                    v:Disconnect()
                    colorPickerConnections[i] = nil
                end
            else
                currentColorPicker = self._assets.ColorPicker:Clone()
                currentColorPicker.Parent = self._gui
                currentColorPicker.Visible = false
            end
    
            currentColorPickerButton = button
            updateColorPicker(colorPicker)
            
            colorPickerConnections[#colorPickerConnections + 1] = RunService.Heartbeat:Connect(function()
                if not currentColorPicker.Visible then
                    currentColorPicker.Visible = true
                end
                currentColorPicker.Position = UDim2.new(0, button.ImageButton.AbsolutePosition.X, 0, button.ImageButton.AbsolutePosition.Y + 65)
            end)

            

            colorPickerConnections[#colorPickerConnections + 1] = currentColorPicker.Slider.MouseButton1Down:Connect(function(X, Y)
                colorPicker._hue = (X - currentColorPicker.Slider.AbsolutePosition.X) / currentColorPicker.Slider.AbsoluteSize.X
                updateColorPicker(colorPicker)

                if colorPicker._flagName then
                    colorPicker._flags[colorPicker._flagName] = Color3.fromHSV(colorPicker._hue, colorPicker._saturation, colorPicker._value)
                end

                colorPicker._callback(Color3.fromHSV(colorPicker._hue, colorPicker._saturation, colorPicker._value))

                tempColorPickerConnections[#tempColorPickerConnections + 1] = UserInputService.InputChanged:Connect(function(inputObject, gameProcessed)
                    if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                        colorPicker._hue = math.clamp((inputObject.Position.X - currentColorPicker.Slider.AbsolutePosition.X) / currentColorPicker.Slider.AbsoluteSize.X, 0, 1)
                        updateColorPicker(colorPicker)

                        if colorPicker._flagName then
                            colorPicker._flags[colorPicker._flagName] = Color3.fromHSV(colorPicker._hue, colorPicker._saturation, colorPicker._value)
                        end

                        colorPicker._callback(Color3.fromHSV(colorPicker._hue, colorPicker._saturation, colorPicker._value))
                    end
                end)
            end)

            colorPickerConnections[#colorPickerConnections + 1] = currentColorPicker.Gradient.TextButton.MouseButton1Down:Connect(function(X, Y)
                colorPicker._saturation = (X - currentColorPicker.Gradient.TextButton.AbsolutePosition.X) / currentColorPicker.Gradient.TextButton.AbsoluteSize.X
                colorPicker._value = 1 - ((Y - 35) - currentColorPicker.Gradient.TextButton.AbsolutePosition.Y) / currentColorPicker.Gradient.TextButton.AbsoluteSize.Y
                updateColorPicker(colorPicker)

                if colorPicker._flagName then
                    colorPicker._flags[colorPicker._flagName] = Color3.fromHSV(colorPicker._hue, colorPicker._saturation, colorPicker._value)
                end

                colorPicker._callback(Color3.fromHSV(colorPicker._hue, colorPicker._saturation, colorPicker._value))

                tempColorPickerConnections[#tempColorPickerConnections + 1] = UserInputService.InputChanged:Connect(function(inputObject, gameProcessed)
                    if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                        colorPicker._saturation = math.clamp((inputObject.Position.X - currentColorPicker.Gradient.TextButton.AbsolutePosition.X) / currentColorPicker.Gradient.TextButton.AbsoluteSize.X, 0, 1)
                        colorPicker._value = 1 - math.clamp((inputObject.Position.Y - currentColorPicker.Gradient.TextButton.AbsolutePosition.Y) / currentColorPicker.Gradient.TextButton.AbsoluteSize.Y, 0, 1)
                        updateColorPicker(colorPicker)

                        if colorPicker._flagName then
                            colorPicker._flags[colorPicker._flagName] = Color3.fromHSV(colorPicker._hue, colorPicker._saturation, colorPicker._value)
                        end

                        colorPicker._callback(Color3.fromHSV(colorPicker._hue, colorPicker._saturation, colorPicker._value))
                    end
                end)
            end)

            colorPickerConnections[#colorPickerConnections + 1] = UserInputService.InputEnded:Connect(function(inputObject, gameProccessed)
                if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
                    for i,v in pairs(tempColorPickerConnections) do
                        v:Disconnect()
                        tempColorPickerConnections[i] = nil
                    end
                end
            end)

            colorPickerConnections[#colorPickerConnections + 1] =  UserInputService.WindowFocusReleased:Connect(function()
                for i,v in pairs(tempColorPickerConnections) do
                    v:Disconnect()
                    tempColorPickerConnections[i] = nil
                end
            end)

            colorPickerConnections[#colorPickerConnections + 1] = currentColorPicker.Frame.Button.FocusLost:Connect(function(enterPressed, self)
                if enterPressed then
                    local color = string.split(string.gsub(currentColorPicker.Frame.Button.Text, " ", ""), ",")
                    local h, s, v = Color3.fromRGB(color[1], color[2], color[3]):ToHSV()

                    colorPicker._hue = h
                    colorPicker._saturation = s
                    colorPicker._value = v
                    updateColorPicker(colorPicker)
                    colorPicker._callback(Color3.fromHSV(colorPicker._hue, colorPicker._saturation, colorPicker._value))
                end

                currentColorPicker.Frame.Button.Text = ""
            end)
        end
    end)
    
    return setmetatable(colorPicker, ColorPickerElement)
end

function ColorPickerElement:Set(color)
    if typeof(color) == "Color3" then
        local h, s, v = color:ToHSV()
        self._hue = h
        self._saturation = s
        self._value = v

        if currentColorPickerButton == self._button then
            updateColorPicker(self)
        end

        if self._flagName then
            self._flags[self._flagName] = Color3.fromHSV(self._hue, self._saturation, self._value)
        end

        task.spawn(self._callback, Color3.fromHSV(self._hue, self._saturation, self._value))
    end
end

return UiLibrary
