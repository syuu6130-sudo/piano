--[[
    Auto Piano Clicker with Rayfield GUI
    For YamaRolanSio Piano Toy
    
    Features:
    - Automatic piano key clicking
    - Camera auto-focus on keys
    - Multiple song support
    - Customizable timing
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "🎹 Auto Piano Clicker",
   LoadingTitle = "Piano Clicker Loading...",
   LoadingSubtitle = "by YourName",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "AutoPianoClickerConfig",
      FileName = "PianoSettings"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false
})

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Variables
local Settings = {
    AutoPlayEnabled = false,
    AutoFocusCamera = true,
    ClickDelay = 0.05,
    NoteGap = 0.04,
    LoopDelay = 1,
    CurrentSong = 1,
    CameraDistance = 8,
    CameraHeight = 3
}

-- Piano key mapping (common piano toy layout)
local KeyMapping = {
    ["C4"] = "C",
    ["D4"] = "D", 
    ["E4"] = "E",
    ["F4"] = "F",
    ["G4"] = "G",
    ["A4"] = "A",
    ["B4"] = "B",
    ["C5"] = "C5",
    ["D5"] = "D5",
    ["E5"] = "E5",
    ["F5"] = "F5",
    ["G5"] = "G5",
    ["A5"] = "A5",
    ["B5"] = "B5"
}

-- Songs Library
local Songs = {
    {
        Name = "きらきら星 (Twinkle Star)",
        Sequence = {
            {"C4", 0.4}, {"C4", 0.4}, {"G4", 0.4}, {"G4", 0.4},
            {"A4", 0.4}, {"A4", 0.4}, {"G4", 0.8},
            {"F4", 0.4}, {"F4", 0.4}, {"E4", 0.4}, {"E4", 0.4},
            {"D4", 0.4}, {"D4", 0.4}, {"C4", 0.8}
        }
    },
    {
        Name = "メリーさんの羊 (Mary's Lamb)",
        Sequence = {
            {"E4", 0.4}, {"D4", 0.4}, {"C4", 0.4}, {"D4", 0.4},
            {"E4", 0.4}, {"E4", 0.4}, {"E4", 0.8},
            {"D4", 0.4}, {"D4", 0.4}, {"D4", 0.8},
            {"E4", 0.4}, {"G4", 0.4}, {"G4", 0.8}
        }
    },
    {
        Name = "ハッピーバースデー (Happy Birthday)",
        Sequence = {
            {"C4", 0.3}, {"C4", 0.3}, {"D4", 0.6}, {"C4", 0.6},
            {"F4", 0.6}, {"E4", 1.2},
            {"C4", 0.3}, {"C4", 0.3}, {"D4", 0.6}, {"C4", 0.6},
            {"G4", 0.6}, {"F4", 1.2}
        }
    },
    {
        Name = "かえるの歌 (Frog Song)",
        Sequence = {
            {"C4", 0.4}, {"D4", 0.4}, {"E4", 0.4}, {"F4", 0.4},
            {"E4", 0.4}, {"D4", 0.4}, {"C4", 0.8},
            {"E4", 0.4}, {"F4", 0.4}, {"G4", 0.4}, {"A4", 0.4},
            {"G4", 0.4}, {"F4", 0.4}, {"E4", 0.8}
        }
    },
    {
        Name = "ドレミの歌 (Do-Re-Mi)",
        Sequence = {
            {"C4", 0.4}, {"D4", 0.4}, {"E4", 0.4}, {"C4", 0.4},
            {"E4", 0.4}, {"C4", 0.4}, {"E4", 0.8},
            {"D4", 0.4}, {"E4", 0.4}, {"F4", 0.4}, {"F4", 0.4},
            {"E4", 0.4}, {"D4", 0.4}, {"F4", 0.8}
        }
    }
}

