# UiLibrary
A clean UiLibrary made with simplicity and good UX in mind. (not debug-friendly *yet*, just dont be an idiot and use the wrong value types)

## Getting the Library
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/kartFr/UiLib/main/Main.lua"))()
```

## Creating the Gui
```lua
local Gui = UiLibrary.new(name)
```

## Creating a Tab
```lua
local Tab = Gui:CreateTab(name)
```

## Creating a Section
```lua
local Section = Tab:CreateSection(name)
```

## Creating a Toggle
**Note* Question Marks means the argument is optional
```lua
local Toggle = Section:CreateToggle({
name: String
default: Boolean
callback: Function
callbackOnCreation: Boolean? -- self explanitory
flag: String? -- to learn more about flags scroll to the bottom
})
```
### Toggle Functions

##### Setting the Toggle
```lua
Toggle:Set(Boolean)
```

#### Adding a Slider
```lua
Toggle:AddSlider({
  minimum: Number
  maximum: Number
  default: Number
  callback: Function
  decimalPlaces: Number? -- amount of decimal places the slider will round to
  flag: String?
  callbackOnCreation: Boolean?
})
```

##### Setting a Slider In a toggle
```lua
Toggle:SetSlider(Number)
```

#### Adding a Keybind
```lua
Toggle:AddKeybind({
  default: {Primary Bind, Secondary Bind}? -- This Ui Library introduces the ability to use 2 different buttons for a keybind
  callback: Function? -- Fires when the keybind is changed
})
```
##### Setting a Keybind
```lua
Toggle:SetBind({Primary Bind, Secondary Bind})
```

## Creating a Toggle
```lua
local Section = Section:CreateToggle({
name: String
default: Boolean
callback: Function
callbackOnCreation: Boolean? -- to learn more about this and flags scroll to the bottom
flag: String?
})
```
