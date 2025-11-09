--[[
    Auto Piano Player for "Fling Things and People"
    Libra Heart by imaizumiyui - Auto Spawn Version 3.0
    
    NEW: Automatic blue piano spawning!
    Part 1/2 - Core Functions
    
    Version: 3.0.0
    License: MIT
]]

-- ============================================================================
-- RAYFIELD INITIALIZATION
-- ============================================================================

local Rayfield
local RayfieldLoadSuccess = false

do
    local success, result = pcall(function()
        return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    
    if success and result then
        Rayfield = result
        RayfieldLoadSuccess = true
        print("[Libra Heart] Rayfield UI loaded successfully")
    else
        warn("[Libra Heart] Failed to load Rayfield UI:", result)
        return
    end
end

if not RayfieldLoadSuccess or not Rayfield then
    error("[Libra Heart] Critical: Rayfield UI library failed to load")
    return
end

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local CONSTANTS = {
    -- Timing
    DEFAULT_CLICK_DELAY = 0.08,
    DEFAULT_NOTE_GAP = 0.05,
    DEFAULT_LOOP_DELAY = 3,
    DEFAULT_PLAY_SPEED = 1.0,
    MIN_PLAY_SPEED = 0.5,
    MAX_PLAY_SPEED = 2.0,
    
    -- Piano Spawning
    PIANO_SPAWN_OFFSET = Vector3.new(0, 2, -8),
    KEY_WIDTH = 2,
    KEY_HEIGHT = 0.5,
    KEY_DEPTH = 4,
    WHITE_KEY_COLOR = Color3.fromRGB(13, 105, 172),
    BLACK_KEY_COLOR = Color3.fromRGB(0, 32, 96),
    BLACK_KEY_HEIGHT_OFFSET = 0.3,
    BLACK_KEY_DEPTH = 2.5,
    
    -- Camera
    CAMERA_OFFSET = Vector3.new(0, 5, 10),
    TELEPORT_OFFSET = Vector3.new(0, 3, 8),
    TELEPORT_WAIT_TIME = 0.5,
    
    KEY_NAMES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"},
    WHITE_KEYS = {"C", "D", "E", "F", "G", "A", "B"},
    BLACK_KEYS = {"C#", "D#", "F#", "G#", "A#"},
    
    -- Delays
    SECTION_DELAY = 0.3,
    FINAL_DELAY = 0.5,
    
    -- UI
    NOTIFICATION_DURATION_SHORT = 2,
    NOTIFICATION_DURATION_MEDIUM = 3,
    NOTIFICATION_DURATION_LONG = 5,
    RAYFIELD_IMAGE = 4483362458
}

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

local State = {
    autoPlayEnabled = false,
    isPlaying = false,
    currentPianoModel = nil,
    pianoKeys = {},
    autoPlayThread = nil,
    originalCameraType = Camera.CameraType,
    cleanupFunctions = {},
    mutex = false,
    spawnedPiano = nil
}

local Settings = {
    autoPlayEnabled = false,
    autoFocusCamera = true,
    clickDelay = CONSTANTS.DEFAULT_CLICK_DELAY,
    noteGap = CONSTANTS.DEFAULT_NOTE_GAP,
    loopDelay = CONSTANTS.DEFAULT_LOOP_DELAY,
    teleportToPiano = false,
    playSpeed = CONSTANTS.DEFAULT_PLAY_SPEED
}

-- ============================================================================
-- SONG DATA
-- ============================================================================

local LibraHeartSong = {
    Name = "Libra Heart - imaizumiyui",
    Intro = {
        {"D#", 0.4}, {"F#", 0.4}, {"G#", 0.4}, {"A#", 0.4},
        {"G#", 0.4}, {"F#", 0.4}, {"D#", 0.6}, {"rest", 0.2},
        {"D#", 0.4}, {"F#", 0.4}, {"G#", 0.4}, {"B", 0.4},
        {"A#", 0.4}, {"G#", 0.4}, {"F#", 0.8}
    },
    VerseA = {
        {"C#", 0.3}, {"D#", 0.3}, {"F#", 0.5}, {"F#", 0.3},
        {"G#", 0.3}, {"F#", 0.3}, {"D#", 0.5}, {"rest", 0.2},
        {"D#", 0.3}, {"F#", 0.3}, {"G#", 0.5}, {"A#", 0.3},
        {"B", 0.4}, {"A#", 0.4}, {"G#", 0.6},
        {"rest", 0.2},
        {"C#", 0.3}, {"D#", 0.3}, {"F#", 0.5}, {"F#", 0.3},
        {"G#", 0.3}, {"A#", 0.3}, {"B", 0.5}, {"rest", 0.2},
        {"B", 0.3}, {"A#", 0.3}, {"G#", 0.5}, {"F#", 0.3},
        {"D#", 0.4}, {"F#", 0.4}, {"G#", 0.8}
    },
    Chorus = {
        {"B", 0.4}, {"B", 0.3}, {"A#", 0.3}, {"G#", 0.4},
        {"F#", 0.3}, {"G#", 0.3}, {"F#", 0.4}, {"D#", 0.4},
        {"rest", 0.2},
        {"D#", 0.3}, {"F#", 0.3}, {"G#", 0.4}, {"A#", 0.4},
        {"B", 0.4}, {"B", 0.4}, {"A#", 0.6},
        {"rest", 0.2},
        {"B", 0.4}, {"B", 0.3}, {"C#", 0.3}, {"D#", 0.4},
        {"F#", 0.4}, {"G#", 0.4}, {"F#", 0.4}, {"D#", 0.4},
        {"rest", 0.2},
        {"F#", 0.3}, {"G#", 0.3}, {"A#", 0.4}, {"B", 0.4},
        {"A#", 0.4}, {"G#", 0.4}, {"F#", 0.8}
    },
    Bridge = {
        {"D#", 0.4}, {"D#", 0.4}, {"F#", 0.4}, {"G#", 0.4},
        {"A#", 0.4}, {"B", 0.4}, {"A#", 0.4}, {"G#", 0.4},
        {"rest", 0.2},
        {"F#", 0.3}, {"F#", 0.3}, {"G#", 0.4}, {"A#", 0.4},
        {"B", 0.4}, {"C#", 0.4}, {"D#", 0.8},
        {"rest", 0.3}
    },
    Outro = {
        {"B", 0.4}, {"A#", 0.4}, {"G#", 0.4}, {"F#", 0.4},
        {"G#", 0.4}, {"F#", 0.4}, {"D#", 0.6}, {"rest", 0.2},
        {"D#", 0.4}, {"F#", 0.4}, {"G#", 0.4}, {"B", 0.4},
        {"A#", 0.6}, {"G#", 0.6}, {"F#", 1.2}
    }
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local Utils = {}

function Utils.safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[Libra Heart] Error:", result)
        return false, result
    end
    return true, result
end

function Utils.isValidInstance(instance)
    return instance and typeof(instance) == "Instance" and instance.Parent ~= nil
end

function Utils.acquireMutex()
    if State.mutex then return false end
    State.mutex = true
    return true
end

function Utils.releaseMutex()
    State.mutex = false
end

function Utils.cleanup()
    for _, cleanupFunc in ipairs(State.cleanupFunctions) do
        Utils.safeCall(cleanupFunc)
    end
    State.cleanupFunctions = {}
end

function Utils.registerCleanup(func)
    table.insert(State.cleanupFunctions, func)
end

-- ============================================================================
-- NOTIFICATION MANAGER
-- ============================================================================

local NotificationManager = {}

function NotificationManager.show(type, title, content, duration)
    if not Rayfield then return end
    
    local icons = {
        success = "✅",
        error = "❌",
        info = "ℹ️",
        warning = "⚠️"
    }
    
    duration = duration or CONSTANTS.NOTIFICATION_DURATION_MEDIUM
    
    Utils.safeCall(function()
        Rayfield:Notify({
            Title = (icons[type] or "") .. " " .. title,
            Content = content,
            Duration = duration,
            Image = CONSTANTS.RAYFIELD_IMAGE
        })
    end)
end

-- ============================================================================
-- PIANO SPAWNER - NEW!
-- ============================================================================

local PianoSpawner = {}

function PianoSpawner.createPianoKey(keyName, position, isBlackKey)
    local key = Instance.new("Part")
    key.Name = keyName
    key.Size = Vector3.new(
        CONSTANTS.KEY_WIDTH,
        CONSTANTS.KEY_HEIGHT,
        isBlackKey and CONSTANTS.BLACK_KEY_DEPTH or CONSTANTS.KEY_DEPTH
    )
    key.Position = position
    key.Anchored = true
    key.CanCollide = true
    key.Material = Enum.Material.SmoothPlastic
    key.Color = isBlackKey and CONSTANTS.BLACK_KEY_COLOR or CONSTANTS.WHITE_KEY_COLOR
    
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 32
    clickDetector.Parent = key
    
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://1356420950"
    sound.Volume = 0.5
    sound.Parent = key
    
    clickDetector.MouseClick:Connect(function()
        if sound then
            sound:Play()
        end
    end)
    
    return key
end

function PianoSpawner.spawnPiano()
    if State.spawnedPiano then
        Utils.safeCall(function()
            State.spawnedPiano:Destroy()
        end)
        State.spawnedPiano = nil
    end
    
    local character = LocalPlayer.Character
    if not character or not character.PrimaryPart then
        NotificationManager.show("error", "Spawn Failed", "Character not found!")
        return false
    end
    
    local spawnPosition = character.PrimaryPart.Position + CONSTANTS.PIANO_SPAWN_OFFSET
    
    local pianoModel = Instance.new("Model")
    pianoModel.Name = "LibraHeartPiano"
    
    local base = Instance.new("Part")
    base.Name = "PianoBase"
    base.Size = Vector3.new(20, 1, 5)
    base.Position = spawnPosition - Vector3.new(0, 1, 0)
    base.Anchored = true
    base.CanCollide = true
    base.Material = Enum.Material.Wood
    base.BrickColor = BrickColor.new("Dark stone grey")
    base.Parent = pianoModel
    
    local whiteKeyIndex = 0
    
    for octave = 0, 1 do
        for i, keyName in ipairs(CONSTANTS.KEY_NAMES) do
            local isBlackKey = table.find(CONSTANTS.BLACK_KEYS, keyName) ~= nil
            
            local xOffset
            if isBlackKey then
                if keyName == "C#" then xOffset = whiteKeyIndex - 0.5
                elseif keyName == "D#" then xOffset = whiteKeyIndex - 0.5
                elseif keyName == "F#" then xOffset = whiteKeyIndex - 0.5
                elseif keyName == "G#" then xOffset = whiteKeyIndex - 0.5
                elseif keyName == "A#" then xOffset = whiteKeyIndex - 0.5
                end
            else
                xOffset = whiteKeyIndex
                whiteKeyIndex = whiteKeyIndex + 1
            end
            
            local keyPosition = spawnPosition + Vector3.new(
                (xOffset - 7) * CONSTANTS.KEY_WIDTH,
                isBlackKey and CONSTANTS.BLACK_KEY_HEIGHT_OFFSET or 0,
                0
            ) + Vector3.new(octave * 14 * CONSTANTS.KEY_WIDTH, 0, 0)
            
            local key = PianoSpawner.createPianoKey(
                keyName .. (octave > 0 and octave or ""),
                keyPosition,
                isBlackKey
            )
            
            key.Parent = pianoModel
        end
    end
    
    pianoModel.Parent = Workspace
    State.spawnedPiano = pianoModel
    
    return true
end

-- ============================================================================
-- PIANO DETECTION
-- ============================================================================

local PianoDetector = {}

function PianoDetector.getPianoKeys(pianoModel)
    local keys = {}
    
    if not pianoModel or not pianoModel.Parent then
        return keys
    end
    
    Utils.safeCall(function()
        for _, obj in ipairs(pianoModel:GetDescendants()) do
            if obj:IsA("BasePart") then
                local keyName = obj.Name
                
                for _, baseName in ipairs(CONSTANTS.KEY_NAMES) do
                    if keyName == baseName or keyName:match("^" .. baseName .. "%d*$") then
                        if not keys[baseName] then
                            keys[baseName] = obj
                        end
                        break
                    end
                end
            end
        end
    end)
    
    return keys
end

-- ============================================================================
-- CONTINUE TO PART 2...
-- ============================================================================

print("[Libra Heart] Part 1/2 loaded. Load Part 2 to continue...")
--[[
    Auto Piano Player - Part 2/2
    このコードはPart 1の続きです
    Part 1を先に実行してください
]]

-- ============================================================================
-- PIANO INTERACTION
-- ============================================================================

local PianoPlayer = {}

function PianoPlayer.clickPianoKey(keyPart)
    if not Utils.isValidInstance(keyPart) then
        return false
    end
    
    local success = false
    
    Utils.safeCall(function()
        local clickDetector = keyPart:FindFirstChildOfClass("ClickDetector")
        if clickDetector then
            fireclickdetector(clickDetector)
            success = true
        end
    end)
    
    if success then return true end
    
    Utils.safeCall(function()
        local proximityPrompt = keyPart:FindFirstChildOfClass("ProximityPrompt")
        if proximityPrompt then
            fireproximityprompt(proximityPrompt)
            success = true
        end
    end)
    
    return success
end

function PianoPlayer.positionCameraAtPiano(pianoModel, keyPart)
    if not Settings.autoFocusCamera then return end
    
    Utils.safeCall(function()
        local targetPos
        
        if keyPart and Utils.isValidInstance(keyPart) then
            targetPos = keyPart.Position
        elseif pianoModel and pianoModel:IsA("Model") then
            targetPos = pianoModel:GetModelCFrame().Position
        end
        
        if targetPos then
            local offset = CONSTANTS.CAMERA_OFFSET
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CFrame = CFrame.new(targetPos + offset, targetPos)
        end
    end)
end

function PianoPlayer.teleportToPiano(pianoModel)
    if not pianoModel then return false end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then
        return false
    end
    
    local success = Utils.safeCall(function()
        local pianoPos = pianoModel:GetModelCFrame().Position
        local teleportPos = pianoPos + CONSTANTS.TELEPORT_OFFSET
        LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(teleportPos))
    end)
    
    return success
end

function PianoPlayer.playNoteSequence(sequence)
    for _, noteInfo in ipairs(sequence) do
        if not Settings.autoPlayEnabled or not State.isPlaying then
            break
        end
        
        local noteName = noteInfo[1]
        local duration = noteInfo[2] * (1 / Settings.playSpeed)
        
        if noteName ~= "rest" then
            local keyPart = State.pianoKeys[noteName]
            
            if keyPart and Utils.isValidInstance(keyPart) then
                if Settings.autoFocusCamera then
                    PianoPlayer.positionCameraAtPiano(State.currentPianoModel, keyPart)
                end
                
                task.wait(Settings.clickDelay)
                PianoPlayer.clickPianoKey(keyPart)
            end
        end
        
        task.wait(math.max(duration, Settings.noteGap))
    end
end

function PianoPlayer.restoreCamera()
    Utils.safeCall(function()
        Camera.CameraType = State.originalCameraType
    end)
end

-- ============================================================================
-- PLAYBACK CONTROL
-- ============================================================================

local PlaybackController = {}

function PlaybackController.stop()
    if not Utils.acquireMutex() then return end
    
    Settings.autoPlayEnabled = false
    State.isPlaying = false
    
    if State.autoPlayThread then
        Utils.safeCall(function()
            task.cancel(State.autoPlayThread)
        end)
        State.autoPlayThread = nil
    end
    
    PianoPlayer.restoreCamera()
    Utils.cleanup()
    Utils.releaseMutex()
end

function PlaybackController.start()
    if not Utils.acquireMutex() then return end
    
    if State.autoPlayThread then
        task.cancel(State.autoPlayThread)
    end
    
    State.autoPlayThread = task.spawn(function()
        State.isPlaying = true
        
        if not State.spawnedPiano or not State.spawnedPiano.Parent then
            NotificationManager.show("error", "No Piano", 
                "Please spawn a piano first!")
            PlaybackController.stop()
            Utils.releaseMutex()
            return
        end
        
        State.currentPianoModel = State.spawnedPiano
        State.pianoKeys = PianoDetector.getPianoKeys(State.currentPianoModel)
        
        local keyCount = 0
        for _ in pairs(State.pianoKeys) do keyCount = keyCount + 1 end
        
        if keyCount == 0 then
            NotificationManager.show("error", "No Keys Found", 
                "Piano has no detectable keys!")
            PlaybackController.stop()
            Utils.releaseMutex()
            return
        end
        
        NotificationManager.show("success", "Libra Heart", 
            string.format("Found %d keys! Starting playback...", keyCount))
        
        if Settings.teleportToPiano then
            PianoPlayer.teleportToPiano(State.currentPianoModel)
            task.wait(CONSTANTS.TELEPORT_WAIT_TIME)
        end
        
        PianoPlayer.positionCameraAtPiano(State.currentPianoModel, nil)
        
        Utils.releaseMutex()
        
        while Settings.autoPlayEnabled and State.isPlaying do
            Utils.safeCall(function()
                PianoPlayer.playNoteSequence(LibraHeartSong.Intro)
                if not Settings.autoPlayEnabled then return end
                
                task.wait(CONSTANTS.SECTION_DELAY)
                PianoPlayer.playNoteSequence(LibraHeartSong.VerseA)
                if not Settings.autoPlayEnabled then return end
                
                task.wait(CONSTANTS.SECTION_DELAY)
                PianoPlayer.playNoteSequence(LibraHeartSong.Chorus)
                if not Settings.autoPlayEnabled then return end
                
                task.wait(CONSTANTS.SECTION_DELAY)
                PianoPlayer.playNoteSequence(LibraHeartSong.VerseA)
                if not Settings.autoPlayEnabled then return end
                
                task.wait(CONSTANTS.SECTION_DELAY)
                PianoPlayer.playNoteSequence(LibraHeartSong.Chorus)
                if not Settings.autoPlayEnabled then return end
                
                task.wait(CONSTANTS.SECTION_DELAY)
                PianoPlayer.playNoteSequence(LibraHeartSong.Bridge)
                if not Settings.autoPlayEnabled then return end
                
                task.wait(CONSTANTS.SECTION_DELAY)
                PianoPlayer.playNoteSequence(LibraHeartSong.Chorus)
                if not Settings.autoPlayEnabled then return end
                
                task.wait(CONSTANTS.FINAL_DELAY)
                PianoPlayer.playNoteSequence(LibraHeartSong.Outro)
            end)
            
            task.wait(Settings.loopDelay)
        end
        
        PianoPlayer.restoreCamera()
        State.isPlaying = false
    end)
end

-- ============================================================================
-- GUI CREATION
-- ============================================================================

local function createGUI()
    if not Rayfield then
        error("[Libra Heart] Cannot create GUI: Rayfield not loaded")
        return nil
    end
    
    local Window = Rayfield:CreateWindow({
        Name = "🎹 Libra Heart - Auto Piano v3.0",
        LoadingTitle = "Libra Heart Loading...",
        LoadingSubtitle = "by imaizumiyui | Auto Spawn Edition",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "LibraHeartPianoConfig",
            FileName = "PianoSettings"
        },
        Discord = {
            Enabled = false
        },
        KeySystem = false
    })
    
    local MainTab = Window:CreateTab("🎵 Libra Heart", CONSTANTS.RAYFIELD_IMAGE)
    local SpawnTab = Window:CreateTab("🎹 Piano Spawner", CONSTANTS.RAYFIELD_IMAGE)
    local SettingsTab = Window:CreateTab("⚙️ Settings", CONSTANTS.RAYFIELD_IMAGE)
    local InfoTab = Window:CreateTab("ℹ️ Info", CONSTANTS.RAYFIELD_IMAGE)
    
    -- Spawn Tab
    SpawnTab:CreateSection("🎹 Piano Management")
    
    SpawnTab:CreateButton({
        Name = "🎹 Spawn Blue Piano",
        Callback = function()
            local success = PianoSpawner.spawnPiano()
            if success then
                NotificationManager.show("success", "Piano Spawned!", 
                    "Blue piano created in front of you!")
            else
                NotificationManager.show("error", "Spawn Failed", 
                    "Could not spawn piano")
            end
        end
    })
    
    SpawnTab:CreateButton({
        Name = "🗑️ Remove Piano",
        Callback = function()
            if State.spawnedPiano then
                State.spawnedPiano:Destroy()
                State.spawnedPiano = nil
                NotificationManager.show("info", "Piano Removed", 
                    "Piano has been deleted")
            else
                NotificationManager.show("warning", "No Piano", 
                    "No spawned piano to remove")
            end
        end
    })
    
    SpawnTab:CreateSection("ℹ️ Instructions")
    
    SpawnTab:CreateParagraph({
        Title = "How to Use",
        Content = "1. Click 'Spawn Blue Piano' button\n2. Piano will appear in front of you\n3. Go to Main tab and toggle 'Play Libra Heart'\n4. Enjoy the music!"
    })
    
    -- Main Tab
    MainTab:CreateSection("Playback Control")
    
    MainTab:CreateToggle({
        Name = "🎹 Play Libra Heart",
        CurrentValue = false,
        Flag = "AutoPlayToggle",
        Callback = function(Value)
            Settings.autoPlayEnabled = Value
            if Value then
                PlaybackController.start()
            else
                PlaybackController.stop()
                NotificationManager.show("info", "Stopped", 
                    "Playback stopped", CONSTANTS.NOTIFICATION_DURATION_SHORT)
            end
        end
    })
    
    MainTab:CreateLabel("Song: Libra Heart by imaizumiyui")
    MainTab:CreateLabel("Complete melody with auto-spawn!")
    
    MainTab:CreateSection("Camera Settings")
    
    MainTab:CreateToggle({
        Name = "📹 Auto Camera Follow",
        CurrentValue = true,
        Flag = "AutoFocusToggle",
        Callback = function(Value)
            Settings.autoFocusCamera = Value
            if not Value then
                PianoPlayer.restoreCamera()
            end
        end
    })
    
    MainTab:CreateToggle({
        Name = "🚀 Teleport to Piano",
        CurrentValue = false,
        Flag = "TeleportToggle",
        Callback = function(Value)
            Settings.teleportToPiano = Value
        end
    })
    
    -- Settings Tab
    SettingsTab:CreateSection("Timing Settings")
    
    SettingsTab:CreateSlider({
        Name = "Play Speed",
        Range = {CONSTANTS.MIN_PLAY_SPEED, CONSTANTS.MAX_PLAY_SPEED},
        Increment = 0.1,
        Suffix = "x",
        CurrentValue = CONSTANTS.DEFAULT_PLAY_SPEED,
        Flag = "PlaySpeedSlider",
        Callback = function(Value)
            Settings.playSpeed = Value
        end
    })
    
    SettingsTab:CreateSlider({
        Name = "Click Delay",
        Range = {0.01, 0.3},
        Increment = 0.01,
        Suffix = "s",
        CurrentValue = CONSTANTS.DEFAULT_CLICK_DELAY,
        Flag = "ClickDelaySlider",
        Callback = function(Value)
            Settings.clickDelay = Value
        end
    })
    
    SettingsTab:CreateSlider({
        Name = "Note Gap",
        Range = {0.01, 0.5},
        Increment = 0.01,
        Suffix = "s",
        CurrentValue = CONSTANTS.DEFAULT_NOTE_GAP,
        Flag = "NoteGapSlider",
        Callback = function(Value)
            Settings.noteGap = Value
        end
    })
    
    SettingsTab:CreateSlider({
        Name = "Loop Delay",
        Range = {1, 20},
        Increment = 1,
        Suffix = "s",
        CurrentValue = CONSTANTS.DEFAULT_LOOP_DELAY,
        Flag = "LoopDelaySlider",
        Callback = function(Value)
            Settings.loopDelay = Value
        end
    })
    
    -- Info Tab
    InfoTab:CreateSection("🎵 Song Information")
    
    InfoTab:CreateParagraph({
        Title = "Libra Heart",
        Content = "Artist: imaizumiyui\nKey: C#m\n\nComplete melody includes:\n• Intro\n• Verse A\n• Chorus\n• Bridge\n• Outro"
    })
    
    InfoTab:CreateSection("📖 How to Use")
    
    InfoTab:CreateParagraph({
        Title = "Quick Start",
        Content = "1. Go to 'Piano Spawner' tab\n2. Click 'Spawn Blue Piano'\n3. Return to 'Libra Heart' tab\n4. Toggle 'Play Libra Heart' ON\n5. Enjoy the music!"
    })
    
    InfoTab:CreateSection("ℹ️ Version Info")
    
    InfoTab:CreateLabel("Libra Heart Auto Piano v3.0")
    InfoTab:CreateLabel("✓ Auto piano spawning")
    InfoTab:CreateLabel("✓ No manual piano needed")
    InfoTab:CreateLabel("✓ Complete automation")
    InfoTab:CreateLabel("✓ Rayfield UI")
    
    return Window
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function initialize()
    print("[Libra Heart] Starting initialization...")
    
    if not Rayfield then
        error("[Libra Heart] Critical: Rayfield not available")
        return false
    end
    
    State.originalCameraType = Camera.CameraType
    
    local success, result = Utils.safeCall(createGUI)
    
    if not success then
        warn("[Libra Heart] Failed to create GUI:", result)
        return false
    end
    
    NotificationManager.show("success", "Libra Heart v3.0", 
        "Ready! Go to Piano Spawner tab!", 
        CONSTANTS.NOTIFICATION_DURATION_LONG)
    
    Utils.registerCleanup(function()
        PlaybackController.stop()
        PianoPlayer.restoreCamera()
        if State.spawnedPiano then
            State.spawnedPiano:Destroy()
        end
    end)
    
    print("[Libra Heart] Initialization complete!")
    return true
