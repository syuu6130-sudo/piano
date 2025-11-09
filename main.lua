--[[
    Auto Piano Player for "Fling Things and People"
    Libra Heart by imaizumiyui - 既存ピアノ対応版
    
    おもちゃメニューから青いピアノをスポーンして使用
    
    Version: 3.1.0
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
        print("[Libra Heart] Rayfield UI loaded")
    else
        warn("[Libra Heart] Failed to load Rayfield UI:", result)
        return
    end
end

if not RayfieldLoadSuccess or not Rayfield then
    error("[Libra Heart] Rayfield UI library failed to load")
    return
end

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local CONSTANTS = {
    DEFAULT_CLICK_DELAY = 0.08,
    DEFAULT_NOTE_GAP = 0.05,
    DEFAULT_LOOP_DELAY = 3,
    DEFAULT_PLAY_SPEED = 1.0,
    MIN_PLAY_SPEED = 0.5,
    MAX_PLAY_SPEED = 2.0,
    
    CAMERA_OFFSET = Vector3.new(0, 5, 10),
    TELEPORT_OFFSET = Vector3.new(0, 3, 8),
    TELEPORT_WAIT_TIME = 0.5,
    
    KEY_NAMES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"},
    
    SECTION_DELAY = 0.3,
    FINAL_DELAY = 0.5,
    
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
    mutex = false
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
        {"B", 0.4}, {"A#", 0.4}, {"G#", 0.6}, {"rest", 0.2},
        {"C#", 0.3}, {"D#", 0.3}, {"F#", 0.5}, {"F#", 0.3},
        {"G#", 0.3}, {"A#", 0.3}, {"B", 0.5}, {"rest", 0.2},
        {"B", 0.3}, {"A#", 0.3}, {"G#", 0.5}, {"F#", 0.3},
        {"D#", 0.4}, {"F#", 0.4}, {"G#", 0.8}
    },
    Chorus = {
        {"B", 0.4}, {"B", 0.3}, {"A#", 0.3}, {"G#", 0.4},
        {"F#", 0.3}, {"G#", 0.3}, {"F#", 0.4}, {"D#", 0.4}, {"rest", 0.2},
        {"D#", 0.3}, {"F#", 0.3}, {"G#", 0.4}, {"A#", 0.4},
        {"B", 0.4}, {"B", 0.4}, {"A#", 0.6}, {"rest", 0.2},
        {"B", 0.4}, {"B", 0.3}, {"C#", 0.3}, {"D#", 0.4},
        {"F#", 0.4}, {"G#", 0.4}, {"F#", 0.4}, {"D#", 0.4}, {"rest", 0.2},
        {"F#", 0.3}, {"G#", 0.3}, {"A#", 0.4}, {"B", 0.4},
        {"A#", 0.4}, {"G#", 0.4}, {"F#", 0.8}
    },
    Bridge = {
        {"D#", 0.4}, {"D#", 0.4}, {"F#", 0.4}, {"G#", 0.4},
        {"A#", 0.4}, {"B", 0.4}, {"A#", 0.4}, {"G#", 0.4}, {"rest", 0.2},
        {"F#", 0.3}, {"F#", 0.3}, {"G#", 0.4}, {"A#", 0.4},
        {"B", 0.4}, {"C#", 0.4}, {"D#", 0.8}, {"rest", 0.3}
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
-- PIANO DETECTION - 改善版
-- ============================================================================

local PianoDetector = {}

function PianoDetector.findYamaRolanSioPiano()
    local foundPiano = nil
    
    print("[Libra Heart] Searching for YamaRolanSio piano...")
    
    Utils.safeCall(function()
        -- Workspaceの全オブジェクトを検索
        for _, obj in ipairs(Workspace:GetDescendants()) do
            -- YamaRolanSioのピアノを名前で検索
            if obj:IsA("Model") then
                local modelName = obj.Name:lower()
                
                -- ピアノに関連する名前をチェック
                if modelName:find("piano") or modelName:find("yamarolansi") or modelName:find("keyboard") then
                    print("[Libra Heart] Found potential piano model:", obj.Name)
                    
                    -- 中にキーがあるか確認
                    local hasKeys = false
                    for _, child in ipairs(obj:GetDescendants()) do
                        if child:IsA("BasePart") then
                            for _, keyName in ipairs(CONSTANTS.KEY_NAMES) do
                                if child.Name == keyName then
                                    hasKeys = true
                                    print("[Libra Heart] Confirmed: Found key", keyName, "in", obj.Name)
                                    foundPiano = obj
                                    return
                                end
                            end
                        end
                    end
                end
            end
            
            -- パーツの名前がキー名と一致する場合、その親を探す
            if obj:IsA("BasePart") then
                for _, keyName in ipairs(CONSTANTS.KEY_NAMES) do
                    if obj.Name == keyName then
                        print("[Libra Heart] Found key part:", keyName)
                        
                        -- 親のModelを探す
                        local parent = obj.Parent
                        while parent and parent ~= Workspace do
                            if parent:IsA("Model") then
                                print("[Libra Heart] Found parent model:", parent.Name)
                                foundPiano = parent
                                return
                            end
                            parent = parent.Parent
                        end
                    end
                end
            end
        end
    end)
    
    if foundPiano then
        print("[Libra Heart] Piano found:", foundPiano.Name)
    else
        print("[Libra Heart] No piano found")
    end
    
    return foundPiano
end

function PianoDetector.findAllPianos()
    local piano = PianoDetector.findYamaRolanSioPiano()
    
    if piano then
        return {piano}
    else
        return {}
    end
end

function PianoDetector.getPianoKeys(pianoModel)
    local keys = {}
    
    if not pianoModel or not pianoModel.Parent then
        return keys
    end
    
    print("[Libra Heart] Getting keys from:", pianoModel.Name)
    
    Utils.safeCall(function()
        for _, obj in ipairs(pianoModel:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = obj.Name
                
                -- 正確なキー名マッチング
                for _, keyName in ipairs(CONSTANTS.KEY_NAMES) do
                    if name == keyName then
                        if not keys[keyName] then
                            keys[keyName] = obj
                            print("[Libra Heart] Found key:", keyName, "at", obj:GetFullName())
                            
                            -- ClickDetectorまたはProximityPromptがあるか確認
                            local hasInteraction = obj:FindFirstChildOfClass("ClickDetector") or obj:FindFirstChildOfClass("ProximityPrompt")
                            if hasInteraction then
                                print("[Libra Heart] Key has interaction:", keyName)
                            else
                                print("[Libra Heart] WARNING: Key has no interaction:", keyName)
                            end
                        end
                        break
                    end
                end
            end
        end
    end)
    
    local keyCount = 0
    for k, v in pairs(keys) do 
        keyCount = keyCount + 1
        print("[Libra Heart] Key registered:", k)
    end
    print("[Libra Heart] Total keys found:", keyCount)
    
    return keys
end

function PianoDetector.findClosestPiano(pianos)
    if #pianos == 0 then return nil end
    if #pianos == 1 then return pianos[1] end
    
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then
        return pianos[1]
    end
    
    local playerPos = LocalPlayer.Character.PrimaryPart.Position
    local closestPiano = nil
    local closestDist = math.huge
    
    for _, piano in ipairs(pianos) do
        local success, pianoPos = Utils.safeCall(function()
            return piano:GetModelCFrame().Position
        end)
        
        if success and pianoPos then
            local dist = (pianoPos - playerPos).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestPiano = piano
            end
        end
    end
    
    return closestPiano or pianos[1]
end

-- ============================================================================
-- PIANO INTERACTION
-- ============================================================================

local PianoPlayer = {}

function PianoPlayer.clickPianoKey(keyPart)
    if not Utils.isValidInstance(keyPart) then
        return false
    end
    
    local success = false
    
    -- ClickDetector
    Utils.safeCall(function()
        local clickDetector = keyPart:FindFirstChildOfClass("ClickDetector")
        if clickDetector then
            fireclickdetector(clickDetector)
            success = true
        end
    end)
    
    if success then return true end
    
    -- ProximityPrompt
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
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CFrame = CFrame.new(targetPos + CONSTANTS.CAMERA_OFFSET, targetPos)
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
        
        local pianos = PianoDetector.findAllPianos()
        
        if #pianos == 0 then
            NotificationManager.show("error", "ピアノが見つかりません", 
                "おもちゃメニューから青いピアノをスポーンしてください！", 
                CONSTANTS.NOTIFICATION_DURATION_LONG)
            PlaybackController.stop()
            Utils.releaseMutex()
            return
        end
        
        State.currentPianoModel = PianoDetector.findClosestPiano(pianos)
        
        if not State.currentPianoModel then
            NotificationManager.show("error", "Piano Selection Failed", 
                "ピアノを選択できませんでした")
            PlaybackController.stop()
            Utils.releaseMutex()
            return
        end
        
        State.pianoKeys = PianoDetector.getPianoKeys(State.currentPianoModel)
        
        local keyCount = 0
        for _ in pairs(State.pianoKeys) do keyCount = keyCount + 1 end
        
        if keyCount == 0 then
            NotificationManager.show("error", "キーが見つかりません", 
                "ピアノに青いキーが検出されませんでした")
            PlaybackController.stop()
            Utils.releaseMutex()
            return
        end
        
        NotificationManager.show("success", "Libra Heart", 
            string.format("%d個のキーを検出！演奏開始...", keyCount))
        
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
    local Window = Rayfield:CreateWindow({
        Name = "🎹 Libra Heart - Auto Piano v3.1",
        LoadingTitle = "Libra Heart 読み込み中...",
        LoadingSubtitle = "by imaizumiyui | 既存ピアノ対応",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "LibraHeartPianoConfig",
            FileName = "PianoSettings"
        },
        Discord = {Enabled = false},
        KeySystem = false
    })
    
    local MainTab = Window:CreateTab("🎵 Libra Heart", CONSTANTS.RAYFIELD_IMAGE)
    local SettingsTab = Window:CreateTab("⚙️ 設定", CONSTANTS.RAYFIELD_IMAGE)
    local InfoTab = Window:CreateTab("ℹ️ 情報", CONSTANTS.RAYFIELD_IMAGE)
    
    -- Main Tab
    MainTab:CreateSection("🎹 再生コントロール")
    
    MainTab:CreateToggle({
        Name = "🎹 Libra Heart を演奏",
        CurrentValue = false,
        Flag = "AutoPlayToggle",
        Callback = function(Value)
            Settings.autoPlayEnabled = Value
            if Value then
                PlaybackController.start()
            else
                PlaybackController.stop()
                NotificationManager.show("info", "停止", 
                    "演奏を停止しました", CONSTANTS.NOTIFICATION_DURATION_SHORT)
            end
        end
    })
    
    MainTab:CreateLabel("曲: Libra Heart by imaizumiyui")
    MainTab:CreateLabel("完全版メロディー")
    
    MainTab:CreateSection("📹 カメラ設定")
    
    MainTab:CreateToggle({
        Name = "📹 自動カメラ追従",
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
        Name = "🚀 ピアノへテレポート",
        CurrentValue = false,
        Flag = "TeleportToggle",
        Callback = function(Value)
            Settings.teleportToPiano = Value
        end
    })
    
    MainTab:CreateSection("🔍 手動操作")
    
    MainTab:CreateButton({
        Name = "🔍 ピアノを検索",
        Callback = function()
            local pianos = PianoDetector.findAllPianos()
            
            if #pianos > 0 then
                local testKeys = PianoDetector.getPianoKeys(pianos[1])
                local keyCount = 0
                for _ in pairs(testKeys) do keyCount = keyCount + 1 end
                
                NotificationManager.show("success", "ピアノ発見！", 
                    string.format("%d台のピアノ、%d個のキーを検出", #pianos, keyCount))
            else
                NotificationManager.show("error", "ピアノなし", 
                    "おもちゃメニューから青いピアノをスポーンしてください", 
                    CONSTANTS.NOTIFICATION_DURATION_LONG)
            end
        end
    })
    
    -- Settings Tab
    SettingsTab:CreateSection("⏱️ タイミング設定")
    
    SettingsTab:CreateSlider({
        Name = "再生速度",
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
        Name = "クリック遅延",
        Range = {0.01, 0.3},
        Increment = 0.01,
        Suffix = "秒",
        CurrentValue = CONSTANTS.DEFAULT_CLICK_DELAY,
        Flag = "ClickDelaySlider",
        Callback = function(Value)
            Settings.clickDelay = Value
        end
    })
    
    SettingsTab:CreateSlider({
        Name = "音符間隔",
        Range = {0.01, 0.5},
        Increment = 0.01,
        Suffix = "秒",
        CurrentValue = CONSTANTS.DEFAULT_NOTE_GAP,
        Flag = "NoteGapSlider",
        Callback = function(Value)
            Settings.noteGap = Value
        end
    })
    
    SettingsTab:CreateSlider({
        Name = "ループ遅延",
        Range = {1, 20},
        Increment = 1,
        Suffix = "秒",
        CurrentValue = CONSTANTS.DEFAULT_LOOP_DELAY,
        Flag = "LoopDelaySlider",
        Callback = function(Value)
            Settings.loopDelay = Value
        end
    })
    
    -- Info Tab
    InfoTab:CreateSection("🎵 曲情報")
    
    InfoTab:CreateParagraph({
        Title = "Libra Heart",
        Content = "アーティスト: imaizumiyui\nキー: C#m\n\n含まれるパート:\n• イントロ\n• Verse A\n• コーラス\n• ブリッジ\n• アウトロ"
    })
    
    InfoTab:CreateSection("📖 使い方")
    
    InfoTab:CreateParagraph({
        Title = "ステップ1: ピアノをスポーン",
        Content = "Fling Things and Peopleの「おもちゃ」メニューから青いピアノをスポーンしてください"
    })
    
    InfoTab:CreateParagraph({
        Title = "ステップ2: 演奏開始",
        Content = "「Libra Heartを演奏」トグルをONにして、音楽を楽しんでください！"
    })
    
    InfoTab:CreateSection("ℹ️ バージョン情報")
    
    InfoTab:CreateLabel("Libra Heart Auto Piano v3.1")
    InfoTab:CreateLabel("✓ 既存の青いピアノに対応")
    InfoTab:CreateLabel("✓ 改善された検出機能")
    InfoTab:CreateLabel("✓ おもちゃメニューから使用")
    InfoTab:CreateLabel("✓ Rayfield UI")
    
    return Window
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function initialize()
    print("[Libra Heart] 初期化開始...")
    
    State.originalCameraType = Camera.CameraType
    
    local success, result = Utils.safeCall(createGUI)
    
    if not success then
        warn("[Libra Heart] GUI作成失敗:", result)
        return false
    end
    
    NotificationManager.show("success", "Libra Heart v3.1", 
        "準備完了！おもちゃメニューから青いピアノをスポーンしてください", 
        CONSTANTS.NOTIFICATION_DURATION_LONG)
    
    Utils.registerCleanup(function()
        PlaybackController.stop()
        PianoPlayer.restoreCamera()
    end)
    
    print("[Libra Heart] 初期化完了！")
    return true
end

-- ============================================================================
-- MAIN EXECUTION
-- ============================================================================

local function main()
    print("=" .. string.rep("=", 78))
    print("  Libra Heart Auto Piano Player v3.1")
    print("  Song: Libra Heart by imaizumiyui")
    print("  おもちゃメニューの青いピアノに対応")
    print("=" .. string.rep("=", 78))
    
    if not RayfieldLoadSuccess or not Rayfield then
        error("[Libra Heart] Rayfield UI読み込み失敗")
        return
    end
    
    local success = Utils.safeCall(function()
        return initialize()
    end)
    
    if not success then
        warn("[Libra Heart] 初期化エラー")
        NotificationManager.show("error", "初期化失敗", 
            "スクリプトの起動に失敗しました")
        return
    end
    
    print("[Libra Heart] 準備完了！")
    print("=" .. string.rep("=", 78))
end

-- Execute
pcall(main)

print("[Libra Heart] スクリプト読み込み完了！")