-- Helper: Find piano in workspace
local function findPiano()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find("YamaRolanSio") then
            return obj
        end
        -- Also check for "Piano" models
        if obj:IsA("Model") and (obj.Name:lower():find("piano") or obj.Name:find("Sio")) then
            return obj
        end
    end
    return nil
end

-- Helper: Find key part by note name
local function findKeyPart(piano, noteName)
    if not piano then return nil end
    
    local keyName = KeyMapping[noteName] or noteName
    
    -- Search in piano descendants
    for _, obj in ipairs(piano:GetDescendants()) do
        if obj:IsA("BasePart") then
            -- Check if name matches
            if obj.Name == keyName or obj.Name:find(keyName) then
                return obj
            end
        end
    end
    
    return nil
end

-- Helper: Click a piano key
local function clickKey(keyPart)
    if not keyPart then return false end
    
    -- Find ClickDetector
    local clickDetector = keyPart:FindFirstChildOfClass("ClickDetector")
    if clickDetector then
        -- Fire the click
        fireclickdetector(clickDetector)
        return true
    end
    
    -- Alternative: Try to find in children
    for _, child in ipairs(keyPart:GetDescendants()) do
        if child:IsA("ClickDetector") then
            fireclickdetector(child)
            return true
        end
    end
    
    return false
end

-- Helper: Focus camera on key
local function focusCameraOnKey(keyPart)
    if not keyPart or not Settings.AutoFocusCamera then return end
    
    local targetPos = keyPart.Position
    local offset = Vector3.new(0, Settings.CameraHeight, Settings.CameraDistance)
    
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = CFrame.new(targetPos + offset, targetPos)
end

-- Helper: Reset camera
local function resetCamera()
    Camera.CameraType = Enum.CameraType.Custom
end

-- Auto play coroutine
local autoPlayThread = nil
local currentPiano = nil

local function startAutoPlay()
    if autoPlayThread then
        task.cancel(autoPlayThread)
    end
    
    autoPlayThread = task.spawn(function()
        -- Find piano first
        currentPiano = findPiano()
        
        if not currentPiano then
            Rayfield:Notify({
               Title = "❌ Piano Not Found",
               Content = "Cannot find YamaRolanSio piano in workspace!",
               Duration = 5,
               Image = 4483362458
            })
            Settings.AutoPlayEnabled = false
            return
        end
        
        Rayfield:Notify({
           Title = "✅ Piano Found",
           Content = "Starting auto play...",
           Duration = 3,
           Image = 4483362458
        })
        
        while Settings.AutoPlayEnabled do
            local currentSong = Songs[Settings.CurrentSong]
            if currentSong then
                for _, noteInfo in ipairs(currentSong.Sequence) do
                    if not Settings.AutoPlayEnabled then break end
                    
                    local note = noteInfo[1]
                    local dur = noteInfo[2] or 0.4
                    
                    if note ~= "rest" then
                        local keyPart = findKeyPart(currentPiano, note)
                        
                        if keyPart then
                            -- Focus camera on key
                            if Settings.AutoFocusCamera then
                                focusCameraOnKey(keyPart)
                            end
                            
                            -- Click the key
                            task.wait(Settings.ClickDelay)
                            local success = clickKey(keyPart)
                            
                            if not success then
                                warn("Failed to click key:", note)
                            end
                        else
                            warn("Key not found:", note)
                        end
                    end
                    
                    task.wait(math.max(dur, Settings.NoteGap))
                end
            end
            task.wait(Settings.LoopDelay)
        end
        
        -- Reset camera when done
        if Settings.AutoFocusCamera then
            resetCamera()
        end
    end)
end

-- GUI Creation
local MainTab = Window:CreateTab("🎵 Main Controls", 4483362458)
local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)
local InfoTab = Window:CreateTab("ℹ️ Info", 4483362458)

-- Main Controls
local PlaybackSection = MainTab:CreateSection("Playback Controls")

