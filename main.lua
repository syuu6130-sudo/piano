--[[
    Auto Piano Player for "Fling Things and People"
    Libra Heart by imaizumiyui - Complete Version (Improved v2.1)
    
    Fixed: Piano detection for actual "Fling Things and People" game
    
    GitHub: https://github.com/yourusername/libra-heart-piano
    Version: 2.1.0
    License: MIT
]]

-- ============================================================================
-- RAYFIELD INITIALIZATION (MUST BE FIRST)
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
        warn("[Libra Heart] Script cannot continue without UI library")
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
    
    -- Camera
    CAMERA_OFFSET = Vector3.new(0, 5, 10),
    TELEPORT_OFFSET = Vector3.new(0, 3, 8),
    TELEPORT_WAIT_TIME = 0.5,
    
    -- Detection (Updated for Fling Things and People)
    PIANO_PART_NAMES = {"piano", "key", "keys", "keyboard"},
    
    -- Blue colors commonly used in Fling Things and People
    BLUE_COLORS = {
        Color3.fromRGB(0, 0, 255),      -- Pure blue
        Color3.fromRGB(13, 105, 172),   -- Ocean blue
        Color3.fromRGB(0, 32, 96),      -- Dark blue
        Color3.fromRGB(0, 85, 255),     -- Bright blue
        Color3.fromRGB(23, 23, 255),    -- Electric blue
        Color3.fromRGB(0, 170, 255),    -- Sky blue
    },
    
    KEY_NAMES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"},
    
    -- Delays
    SECTION_DELAY = 0.3,
    FINAL_DELAY = 0.5,
    INITIAL_SEARCH_DELAY = 2,
    
    -- UI
    NOTIFICATION_DURATION_SHORT = 2,
    NOTIFICATION_DURATION_MEDIUM = 3,
    NOTIFICATION_DURATION_LONG = 5,
    RAYFIELD_IMAGE = 4483362458,
    
    -- Search depth
    MAX_SEARCH_DEPTH = 50000  -- Maximum descendants to search
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
    foundPianos = {},
    autoPlayThread = nil,
    originalCameraType = Camera.CameraType,
    cleanupFunctions = {},
    mutex = false,
    rayfieldWindow = nil,
    debugMode = true  -- Enable for troubleshooting
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

function Utils.isValidModel(model)
    return Utils.isValidInstance(model) and model:IsA("Model")
end

function Utils.debounce(func, delay)
    local lastCall = 0
    return function(...)
        local now = tick()
        if now - lastCall >= delay then
            lastCall = now
            return func(...)
        end
    end
end

function Utils.acquireMutex()
    if State.mutex then
        return false
    end
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

-- Debug print function
function Utils.debug(...)
    if State.debugMode then
        print("[Libra Heart Debug]", ...)
    end
end

-- ============================================================================
-- NOTIFICATION MANAGER
-- ============================================================================

local NotificationManager = {}

function NotificationManager.show(type, title, content, duration)
    if not Rayfield then
        warn("[Libra Heart] Cannot show notification: Rayfield not initialized")
        return
    end
    
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
-- IMPROVED PIANO DETECTION FOR FLING THINGS AND PEOPLE
-- ============================================================================

local PianoDetector = {}

function PianoDetector.isBlueColor(color)
    for _, blueColor in ipairs(CONSTANTS.BLUE_COLORS) do
        local r_diff = math.abs(color.R - blueColor.R)
        local g_diff = math.abs(color.G - blueColor.G)
        local b_diff = math.abs(color.B - blueColor.B)
        
        -- Allow some tolerance for color matching
        if r_diff < 0.1 and g_diff < 0.1 and b_diff < 0.1 then
            return true
        end
    end
    
    -- Also check if it's any shade of blue
    if color.B > 0.5 and color.B > color.R and color.B > color.G then
        return true
    end
    
    return false
end

function PianoDetector.isKeyPart(part)
    if not part:IsA("BasePart") then return false end
    
    local name = part.Name
    
    -- Check if it's a named key
    for _, keyName in ipairs(CONSTANTS.KEY_NAMES) do
        if name == keyName then
            return true
        end
    end
    
    return false
end

