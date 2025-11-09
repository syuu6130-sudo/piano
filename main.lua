--[[
    Auto Piano Player with Push Effect
    Created for Roblox
    
    Features:
    - Automatic piano melody playback
    - Push effect around piano keys
    - Rayfield GUI controls
    - Customizable settings
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "🎹 Auto Piano Player",
   LoadingTitle = "Piano System Loading...",
   LoadingSubtitle = "by Your Name",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "AutoPianoConfig",
      FileName = "PianoSettings"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false
})

-- Variables
local PianoKeysFolder = workspace:FindFirstChild("Piano") and workspace.Piano:FindFirstChild("Keys")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Settings
local Settings = {
    AutoPlayEnabled = false,
    PushEnabled = true,
    PushRadius = 12,
    PushStrength = 70,
    PushDuration = 0.35,
    NoteGap = 0.04,
    LoopDelay = 0.8,
    CurrentSong = 1
}

-- Songs Library
local Songs = {
    {
        Name = "Twinkle Twinkle Little Star",
        Sequence = {
            {"C4", 0.4}, {"C4", 0.4}, {"G4", 0.4}, {"G4", 0.4},
            {"A4", 0.4}, {"A4", 0.4}, {"G4", 0.8},
            {"F4", 0.4}, {"F4", 0.4}, {"E4", 0.4}, {"E4", 0.4},
            {"D4", 0.4}, {"D4", 0.4}, {"C4", 0.8}
        }
    },
    {
        Name = "Mary Had a Little Lamb",
        Sequence = {
            {"E4", 0.4}, {"D4", 0.4}, {"C4", 0.4}, {"D4", 0.4},
            {"E4", 0.4}, {"E4", 0.4}, {"E4", 0.8},
            {"D4", 0.4}, {"D4", 0.4}, {"D4", 0.8},
            {"E4", 0.4}, {"G4", 0.4}, {"G4", 0.8}
        }
    },
    {
        Name = "Happy Birthday",
        Sequence = {
            {"C4", 0.3}, {"C4", 0.3}, {"D4", 0.6}, {"C4", 0.6},
            {"F4", 0.6}, {"E4", 1.2},
            {"C4", 0.3}, {"C4", 0.3}, {"D4", 0.6}, {"C4", 0.6},
            {"G4", 0.6}, {"F4", 1.2}
        }
    },
    {
        Name = "Custom Song (Edit in Script)",
        Sequence = {
            {"E4", 0.4}, {"D4", 0.4}, {"C4", 0.8}, {"D4", 0.4},
            {"E4", 0.4}, {"E4", 0.8}, {"rest", 0.2},
            {"E4", 0.4}, {"D4", 0.4}, {"C4", 0.8}
        }
    }
}

-- Helper Functions
local function getKeyPart(noteName)
    if not PianoKeysFolder then
        PianoKeysFolder = workspace:FindFirstChild("Piano") and workspace.Piano:FindFirstChild("Keys")
    end
    return PianoKeysFolder and PianoKeysFolder:FindFirstChild(noteName)
end

local function playNoteAndPush(noteName, velocityMultiplier)
    local keyPart = getKeyPart(noteName)
    if not keyPart then
        return
    end

    -- Play sound
    local sound = keyPart:FindFirstChildOfClass("Sound")
    if sound then
        sound:Play()
    end

    if not Settings.PushEnabled then return end

    -- Push players
    local origin = keyPart.Position
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char and char.PrimaryPart then
            local root = char.PrimaryPart
            local dist = (root.Position - origin).Magnitude
            if dist <= Settings.PushRadius then
                local upVel = Vector3.new(
                    (math.random()-0.5)*6,
                    1 + (velocityMultiplier or 1),
                    (math.random()-0.5)*6
                ) * Settings.PushStrength
                
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                bv.Velocity = upVel
                bv.P = 1000
                bv.Parent = root
                
                task.delay(Settings.PushDuration, function()
                    if bv and bv.Parent then 
                        bv:Destroy() 
                    end
                end)
            end
        end
    end

    -- Push physics objects
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part.Anchored and part ~= keyPart then
            if (part.Position - origin).Magnitude <= Settings.PushRadius then
                if typeof(part.AssemblyLinearVelocity) == "Vector3" then
                    part.AssemblyLinearVelocity = part.AssemblyLinearVelocity + 
                        Vector3.new(
                            (math.random()-0.5)*6,
                            1 + (velocityMultiplier or 1),
                            (math.random()-0.5)*6
                        ) * (Settings.PushStrength * 0.15)
                end
            end
        end
    end
end

