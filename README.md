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
```lua
local Section = Section:CreateToggle({
name: [String](https://github.com/gmarciani](https://create.roblox.com/docs/reference/engine/libraries/string)
default: Boolean
callback: Function
})
```
