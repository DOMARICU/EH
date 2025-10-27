local Uilib = {}

Uilib.CreateUi = function(s:boolean)
    while not game.Loaded do task.wait(0.5) end

    local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()
    local CheatLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/DOMARICU/EH/main/CheatLib.lua')))()
    if not OrionLib then warn("UI 404 ERROR") return end

    local Window = OrionLib:MakeWindow({
        Name = "Title of the library", HidePremium = false,
        SaveConfig = false,
        ConfigFolder = "OrionTest"
    })

    --TABS
    local CarTab = Window:MakeTab({
        Name = "CAR",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })

    --DEV
    if s then
        local DevTab = Window:MakeTab({
            Name = "Dev Tools",
            Icon = "rbxassetid://4483345998",
            PremiumOnly = false
        })

        DevTab:AddButton({
            Name = "Button!",
            Callback = function()
                    print("button pressed")
            end    
        })
    end

    --Buttons
    CarTab:AddToggle({
        Name = "Car Fling",
        Default = false,
        Callback = function(Value)
            CheatLib.vehicleFlingEnabled = Value
        end
    })
end

return Uilib