-- NEW: More aggressive piano search
function PianoDetector.findAllPianos()
    local pianos = {}
    local foundParts = {}
    local checkedCount = 0
    
    Utils.debug("Starting piano search...")
    
    local success = Utils.safeCall(function()
        -- Method 1: Search for any blue parts that look like keys
        for _, obj in ipairs(Workspace:GetDescendants()) do
            checkedCount = checkedCount + 1
            
            if checkedCount > CONSTANTS.MAX_SEARCH_DEPTH then
                Utils.debug("Reached max search depth, stopping search")
                break
            end
            
            if obj:IsA("BasePart") then
                -- Check if it's blue AND has a key name
                local isBlue = PianoDetector.isBlueColor(obj.Color)
                local isKeyName = PianoDetector.isKeyPart(obj)
                
                if isBlue and isKeyName then
                    Utils.debug("Found blue key part:", obj.Name, "Color:", obj.Color)
                    table.insert(foundParts, obj)
                    
                    -- Try to find parent model
                    local parent = obj.Parent
                    if parent and not table.find(pianos, parent) then
                        Utils.debug("Adding parent:", parent.Name, "ClassName:", parent.ClassName)
                        table.insert(pianos, parent)
                    end
                end
            end
        end
        
        Utils.debug("Search complete. Found", #foundParts, "blue key parts")
        Utils.debug("Found", #pianos, "potential piano models")
    end)
    
    if not success then
        warn("[Libra Heart] Error during piano search")
        return {}
    end
    
    -- If no models found but we have parts, use the parts directly
    if #pianos == 0 and #foundParts > 0 then
        Utils.debug("No models found, creating virtual piano from parts")
        
        -- Create a virtual "piano" that's just a collection of the parts
        local virtualPiano = {
            Name = "VirtualPiano",
            Parts = foundParts,
            IsVirtual = true
        }
        
        table.insert(pianos, virtualPiano)
    end
    
    return pianos
end

function PianoDetector.getPianoKeys(pianoModel)
    local keys = {}
    
    Utils.debug("Getting piano keys from:", pianoModel.Name or "Unknown")
    
    -- Handle virtual piano (just parts, no model)
    if pianoModel.IsVirtual then
        Utils.debug("Processing virtual piano")
        for _, part in ipairs(pianoModel.Parts) do
            if Utils.isValidInstance(part) then
                local keyName = part.Name
                if table.find(CONSTANTS.KEY_NAMES, keyName) then
                    keys[keyName] = part
                    Utils.debug("  Found key:", keyName)
                end
            end
        end
        return keys
    end
    
    -- Handle normal model
    if not Utils.isValidModel(pianoModel) then 
        Utils.debug("Invalid piano model")
        return keys 
    end
    
    Utils.safeCall(function()
        for _, obj in ipairs(pianoModel:GetDescendants()) do
            if obj:IsA("BasePart") then
                local keyName = obj.Name
                
                -- Check if it's a key name
                if table.find(CONSTANTS.KEY_NAMES, keyName) and not keys[keyName] then
                    -- Verify it's blue
                    if PianoDetector.isBlueColor(obj.Color) then
                        keys[keyName] = obj
                        Utils.debug("  Found key:", keyName, "at", obj.Position)
                    end
                end
            end
        end
    end)
    
    Utils.debug("Total keys found:", Utils.tableLength(keys))
    
    return keys
end

function Utils.tableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function PianoDetector.findClosestPiano(pianos)
    if #pianos == 0 then return nil end
    if #pianos == 1 then return pianos[1] end
    
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then
        Utils.debug("No character, returning first piano")
        return pianos[1]
    end
    
    local playerPos = LocalPlayer.Character.PrimaryPart.Position
    local closestPiano = nil
    local closestDist = math.huge
    
    for _, piano in ipairs(pianos) do
        local pianoPos
        
        if piano.IsVirtual then
            -- For virtual piano, use first part position
            if piano.Parts[1] then
                pianoPos = piano.Parts[1].Position
            end
        elseif Utils.isValidModel(piano) then
            local success, result = Utils.safeCall(function()
                return piano:GetModelCFrame().Position
            end)
            if success then
                pianoPos = result
            end
        end
        
        if pianoPos then
            local dist = (pianoPos - playerPos).Magnitude
            Utils.debug("Piano distance:", dist)
            if dist < closestDist then
                closestDist = dist
                closestPiano = piano
            end
        end
    end
    
    Utils.debug("Selected closest piano at distance:", closestDist)
    return closestPiano or pianos[1]
end

-- ============================================================================
-- PIANO INTERACTION
-- ============================================================================

local PianoPlayer = {}

function PianoPlayer.clickPianoKey(keyPart)
    if not Utils.isValidInstance(keyPart) then 
        Utils.debug("Invalid key part for clicking")
        return false 
    end
    
    local success = false
    
    -- Try ProximityPrompt
    Utils.safeCall(function()
        for _, child in ipairs(keyPart:GetDescendants()) do
            if child:IsA("ProximityPrompt") then
                fireproximityprompt(child)
                Utils.debug("Fired ProximityPrompt on", keyPart.Name)
                success = true
                return
            end
        end
        
        local proximityPrompt = keyPart:FindFirstChildOfClass("ProximityPrompt")
        if proximityPrompt then
            fireproximityprompt(proximityPrompt)
            Utils.debug("Fired ProximityPrompt (FindFirst) on", keyPart.Name)
            success = true
            return
        end
    end)
    
    if success then return true end
    
    -- Try ClickDetector
    Utils.safeCall(function()
        for _, child in ipairs(keyPart:GetDescendants()) do
            if child:IsA("ClickDetector") then
                fireclickdetector(child)
                Utils.debug("Fired ClickDetector on", keyPart.Name)
                success = true
                return
            end
        end
        
        local clickDetector = keyPart:FindFirstChildOfClass("ClickDetector")
        if clickDetector then
            fireclickdetector(clickDetector)
            Utils.debug("Fired ClickDetector (FindFirst) on", keyPart.Name)
            success = true
        end
    end)
    
    if not success then
        Utils.debug("No interaction method found for", keyPart.Name)
    end
    
    return success
end

function PianoPlayer.positionCameraAtPiano(pianoModel, keyPart)
    if not Settings.autoFocusCamera then return end
    
    Utils.safeCall(function()
        local targetPos
        
        if keyPart and Utils.isValidInstance(keyPart) then
            targetPos = keyPart.Position
        elseif pianoModel then
            if pianoModel.IsVirtual and pianoModel.Parts[1] then
                targetPos = pianoModel.Parts[1].Position
            elseif Utils.isValidModel(pianoModel) then
                targetPos = pianoModel:GetModelCFrame().Position
            end
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
        local pianoPos
        
        if pianoModel.IsVirtual and pianoModel.Parts[1] then
            pianoPos = pianoModel.Parts[1].Position
        elseif Utils.isValidModel(pianoModel) then
            pianoPos = pianoModel:GetModelCFrame().Position
        end
        
        if pianoPos then
            local teleportPos = pianoPos + CONSTANTS.TELEPORT_OFFSET
            LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(teleportPos))
        end
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
            else
                Utils.debug("Key not found or invalid:", noteName)
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
    if not Utils.acquireMutex() then
        return
    end
    
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
    if not Utils.acquireMutex() then
        Utils.debug("Could not acquire mutex")
        return
    end
    
    if State.autoPlayThread then
        task.cancel(State.autoPlayThread)
    end
    
    State.autoPlayThread = task.spawn(function()
        State.isPlaying = true
        
        Utils.debug("Starting piano search...")
        State.foundPianos = PianoDetector.findAllPianos()
        
        Utils.debug("Pianos found:", #State.foundPianos)
        
        if #State.foundPianos == 0 then
            NotificationManager.show("error", "Piano Not Found", 
                "No blue piano detected!\n\nMake sure:\n• Piano is spawned\n• Keys are BLUE colored\n• Keys are named C, D, E, F, G, A, B (with # for sharps)")
            PlaybackController.stop()
            Utils.releaseMutex()
            return
        end
        
        State.currentPianoModel = PianoDetector.findClosestPiano(State.foundPianos)
        
        if not State.currentPianoModel then
            NotificationManager.show("error", "Piano Selection Failed", 
                "Could not select a piano")
            PlaybackController.stop()
            Utils.releaseMutex()
            return
        end
        
        Utils.debug("Selected piano:", State.currentPianoModel.Name or "VirtualPiano")
        
        State.pianoKeys = PianoDetector.getPianoKeys(State.currentPianoModel)
        
        local keyCount = Utils.tableLength(State.pianoKeys)
        Utils.debug("Keys detected:", keyCount)
        
        if keyCount == 0 then
            NotificationManager.show("error", "No Keys Found", 
                "Piano has no detectable keys!\n\nCheck that:\n• Keys are BLUE\n• Keys are named correctly (C, D#, etc.)")
            PlaybackController.stop()
            Utils.releaseMutex()
            return
        end
        
        -- List found keys
        local keyList = {}
        for keyName, _ in pairs(State.pianoKeys) do
            table.insert(keyList, keyName)
        end
        table.sort(keyList)
        Utils.debug("Available keys:", table.concat(keyList, ", "))
        
        NotificationManager.show("success", "Libra Heart", 
            string.format("Found %d keys! Starting playback...", keyCount))
        
        if Settings.teleportToPiano then
            PianoPlayer.teleportToPiano(State.currentPianoModel)
            task.wait(CONSTANTS.TELEPORT_WAIT_TIME)
        end
        
        PianoPlayer.positionCameraAtPiano(State.currentPianoModel, nil)
        
        Utils.releaseMutex()
        
        while Settings.autoPlayEnabled and State.isPlaying do
            local success = Utils.safeCall(function()
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
            
            if not success then
                warn("[Libra Heart] Playback error occurred")
                break
            end
            
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
        Name = "🎹 Libra Heart - Auto Piano v2.1",
        LoadingTitle = "Libra Heart Loading...",
        LoadingSubtitle = "by imaizumiyui | Fixed Detection",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "LibraHeartPianoConfig",
            FileName = "PianoSettings"
        },
        Discord = {
            Enabled = false,
            Invite = "noinvitelink",
            RememberJoins = true
        },
        KeySystem = false
    })
    
    local MainTab = Window:CreateTab("🎵 Libra Heart", CONSTANTS.RAYFIELD_IMAGE)
    local SettingsTab = Window:CreateTab("⚙️ Settings", CONSTANTS.RAYFIELD_IMAGE)
    local DebugTab = Window:CreateTab("🔧 Debug", CONSTANTS.RAYFIELD_IMAGE)
    local InfoTab = Window:CreateTab("ℹ️ Info", CONSTANTS.RAYFIELD_IMAGE)
    
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
    MainTab:CreateLabel("Complete melody - Fixed detection!")
    
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
    
    MainTab:CreateSection("Manual Controls")
    
    local FindPianoButton = Utils.debounce(function()
        Utils.debug("Manual piano search initiated")
        State.foundPianos = PianoDetector.findAllPianos()
        
        if #State.foundPianos > 0 then
            -- Get key count from first piano
            local testKeys = PianoDetector.getPianoKeys(State.foundPianos[1])
            local keyCount = Utils.tableLength(testKeys)
            
            NotificationManager.show("success", "Pianos Found!", 
                string.format("Found %d piano(s) with %d keys", #State.foundPianos, keyCount))
        else
            NotificationManager.show("error", "No Pianos", 
                "No blue pianofound!\n\nTroubleshooting:\n• Check if piano is BLUE\n• Verify key names (C, D, E, F, G, A, B)\n• Use Debug tab for more info", 
                CONSTANTS.NOTIFICATION_DURATION_LONG)
        end
    end, 1)
    
    MainTab:CreateButton({
        Name = "🔍 Find Pianos",
        Callback = FindPianoButton
    })
    
    local TeleportNowButton = Utils.debounce(function()
        if State.currentPianoModel then
            local success = PianoPlayer.teleportToPiano(State.currentPianoModel)
            if success then
                NotificationManager.show("success", "Teleported", 
                    "Moved to piano", CONSTANTS.NOTIFICATION_DURATION_SHORT)
            else
                NotificationManager.show("error", "Teleport Failed", 
                    "Could not teleport to piano")
            end
        else
            NotificationManager.show("error", "No Piano Selected", 
                "Please use 'Find Pianos' first")
        end
    end, 2)
    
    MainTab:CreateButton({
        Name = "🎹 Teleport Now",
        Callback = TeleportNowButton
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
    
    -- Debug Tab
    DebugTab:CreateSection("🔧 Troubleshooting Tools")
    
    DebugTab:CreateToggle({
        Name = "Enable Debug Mode",
        CurrentValue = true,
        Flag = "DebugModeToggle",
        Callback = function(Value)
            State.debugMode = Value
            Utils.debug("Debug mode:", Value and "Enabled" or "Disabled")
        end
    })
    
    DebugTab:CreateButton({
        Name = "🔍 Search All Blue Parts",
        Callback = function()
            local bluePartCount = 0
            local keyPartCount = 0
            
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    if PianoDetector.isBlueColor(obj.Color) then
                        bluePartCount = bluePartCount + 1
                        Utils.debug("Blue part:", obj:GetFullName(), "Color:", obj.Color)
                        
                        if PianoDetector.isKeyPart(obj) then
                            keyPartCount = keyPartCount + 1
                            Utils.debug("  ^ This is a KEY!")
                        end
                    end
                end
            end
            
            NotificationManager.show("info", "Search Complete", 
                string.format("Found %d blue parts\n%d are piano keys", bluePartCount, keyPartCount))
        end
    })
    
    DebugTab:CreateButton({
        Name = "📋 List Current Keys",
        Callback = function()
            if State.currentPianoModel then
                local keys = PianoDetector.getPianoKeys(State.currentPianoModel)
                local keyList = {}
                
                for keyName, keyPart in pairs(keys) do
                    table.insert(keyList, keyName)
                    Utils.debug(keyName, "->", keyPart:GetFullName())
                end
                
                table.sort(keyList)
                
                if #keyList > 0 then
                    NotificationManager.show("info", "Available Keys", 
                        string.format("%d keys:\n%s", #keyList, table.concat(keyList, ", ")))
                else
                    NotificationManager.show("warning", "No Keys", 
                        "Current piano has no detectable keys")
                end
            else
                NotificationManager.show("error", "No Piano", 
                    "Use 'Find Pianos' first")
            end
        end
    })
    
    DebugTab:CreateButton({
        Name = "🎹 Test Single Key (C)",
        Callback = function()
            if State.pianoKeys and State.pianoKeys["C"] then
                Utils.debug("Testing key C")
                local success = PianoPlayer.clickPianoKey(State.pianoKeys["C"])
                
                if success then
                    NotificationManager.show("success", "Key Test", 
                        "Key C clicked successfully!")
                else
                    NotificationManager.show("error", "Key Test Failed", 
                        "Could not click key C")
                end
            else
                NotificationManager.show("error", "Key Not Found", 
                    "Key C not available in current piano")
            end
        end
    })
    
    DebugTab:CreateButton({
        Name = "📊 Show Piano Info",
        Callback = function()
            if State.currentPianoModel then
                local info = string.format(
                    "Piano: %s\nType: %s\nKeys: %d\nPlaying: %s",
                    State.currentPianoModel.Name or "VirtualPiano",
                    State.currentPianoModel.IsVirtual and "Virtual" or "Model",
                    Utils.tableLength(State.pianoKeys),
                    State.isPlaying and "Yes" or "No"
                )
                
                Utils.debug("=== Piano Info ===")
                Utils.debug(info)
                
                NotificationManager.show("info", "Piano Info", info)
            else
                NotificationManager.show("error", "No Piano", 
                    "No piano selected yet")
            end
        end
    })
    
    DebugTab:CreateSection("📝 Console Output")
    
    DebugTab:CreateLabel("Check F9 console for detailed debug info")
    DebugTab:CreateLabel("All debug messages are prefixed with:")
    DebugTab:CreateLabel("[Libra Heart Debug]")
    
    -- Info Tab
    InfoTab:CreateSection("🎵 Song Information")
    
    InfoTab:CreateParagraph({
        Title = "Libra Heart",
        Content = "Artist: imaizumiyui\nKey: C#m (D#, B, C#, F#)\n\nComplete melody includes:\n• Intro\n• Verse A\n• Chorus (Main melody)\n• Bridge\n• Outro"
    })
    
    InfoTab:CreateSection("📖 How to Use")
    
    InfoTab:CreateParagraph({
        Title = "Step 1: Spawn Piano",
        Content = "In 'Fling Things and People', spawn a BLUE piano. The keys must be blue colored!"
    })
    
    InfoTab:CreateParagraph({
        Title = "Step 2: Find Piano",
        Content = "Click 'Find Pianos' button in Main tab. Check Debug tab if not found."
    })
    
    InfoTab:CreateParagraph({
        Title = "Step 3: Play!",
        Content = "Toggle 'Play Libra Heart' on and enjoy!"
    })
    
    InfoTab:CreateSection("⚠️ Troubleshooting")
    
    InfoTab:CreateParagraph({
        Title = "Piano Not Found?",
        Content = "• Make sure piano keys are BLUE\n• Keys should be named: C, C#, D, D#, E, F, F#, G, G#, A, A#, B\n• Use Debug tab to search for blue parts\n• Try spawning a different piano"
    })
    
    InfoTab:CreateParagraph({
        Title = "No Sound?",
        Content = "• Check if executor supports fireproximityprompt\n• Some pianos may not work\n• Try testing a single key in Debug tab"
    })
    
    InfoTab:CreateSection("ℹ️ Script Information")
    
    InfoTab:CreateLabel("Libra Heart Auto Piano v2.1")
    InfoTab:CreateLabel("For: Fling Things and People")
    InfoTab:CreateLabel("")
    InfoTab:CreateLabel("✓ Fixed piano detection")
    InfoTab:CreateLabel("✓ Enhanced blue color detection")
    InfoTab:CreateLabel("✓ Virtual piano support")
    InfoTab:CreateLabel("✓ Debug tools included")
    InfoTab:CreateLabel("✓ Complete error handling")
    InfoTab:CreateLabel("✓ Performance optimized")
    
    InfoTab:CreateSection("🔧 Version 2.1 Changes")
    
    InfoTab:CreateParagraph({
        Title = "Detection Improvements",
        Content = "• More aggressive blue color matching\n• Support for color variations\n• Virtual piano system\n• Better parent model detection\n• Enhanced debug logging"
    })
    
    InfoTab:CreateSection("📝 GitHub & Support")
    
    InfoTab:CreateParagraph({
        Title = "Repository",
        Content = "github.com/yourusername/libra-heart-piano\n\nUse Debug tab to troubleshoot!\nCheck F9 console for detailed logs."
    })
    
    return Window
end

-- ============================================================================
-- ERROR RECOVERY
-- ============================================================================

local function setupErrorRecovery()
    -- Handle workspace changes
    Workspace.DescendantRemoving:Connect(function(descendant)
        if descendant == State.currentPianoModel then
            warn("[Libra Heart] Current piano removed from workspace")
            if Settings.autoPlayEnabled then
                NotificationManager.show("warning", "Piano Removed", 
                    "Current piano was removed. Stopping playback...")
                PlaybackController.stop()
            end
        end
    end)
    
    -- Handle character respawn
    if LocalPlayer.Character then
        LocalPlayer.Character:GetPropertyChangedSignal("Parent"):Connect(function()
            if not LocalPlayer.Character.Parent and Settings.autoPlayEnabled then
                warn("[Libra Heart] Character removed, pausing playback")
                local wasEnabled = Settings.autoPlayEnabled
                PlaybackController.stop()
                
                task.spawn(function()
                    LocalPlayer.CharacterAdded:Wait()
                    task.wait(2)
                    if wasEnabled then
                        NotificationManager.show("info", "Auto-Resume", 
                            "Resuming playback after respawn...")
                        Settings.autoPlayEnabled = true
                        PlaybackController.start()
                    end
                end)
            end
        end)
    end
    
    LocalPlayer.CharacterAdded:Connect(function(character)
        character:GetPropertyChangedSignal("Parent"):Connect(function()
            if not character.Parent and Settings.autoPlayEnabled then
                PlaybackController.stop()
            end
        end)
    end)
end

-- ============================================================================
-- PERFORMANCE MONITORING
-- ============================================================================

local PerformanceMonitor = {}

function PerformanceMonitor.start()
    local startTime = tick()
    local frameCount = 0
    local lastReport = startTime
    
    local connection = RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()
        
        if currentTime - lastReport >= 60 then
            local fps = frameCount / (currentTime - lastReport)
            local memoryUsage = gcinfo()
            
            Utils.debug(string.format("Performance - FPS: %.1f, Memory: %.2f MB", 
                fps, memoryUsage / 1024))
            
            frameCount = 0
            lastReport = currentTime
            
            if fps < 30 then
                warn("[Libra Heart] Low FPS detected, consider reducing play speed")
            end
            
            if memoryUsage > 500000 then
                warn("[Libra Heart] High memory usage detected")
                collectgarbage("collect")
            end
        end
    end)
    
    Utils.registerCleanup(function()
        connection:Disconnect()
    end)
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
    
    State.rayfieldWindow = result
    
    NotificationManager.show("success", "Libra Heart v2.1", 
        "Loaded with improved detection!", 
        CONSTANTS.NOTIFICATION_DURATION_LONG)
    
    -- Auto-find pianos after delay
    task.spawn(function()
        task.wait(CONSTANTS.INITIAL_SEARCH_DELAY)
        
        Utils.debug("Running automatic piano search...")
        State.foundPianos = PianoDetector.findAllPianos()
        
        if #State.foundPianos > 0 then
            local keys = PianoDetector.getPianoKeys(State.foundPianos[1])
            local keyCount = Utils.tableLength(keys)
            
            NotificationManager.show("info", "Auto-Detection", 
                string.format("Found %d piano(s) with %d keys!", #State.foundPianos, keyCount))
        else
            NotificationManager.show("info", "No Pianos Yet", 
                "Spawn a blue piano, then click 'Find Pianos'", 
                CONSTANTS.NOTIFICATION_DURATION_LONG)
        end
    end)
    
    Utils.registerCleanup(function()
        PlaybackController.stop()
        PianoPlayer.restoreCamera()
    end)
    
    print("[Libra Heart] Initialization complete!")
    return true
end

-- ============================================================================
-- MAIN EXECUTION
-- ============================================================================

local function main()
    print("=" .. string.rep("=", 78))
    print("  Libra Heart Auto Piano Player v2.1")
    print("  For: Fling Things and People")
    print("  Song: Libra Heart by imaizumiyui")
    print("  FIXED: Enhanced Piano Detection")
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
        
        setupErrorRecovery()
        PerformanceMonitor.start()
    end)
    
    if not success then
        warn("[Libra Heart] Fatal error during initialization:", error)
        NotificationManager.show("error", "Initialization Failed", 
            "Script failed to start. Check console for details.")
        return
    end
    
    print("[Libra Heart] Ready to play Libra Heart")
    print("[Libra Heart] Debug mode enabled - check F9 console")
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

local scriptConnection = game:GetService("ScriptContext").Error:Connect(function(message, trace)
    if string.find(trace, "Libra Heart") then
        warn("[Libra Heart] Error detected:", message)
        PlaybackController.stop()
    end
end)

Utils.registerCleanup(function()
    scriptConnection:Disconnect()
end)

-- ============================================================================
-- EXECUTE MAIN
-- ============================================================================

local mainSuccess, mainError = pcall(main)

if not mainSuccess then
    warn("[Libra Heart] Critical error:", mainError)
    warn("[Libra Heart] Please report this error on GitHub")
    
    if Rayfield then
        pcall(function()
            Rayfield:Notify({
                Title = "❌ Critical Error",
                Content = "Script failed to load. Check console (F9) for details.",
                Duration = 10,
                Image = CONSTANTS.RAYFIELD_IMAGE
            })
        end)
    end
end

print("[Libra Heart] Script loaded. Use Debug tab if piano not found!")

--[[
    ============================================================================
    VERSION 2.1.0 - DETECTION FIX CHANGELOG
    ============================================================================
    
    [FIXED - Piano Detection]
    ✅ Enhanced blue color detection with tolerance
    ✅ Added support for multiple shades of blue
    ✅ Virtual piano system for loose parts
    ✅ Better parent model detection
    ✅ Increased search reliability
    
    [ADDED - Debug Features]
    ✅ New Debug tab with troubleshooting tools
    ✅ "Search All Blue Parts" button
    ✅ "List Current Keys" functionality
    ✅ "Test Single Key" feature
    ✅ "Show Piano Info" display
    ✅ Enhanced console logging with Utils.debug()
    
    [IMPROVED]
    ✅ Color matching algorithm (RGB tolerance)
    ✅ Any blue shade detection (B > R and B > G)
    ✅ Better error messages with solutions
    ✅ More informative notifications
    ✅ Key detection logging
    
    [USAGE TIPS]
    • Enable Debug Mode in Debug tab
    • Check F9 console for detailed logs
    • Use "Search All Blue Parts" to verify piano
    • Test individual keys before full playback
    • If still not working, piano may not be compatible
    
    ============================================================================
    FLING THINGS AND PEOPLE - PIANO REQUIREMENTS
    ============================================================================
    
    For this script to work, the piano MUST have:
    
    1. BLUE colored keys (any shade of blue)
    2. Keys named exactly as: C, C#, D, D#, E, F, F#, G, G#, A, A#, B
    3. ProximityPrompt or ClickDetector on each key
    
    If piano still not detected:
    • Try Debug tab -> "Search All Blue Parts"
    • Check if any blue parts are found
    • Verify key naming in Debug output
    • Some custom pianos may not be compatible
    
    ============================================================================
]]