-- Auto play coroutine
local autoPlayThread = nil
local function startAutoPlay()
    if autoPlayThread then
        task.cancel(autoPlayThread)
    end
    
    autoPlayThread = task.spawn(function()
        while Settings.AutoPlayEnabled do
            local currentSong = Songs[Settings.CurrentSong]
            if currentSong then
                for _, noteInfo in ipairs(currentSong.Sequence) do
                    if not Settings.AutoPlayEnabled then break end
                    
                    local note = noteInfo[1]
                    local dur = noteInfo[2] or 0.4
                    local velMult = noteInfo[3] or 1
                    
                    if note ~= "rest" then
                        pcall(function()
                            playNoteAndPush(note, velMult)
                        end)
                    end
                    
                    task.wait(math.max(dur, Settings.NoteGap))
                end
            end
            task.wait(Settings.LoopDelay)
        end
    end)
end

-- GUI Creation
local MainTab = Window:CreateTab("🎵 Main Controls", 4483362458)
local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)

-- Main Controls
local PlaybackSection = MainTab:CreateSection("Playback Controls")

local AutoPlayToggle = MainTab:CreateToggle({
   Name = "Auto Play Piano",
   CurrentValue = false,
   Flag = "AutoPlayToggle",
   Callback = function(Value)
       Settings.AutoPlayEnabled = Value
       if Value then
           startAutoPlay()
           Rayfield:Notify({
              Title = "Auto Play Started",
              Content = "Piano is now playing automatically!",
              Duration = 3,
              Image = 4483362458
           })
       else
           if autoPlayThread then
               task.cancel(autoPlayThread)
           end
           Rayfield:Notify({
              Title = "Auto Play Stopped",
              Content = "Piano playback stopped.",
              Duration = 3,
              Image = 4483362458
           })
       end
   end
})

local SongDropdown = MainTab:CreateDropdown({
   Name = "Select Song",
   Options = {"Twinkle Twinkle", "Mary Had a Lamb", "Happy Birthday", "Custom Song"},
   CurrentOption = {"Twinkle Twinkle"},
   MultipleOptions = false,
   Flag = "SongDropdown",
   Callback = function(Option)
       for i, song in ipairs(Songs) do
           if song.Name:find(Option[1]) then
               Settings.CurrentSong = i
               Rayfield:Notify({
                  Title = "Song Changed",
                  Content = "Now playing: " .. song.Name,
                  Duration = 3,
                  Image = 4483362458
               })
               break
           end
       end
   end
})

local PushSection = MainTab:CreateSection("Push Effect")

local PushToggle = MainTab:CreateToggle({
   Name = "Enable Push Effect",
   CurrentValue = true,
   Flag = "PushToggle",
   Callback = function(Value)
       Settings.PushEnabled = Value
   end
})

-- Settings Tab
local PushSettingsSection = SettingsTab:CreateSection("Push Settings")

local RadiusSlider = SettingsTab:CreateSlider({
   Name = "Push Radius",
   Range = {5, 30},
   Increment = 1,
   Suffix = " studs",
   CurrentValue = 12,
   Flag = "RadiusSlider",
   Callback = function(Value)
       Settings.PushRadius = Value
   end
})

local StrengthSlider = SettingsTab:CreateSlider({
   Name = "Push Strength",
   Range = {20, 150},
   Increment = 5,
   Suffix = " power",
   CurrentValue = 70,
   Flag = "StrengthSlider",
   Callback = function(Value)
       Settings.PushStrength = Value
   end
})

local DurationSlider = SettingsTab:CreateSlider({
   Name = "Push Duration",
   Range = {0.1, 1},
   Increment = 0.05,
   Suffix = "s",
   CurrentValue = 0.35,
   Flag = "DurationSlider",
   Callback = function(Value)
       Settings.PushDuration = Value
   end
})

local TimingSection = SettingsTab:CreateSection("Timing Settings")

local NoteGapSlider = SettingsTab:CreateSlider({
   Name = "Note Gap",
   Range = {0.01, 0.2},
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
   Range = {0.2, 3},
   Increment = 0.1,
   Suffix = "s",
   CurrentValue = 0.8,
   Flag = "LoopDelaySlider",
   Callback = function(Value)
       Settings.LoopDelay = Value
   end
})

-- Info Section
local InfoSection = SettingsTab:CreateSection("Information")

SettingsTab:CreateLabel("Auto Piano Player v1.0")
SettingsTab:CreateLabel("Make sure Piano model is in workspace")

local StatusButton = SettingsTab:CreateButton({
   Name = "Check Piano Status",
   Callback = function()
       local pianoExists = workspace:FindFirstChild("Piano") ~= nil
       local keysExist = PianoKeysFolder ~= nil
       
       if pianoExists and keysExist then
           Rayfield:Notify({
              Title = "✅ Piano Found",
              Content = "Piano is ready to play!",
              Duration = 3,
              Image = 4483362458
           })
       else
           Rayfield:Notify({
              Title = "❌ Piano Not Found",
              Content = "Please make sure Piano model with Keys folder exists in workspace",
              Duration = 5,
              Image = 4483362458
           })
       end
   end
})

-- Initial notification
Rayfield:Notify({
   Title = "🎹 Auto Piano Loaded",
   Content = "Select a song and enable Auto Play!",
   Duration = 5,
   Image = 4483362458
})

print("Auto Piano Player loaded successfully!")