end

-- ============================================================================
-- MAIN EXECUTION
-- ============================================================================

local function main()
    print("=" .. string.rep("=", 78))
    print("  Libra Heart Auto Piano Player v3.0")
    print("  Song: Libra Heart by imaizumiyui")
    print("  NEW: Auto Spawn Piano!")
    print("=" .. string.rep("=", 78))
    
    if not RayfieldLoadSuccess or not Rayfield then
        error("[Libra Heart] Cannot continue: Rayfield UI library failed to load")
        return
    end
    
    local success, error = Utils.safeCall(function()
        local initSuccess = initialize()
        if not initSuccess then
            error("Initialization failed")
        end
    end)
    
    if not success then
        warn("[Libra Heart] Fatal error during initialization:", error)
        NotificationManager.show("error", "Initialization Failed", 
            "Script failed to start. Check console for details.")
        return
    end
    
    print("[Libra Heart] Ready! Spawn a piano to begin!")
    print("=" .. string.rep("=", 78))
end

-- ============================================================================
-- GRACEFUL SHUTDOWN
-- ============================================================================

game:GetService("Players").LocalPlayer.OnTeleport:Connect(function()
    print("[Libra Heart] Teleport detected, cleaning up...")
    PlaybackController.stop()
    Utils.cleanup()
end)