local AutoPlayToggle = MainTab:CreateToggle({
   Name = "🎹 Auto Play Piano",
   CurrentValue = false,
   Flag = "AutoPlayToggle",
   Callback = function(Value)
       Settings.AutoPlayEnabled = Value
       if Value then
           startAutoPlay()
       else
           if autoPlayThread then
               task.cancel(autoPlayThread)
           end
           if Settings.AutoFocusCamera then
               resetCamera()
           end
           Rayfield:Notify({
              Title = "⏸️ Auto Play Stopped",
              Content = "Piano playback stopped.",
              Duration = 3,
              Image = 4483362458
           })
       end
   end
})

local SongDropdown = MainTab:CreateDropdown({
   Name = "Select Song",
   Options = {
       "きらきら星 (Twinkle Star)",
       "メリーさんの羊 (Mary's Lamb)", 
       "ハッピーバースデー (Happy Birthday)",
       "かえるの歌 (Frog Song)",
       "ドレミの歌 (Do-Re-Mi)"
   },
   CurrentOption = {"きらきら星 (Twinkle Star)"},
   MultipleOptions = false,
   Flag = "SongDropdown",
   Callback = function(Option)
       for i, song in ipairs(Songs) do
           if song.Name == Option[1] then
               Settings.CurrentSong = i
               Rayfield:Notify({
                  Title = "🎵 Song Changed",
                  Content = "Now playing: " .. song.Name,
                  Duration = 3,
                  Image = 4483362458
               })
               break
           end
       end
   end
})

local CameraSection = MainTab:CreateSection("Camera Controls")

local AutoFocusToggle = MainTab:CreateToggle({
   Name = "📹 Auto Focus Camera",
   CurrentValue = true,
   Flag = "AutoFocusToggle",
   Callback = function(Value)
       Settings.AutoFocusCamera = Value
       if not Value then
           resetCamera()
       end
   end
})

local ManualButtons = MainTab:CreateSection("Manual Controls")

local FindPianoButton = MainTab:CreateButton({
   Name = "🔍 Find Piano",
   Callback = function()
       local piano = findPiano()
       if piano then
           Rayfield:Notify({
              Title = "✅ Piano Found!",
              Content = "Found: " .. piano.Name,
              Duration = 4,
              Image = 4483362458
           })
           currentPiano = piano
       else
           Rayfield:Notify({
              Title = "❌ Piano Not Found",
              Content = "Make sure YamaRolanSio piano is in workspace",
              Duration = 5,
              Image = 4483362458
           })
       end
   end
})

local ResetCameraButton = MainTab:CreateButton({
   Name = "🔄 Reset Camera",
   Callback = function()
       resetCamera()
       Rayfield:Notify({
          Title = "📹 Camera Reset",
          Content = "Camera returned to normal",
          Duration = 2,
          Image = 4483362458
       })
   end
})

-- Settings Tab
local TimingSection = SettingsTab:CreateSection("Timing Settings")

local ClickDelaySlider = SettingsTab:CreateSlider({
   Name = "Click Delay",
   Range = {0.01, 0.2},
   Increment = 0.01,
   Suffix = "s",
   CurrentValue = 0.05,
   Flag = "ClickDelaySlider",
   Callback = function(Value)
       Settings.ClickDelay = Value
   end
})

local NoteGapSlider = SettingsTab:CreateSlider({
   Name = "Note Gap",
   Range = {0.01, 0.3},
   Increment = 0.01,
   Suffix = "s",
   CurrentValue = 0.04,
   Flag = "NoteGapSlider",
   Callback = function(Value)
       Settings.NoteGap = Value
   end
})

local LoopDelaySlider = SettingsTab:CreateSlider({
   Name = "Loop Delay",
   Range = {0.5, 5},
   Increment = 0.1,
   Suffix = "s",
   CurrentValue = 1,
   Flag = "LoopDelaySlider",
   Callback = function(Value)
       Settings.LoopDelay = Value
   end
})

local CameraSettingsSection = SettingsTab:CreateSection("Camera Settings")

