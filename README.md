# UiLibrary
A clean UiLibrary made with simplicity and good UX in mind. (not debug-friendly *yet*)

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
*Note* Question Marks means the argument is optional
```lua
local Section = Section:CreateToggle({
name: String
default: Boolean
callback: Function
callbackOnCreation: Boolean? -- to learn more about this and flags scroll to the bottom
flag: String?
})
```
