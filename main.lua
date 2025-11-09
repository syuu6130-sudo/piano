--[[
    Auto Piano Player for "Fling Things and People"
    Libra Heart by imaizumiyui - Complete Version
    
    Features:
    - Finds blue piano automatically
    - Plays Libra Heart melody
    - Camera auto-positioning
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "🎹 Libra Heart - Auto Piano",
   LoadingTitle = "Libra Heart 読み込み中...",
   LoadingSubtitle = "by imaizumiyui",
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

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Settings
local Settings = {
    AutoPlayEnabled = false,
    AutoFocusCamera = true,
    ClickDelay = 0.08,
    NoteGap = 0.05,
    LoopDelay = 3,
    TeleportToPiano = false,
    PlaySpeed = 1.0  -- 再生速度調整（1.0 = 通常速度）
}

-- Libra Heart Complete Melody
-- Based on C#m key (D#, B, C#, F# chord progression)
local LibraHeartSong = {
    Name = "Libra Heart - imaizumiyui",
    -- イントロ
    Intro = {
        {"D#", 0.4}, {"F#", 0.4}, {"G#", 0.4}, {"A#", 0.4},
        {"G#", 0.4}, {"F#", 0.4}, {"D#", 0.6}, {"rest", 0.2},
        {"D#", 0.4}, {"F#", 0.4}, {"G#", 0.4}, {"B", 0.4},
        {"A#", 0.4}, {"G#", 0.4}, {"F#", 0.8}
    },
    -- Aメロ（サビ前）
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
    -- サビ（メインメロディ）
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
    -- ブリッジ
    Bridge = {
        {"D#", 0.4}, {"D#", 0.4}, {"F#", 0.4}, {"G#", 0.4},
        {"A#", 0.4}, {"B", 0.4}, {"A#", 0.4}, {"G#", 0.4},
        {"rest", 0.2},
        {"F#", 0.3}, {"F#", 0.3}, {"G#", 0.4}, {"A#", 0.4},
        {"B", 0.4}, {"C#", 0.4}, {"D#", 0.8},
        {"rest", 0.3}
    },
    -- アウトロ
    Outro = {
        {"B", 0.4}, {"A#", 0.4}, {"G#", 0.4}, {"F#", 0.4},
        {"G#", 0.4}, {"F#", 0.4}, {"D#", 0.6}, {"rest", 0.2},
        {"D#", 0.4}, {"F#", 0.4}, {"G#", 0.4}, {"B", 0.4},
        {"A#", 0.6}, {"G#", 0.6}, {"F#", 1.2}
    }
}

local currentPianoModel = nil
local pianoKeys = {}
local autoPlayThread = nil
local foundPianos = {}

-- Helper: Find all pianos
local function findAllPianos()
    local pianos = {}
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            
            if name:find("piano") or name:find("yamaha") or name:find("keyboard") or 
               name:find("roland") or name:find("sio") then
                
                local hasBlueKeys = false
                local hasKeys = false
                
                for _, part in ipairs(obj:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if part.Color == Color3.fromRGB(0, 0, 255) or 
                           part.Color == Color3.fromRGB(13, 105, 172) or
                           part.BrickColor == BrickColor.new("Really blue") or
                           part.BrickColor == BrickColor.new("Bright blue") then
                            hasBlueKeys = true
                        end
                        
                        if part.Name == "C" or part.Name == "D" or part.Name == "E" or
                           part.Name == "F" or part.Name == "G" or part.Name == "A" or
                           part.Name == "B" or part.Name == "C#" or part.Name == "D#" or
                           part.Name == "F#" or part.Name == "G#" or part.Name == "A#" then
                            hasKeys = true
                        end
                    end
                end
                
                if hasKeys or hasBlueKeys then
                    table.insert(pianos, obj)
                end
            end
        end
    end
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local color = obj.Color
            if (color == Color3.fromRGB(0, 0, 255) or 
                color == Color3.fromRGB(13, 105, 172) or
                obj.BrickColor == BrickColor.new("Really blue") or
                obj.BrickColor == BrickColor.new("Bright blue")) and
               (obj.Name:match("^[CDEFGAB]#?$")) then
                
                local parent = obj.Parent
                if parent and parent:IsA("Model") and not table.find(pianos, parent) then
                    table.insert(pianos, parent)
                end
            end
        end
    end
    
    return pianos
end

-- Helper: Get piano keys
local function getPianoKeys(pianoModel)
    local keys = {}
    
    if not pianoModel then return keys end
    
    local keyNames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
    
    for _, obj in ipairs(pianoModel:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name
            
            for _, keyName in ipairs(keyNames) do
                if name == keyName then
                    keys[keyName] = obj
                    break
                end
            end
        end
    end
    
    return keys
end

-- Helper: Click piano key
local function clickPianoKey(keyPart)
    if not keyPart then return false end
    
    for _, child in ipairs(keyPart:GetDescendants()) do
        if child:IsA("ProximityPrompt") then
            pcall(function()
                fireproximityprompt(child)
            end)
            return true
        end
    end
    
    for _, child in ipairs(keyPart:GetDescendants()) do
        if child:IsA("ClickDetector") then
            pcall(function()
                fireclickdetector(child)
            end)
            return true
        end
    end
    
    local proximityPrompt = keyPart:FindFirstChildOfClass("ProximityPrompt")
    if proximityPrompt then
        pcall(function()
            fireproximityprompt(proximityPrompt)
        end)
        return true
    end
    
    local clickDetector = keyPart:FindFirstChildOfClass("ClickDetector")
    if clickDetector then
        pcall(function()
            fireclickdetector(clickDetector)
        end)
        return true
    end
    
    return true
end

-- Helper: Position camera
local function positionCameraAtPiano(pianoModel, keyPart)
    if not Settings.AutoFocusCamera then return end
    if not pianoModel then return end
    
    pcall(function()
        local targetPos = keyPart and keyPart.Position or pianoModel:GetModelCFrame().Position
        local offset = Vector3.new(0, 5, 10)
        
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = CFrame.new(targetPos + offset, targetPos)
    end)
end

-- Helper: Teleport to piano
local function teleportToPiano(pianoModel)
    if not pianoModel then return end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
    
    pcall(function()
        local pianoPos = pianoModel:GetModelCFrame().Position
        local teleportPos = pianoPos + Vector3.new(0, 3, 8)
        
        LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(teleportPos))
    end)
end

-- Helper: Play note sequence
local function playNoteSequence(sequence)
    for _, noteInfo in ipairs(sequence) do
        if not Settings.AutoPlayEnabled then break end
        
        local noteName = noteInfo[1]
        local duration = noteInfo[2] * (1 / Settings.PlaySpeed)
        
        if noteName ~= "rest" then
            local keyPart = pianoKeys[noteName]
            
            if keyPart then
                if Settings.AutoFocusCamera then
                    positionCameraAtPiano(currentPianoModel, keyPart)
                end
                
                task.wait(Settings.ClickDelay)
                pcall(function()
                    clickPianoKey(keyPart)
                end)
            end
        end
        
        task.wait(math.max(duration, Settings.NoteGap))
    end
end

-- Start auto play
local function startAutoPlay()
    if autoPlayThread then
        task.cancel(autoPlayThread)
    end
    
    autoPlayThread = task.spawn(function()
        foundPianos = findAllPianos()
        
        if #foundPianos == 0 then
            Rayfield:Notify({
               Title = "❌ ピアノが見つかりません",
               Content = "青いピアノをスポーンしてください！",
               Duration = 5,
               Image = 4483362458
            })
            Settings.AutoPlayEnabled = false
            return
        end
        
        if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
            local playerPos = LocalPlayer.Character.PrimaryPart.Position
            local closestDist = math.huge
            
            for _, piano in ipairs(foundPianos) do
                local dist = (piano:GetModelCFrame().Position - playerPos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    currentPianoModel = piano
                end
            end
        else
            currentPianoModel = foundPianos[1]
        end
        
        pianoKeys = getPianoKeys(currentPianoModel)
        
        if next(pianoKeys) == nil then
            Rayfield:Notify({
               Title = "❌ 鍵盤が見つかりません",
               Content = "ピアノに鍵盤が見つかりませんでした",
               Duration = 5,
               Image = 4483362458
            })
            Settings.AutoPlayEnabled = false
            return
        end
        
        Rayfield:Notify({
           Title = "🎵 Libra Heart",
           Content = "演奏を開始します...",
           Duration = 3,
           Image = 4483362458
        })
        
        if Settings.TeleportToPiano then
            teleportToPiano(currentPianoModel)
            task.wait(0.5)
        end
        
        positionCameraAtPiano(currentPianoModel, nil)
        
        -- Main play loop - Full song structure
        while Settings.AutoPlayEnabled do
            -- Play full song
            playNoteSequence(LibraHeartSong.Intro)
            if not Settings.AutoPlayEnabled then break end
            
            task.wait(0.3)
            playNoteSequence(LibraHeartSong.VerseA)
            if not Settings.AutoPlayEnabled then break end
            
            task.wait(0.3)
            playNoteSequence(LibraHeartSong.Chorus)
            if not Settings.AutoPlayEnabled then break end
            
            task.wait(0.3)
            playNoteSequence(LibraHeartSong.VerseA)
            if not Settings.AutoPlayEnabled then break end
            
            task.wait(0.3)
            playNoteSequence(LibraHeartSong.Chorus)
            if not Settings.AutoPlayEnabled then break end
            
            task.wait(0.3)
            playNoteSequence(LibraHeartSong.Bridge)
            if not Settings.AutoPlayEnabled then break end
            
            task.wait(0.3)
            playNoteSequence(LibraHeartSong.Chorus)
            if not Settings.AutoPlayEnabled then break end
            
            task.wait(0.5)
            playNoteSequence(LibraHeartSong.Outro)
            
            task.wait(Settings.LoopDelay)
        end
        
        Camera.CameraType = Enum.CameraType.Custom
    end)
end

-- GUI Creation
local MainTab = Window:CreateTab("🎵 Libra Heart", 4483362458)
local SettingsTab = Window:CreateTab("⚙️ 設定", 4483362458)
local InfoTab = Window:CreateTab("ℹ️ 情報", 4483362458)

-- Main Tab
local PlaySection = MainTab:CreateSection("再生コントロール")

local AutoPlayToggle = MainTab:CreateToggle({
   Name = "🎹 Libra Heart を演奏",
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
           Camera.CameraType = Enum.CameraType.Custom
           Rayfield:Notify({
              Title = "⏸️ 停止",
              Content = "演奏を停止しました",
              Duration = 2,
              Image = 4483362458
           })
       end
   end
})

MainTab:CreateLabel("曲: Libra Heart by imaizumiyui")
MainTab:CreateLabel("完全版メロディ搭載")

local CameraSection = MainTab:CreateSection("カメラ設定")

local AutoFocusToggle = MainTab:CreateToggle({
   Name = "📹 カメラ自動追従",
   CurrentValue = true,
   Flag = "AutoFocusToggle",
   Callback = function(Value)
       Settings.AutoFocusCamera = Value
       if not Value then
           Camera.CameraType = Enum.CameraType.Custom
       end
   end
})

local TeleportToggle = MainTab:CreateToggle({
   Name = "🚀 ピアノにテレポート",
   CurrentValue = false,
   Flag = "TeleportToggle",
   Callback = function(Value)
       Settings.TeleportToPiano = Value
   end
})

local ManualSection = MainTab:CreateSection("手動操作")

local FindPianoButton = MainTab:CreateButton({
   Name = "🔍 ピアノを探す",
   Callback = function()
       foundPianos = findAllPianos()
       
       if #foundPianos > 0 then
           Rayfield:Notify({
              Title = "✅ ピアノ発見！",
              Content = string.format("%d個のピアノが見つかりました", #foundPianos),
              Duration = 4,
              Image = 4483362458
           })
       else
           Rayfield:Notify({
              Title = "❌ ピアノなし",
              Content = "青いピアノをスポーンしてください！",
              Duration = 5,
              Image = 4483362458
           })
       end
   end
})

local TeleportNowButton = MainTab:CreateButton({
   Name = "🎹 今すぐテレポート",
   Callback = function()
       if currentPianoModel then
           teleportToPiano(currentPianoModel)
           Rayfield:Notify({
              Title = "✅ テレポート完了",
              Content = "ピアノの近くに移動しました",
              Duration = 2,
              Image = 4483362458
           })
       else
           Rayfield:Notify({
              Title = "❌ ピアノ未設定",
              Content = "先に「ピアノを探す」を押してください",
              Duration = 3,
              Image = 4483362458
           })
       end
   end
})

-- Settings Tab
local TimingSection = SettingsTab:CreateSection("タイミング設定")

local PlaySpeedSlider = SettingsTab:CreateSlider({
   Name = "再生速度",
   Range = {0.5, 2.0},
   Increment = 0.1,
   Suffix = "x",
   CurrentValue = 1.0,
   Flag = "PlaySpeedSlider",
   Callback = function(Value)
       Settings.PlaySpeed = Value
   end
})

local ClickDelaySlider = SettingsTab:CreateSlider({
   Name = "クリック遅延",
   Range = {0.01, 0.3},
   Increment = 0.01,
   Suffix = "秒",
   CurrentValue = 0.08,
   Flag = "ClickDelaySlider",
   Callback = function(Value)
       Settings.ClickDelay = Value
   end
})

local NoteGapSlider = SettingsTab:CreateSlider({
   Name = "音符間隔",
   Range = {0.01, 0.5},
   Increment = 0.01,
   Suffix = "秒",
   CurrentValue = 0.05,
   Flag = "NoteGapSlider",
   Callback = function(Value)
       Settings.NoteGap = Value
   end
})

local LoopDelaySlider = SettingsTab:CreateSlider({
   Name = "曲間の待機時間",
   Range = {1, 20},
   Increment = 1,
   Suffix = "秒",
   CurrentValue = 3,
   Flag = "LoopDelaySlider",
   Callback = function(Value)
       Settings.LoopDelay = Value
   end
})

-- Info Tab
InfoTab:CreateSection("🎵 曲情報")

InfoTab:CreateParagraph({
    Title = "Libra Heart",
    Content = "アーティスト: imaizumiyui\nキー: C#m (D#, B, C#, F#)\n\n完全版メロディ:\n• イントロ\n• Aメロ\n• サビ（メインメロディ）\n• ブリッジ\n• アウトロ"
})

InfoTab:CreateSection("📖 使い方")

InfoTab:CreateParagraph({
    Title = "ステップ 1",
    Content = "ゲーム内で青いピアノをスポーン"
})

InfoTab:CreateParagraph({
    Title = "ステップ 2",
    Content = "「ピアノを探す」ボタンを押す"
})

InfoTab:CreateParagraph({
    Title = "ステップ 3",
    Content = "「Libra Heart を演奏」をオン！"
})

InfoTab:CreateSection("ℹ️ スクリプト情報")

InfoTab:CreateLabel("Libra Heart Auto Piano v1.0")
InfoTab:CreateLabel("Fling Things and People 対応")
InfoTab:CreateLabel("")
InfoTab:CreateLabel("✓ 完全版メロディ")
InfoTab:CreateLabel("✓ 青色ピアノ自動検出")
InfoTab:CreateLabel("✓ 再生速度調整")
InfoTab:CreateLabel("✓ カメラ追従機能")

InfoTab:CreateSection("⚠️ 注意")

InfoTab:CreateParagraph({
    Title = "必要な鍵盤",
    Content = "このメロディには以下の鍵盤が必要です:\nC#, D#, F#, G#, A#, B, C, D, E, F, G, A\n\nシャープ(#)付きの鍵盤がないピアノでは一部の音が鳴らない場合があります。"
})

-- Initial notification
Rayfield:Notify({
   Title = "🎵 Libra Heart",
   Content = "by imaizumiyui - 完全版メロディ搭載！",
   Duration = 5,
   Image = 4483362458
})

-- Auto-find piano
task.spawn(function()
    task.wait(3)
    foundPianos = findAllPianos()
    if #foundPianos > 0 then
        Rayfield:Notify({
           Title = "✅ ピアノ自動検出",
           Content = string.format("%d個のピアノが見つかりました！", #foundPianos),
           Duration = 4,
           Image = 4483362458
        })
    else
        Rayfield:Notify({
           Title = "ℹ️ ピアノ未検出",
           Content = "青いピアノをスポーンしてください",
           Duration = 5,
           Image = 4483362458
        })
    end
end)

print("🎵 Libra Heart Auto Piano 読み込み完了!")
print("🎹 imaizumiyui - Libra Heart")