local CameraDistanceSlider = SettingsTab:CreateSlider({
   Name = "Camera Distance",
   Range = {3, 15},
   Increment = 0.5,
   Suffix = " studs",
   CurrentValue = 8,
   Flag = "CameraDistanceSlider",
   Callback = function(Value)
       Settings.CameraDistance = Value
   end
})

local CameraHeightSlider = SettingsTab:CreateSlider({
   Name = "Camera Height",
   Range = {0, 8},
   Increment = 0.5,
   Suffix = " studs",
   CurrentValue = 3,
   Flag = "CameraHeightSlider",
   Callback = function(Value)
       Settings.CameraHeight = Value
   end
})

-- Info Tab
InfoTab:CreateSection("📖 How to Use")

InfoTab:CreateParagraph({
    Title = "Step 1: Find Piano",
    Content = "Click 'Find Piano' button to locate the YamaRolanSio piano in the game."
})

InfoTab:CreateParagraph({
    Title = "Step 2: Select Song",
    Content = "Choose a song from the dropdown menu. Multiple Japanese songs are available!"
})

InfoTab:CreateParagraph({
    Title = "Step 3: Start Playing",
    Content = "Toggle 'Auto Play Piano' to start automatic playing. The camera will focus on each key."
})

InfoTab:CreateSection("ℹ️ Information")

InfoTab:CreateLabel("Auto Piano Clicker v1.0")
InfoTab:CreateLabel("For YamaRolanSio Piano Toy")
InfoTab:CreateLabel("")
InfoTab:CreateLabel("Features:")
InfoTab:CreateLabel("✓ Automatic key clicking")
InfoTab:CreateLabel("✓ Camera auto-focus")
InfoTab:CreateLabel("✓ Multiple songs")
InfoTab:CreateLabel("✓ Customizable timing")

InfoTab:CreateSection("⚠️ Requirements")

InfoTab:CreateParagraph({
    Title = "Game Requirements",
    Content = "• YamaRolanSio piano must be in workspace\n• Piano keys must have ClickDetectors\n• Executor must support fireclickdetector"
})

local TestSection = InfoTab:CreateSection("🧪 Test Features")

local TestClickButton = InfoTab:CreateButton({
   Name = "Test Single Note (C4)",
   Callback = function()
       if not currentPiano then
           currentPiano = findPiano()
       end
       
       if currentPiano then
           local keyPart = findKeyPart(currentPiano, "C4")
           if keyPart then
               focusCameraOnKey(keyPart)
               task.wait(0.1)
               local success = clickKey(keyPart)
               if success then
                   Rayfield:Notify({
                      Title = "✅ Test Successful",
                      Content = "C4 key clicked successfully!",
                      Duration = 3,
                      Image = 4483362458
                   })
               else
                   Rayfield:Notify({
                      Title = "❌ Test Failed",
                      Content = "Could not click C4 key",
                      Duration = 3,
                      Image = 4483362458
                   })
               end
           else
               Rayfield:Notify({
                  Title = "❌ Key Not Found",
                  Content = "C4 key not found in piano",
                  Duration = 3,
                  Image = 4483362458
               })
           end
       else
           Rayfield:Notify({
              Title = "❌ Piano Not Found",
              Content = "Please find piano first",
              Duration = 3,
              Image = 4483362458
           })
       end
   end
})

-- Initial notification
Rayfield:Notify({
   Title = "🎹 Auto Piano Clicker Loaded",
   Content = "Click 'Find Piano' to get started!",
   Duration = 5,
   Image = 4483362458
})

-- Auto-find piano on load
task.spawn(function()
    task.wait(2)
    local piano = findPiano()
    if piano then
        currentPiano = piano
        Rayfield:Notify({
           Title = "✅ Piano Auto-Detected",
           Content = "Found: " .. piano.Name,
           Duration = 4,
           Image = 4483362458
        })
    end
end)

print("🎹 Auto Piano Clicker loaded successfully!")
print("📍 Searching for YamaRolanSio piano...")