-- ============================================================================
-- EXECUTE MAIN
-- ============================================================================

local mainSuccess, mainError = pcall(main)

if not mainSuccess then
    warn("[Libra Heart] Critical error:", mainError)
    
    if Rayfield then
        pcall(function()
            Rayfield:Notify({
                Title = "❌ Critical Error",
                Content = "Script failed to load. Check console (F9).",
                Duration = 10,
                Image = CONSTANTS.RAYFIELD_IMAGE
            })
        end)
    end
end

print("[Libra Heart] Part 2/2 loaded successfully!")

--[[
    ============================================================================
    VERSION 3.0.0 - AUTO SPAWN CHANGELOG
    ============================================================================
    
    [NEW FEATURES]
    ✅ Automatic blue piano spawning
    ✅ "Piano Spawner" tab in UI
    ✅ Spawn/Remove piano buttons
    ✅ No need to find existing pianos
    ✅ Piano spawns in front of player
    
    [IMPROVEMENTS]
    ✅ Simplified workflow
    ✅ Guaranteed compatibility
    ✅ No detection issues
    ✅ Cleaner UI layout
    
    [USAGE]
    1. Go to "Piano Spawner" tab
    2. Click "Spawn Blue Piano"
    3. Go to "Libra Heart" tab
    4. Toggle "Play Libra Heart" ON
    5. Enjoy!
    
    ============================================================================
]]
