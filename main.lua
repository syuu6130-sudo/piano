--[[
    Auto Piano Player for "物や人を飛ばす" (Fling Things and People)
    Roblox Game Auto Piano Script with Rayfield GUI
    
    Features:
    - Finds and clicks piano toy automatically
    - Camera auto-positioning
    - Multiple song playback
    - Works with ProximityPrompts
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "🎹 物や人を飛ばす - Auto Piano",
   LoadingTitle = "ピアノ自動演奏読み込み中...",
   LoadingSubtitle = "by Script Creator",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "FlingPianoConfig",
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
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Variables
local Settings = {
    AutoPlayEnabled = false,
    AutoFocusCamera = true,
    ClickDelay = 0.08,
    NoteGap = 0.05,
    LoopDelay = 2,
    CurrentSong = 1,
    TeleportToPiano = false,
    PlayDistance = 15
}

-- Piano key names mapping
local PianoKeyNames = {
    "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
    "C5", "C#5", "D5", "D#5", "E5", "F5", "F#5", "G5", "G#5", "A5", "A#5", "B5"
}

-- Songs Library
local Songs = {
    {
        Name = "きらきら星 (Twinkle Star)",
        Sequence = {
            {"C", 0.4}, {"C", 0.4}, {"G", 0.4}, {"G", 0.4},
            {"A", 0.4}, {"A", 0.4}, {"G", 0.8},
            {"F", 0.4}, {"F", 0.4}, {"E", 0.4}, {"E", 0.4},
            {"D", 0.4}, {"D", 0.4}, {"C", 0.8}
        }
    },
    {
        Name = "メリーさんの羊 (Mary's Lamb)",
        Sequence = {
            {"E", 0.4}, {"D", 0.4}, {"C", 0.4}, {"D", 0.4},
            {"E", 0.4}, {"E", 0.4}, {"E", 0.8},
            {"D", 0.4}, {"D", 0.4}, {"D", 0.8},
            {"E", 0.4}, {"G", 0.4}, {"G", 0.8}
        }
    },
    {
        Name = "ハッピーバースデー (Happy Birthday)",
        Sequence = {
            {"C", 0.3}, {"C", 0.3}, {"D", 0.6}, {"C", 0.6},
            {"F", 0.6}, {"E", 1.2},
            {"C", 0.3}, {"C", 0.3}, {"D", 0.6}, {"C", 0.6},
            {"G", 0.6}, {"F", 1.2}
        }
    },
    {
        Name = "かえるの歌 (Frog Song)",
        Sequence = {
            {"C", 0.4}, {"D", 0.4}, {"E", 0.4}, {"F", 0.4},
            {"E", 0.4}, {"D", 0.4}, {"C", 0.8},
            {"E", 0.4}, {"F", 0.4}, {"G", 0.4}, {"A", 0.4},
            {"G", 0.4}, {"F", 0.4}, {"E", 0.8}
        }
    },
    {
        Name = "ドレミの歌 (Do-Re-Mi)",
        Sequence = {
            {"C", 0.4}, {"D", 0.4}, {"E", 0.4}, {"C", 0.4},
            {"E", 0.4}, {"C", 0.4}, {"E", 0.8},
            {"D", 0.4}, {"E", 0.4}, {"F", 0.4}, {"F", 0.4},
            {"E", 0.4}, {"D", 0.4}, {"F", 0.8}
        }
    },
    {
        Name = "チューリップ (Tulip)",
        Sequence = {
            {"C", 0.4}, {"D", 0.4}, {"E", 0.4}, {"C", 0.4},
            {"E", 0.4}, {"F", 0.4}, {"E", 0.4}, {"D", 0.4},
            {"C", 0.4}, {"E", 0.4}, {"G", 0.4}, {"G", 0.4},
            {"E", 0.4}, {"D", 0.4}, {"C", 0.8}
        }
    }
}

local currentPianoModel = nil
local pianoKeys = {}
local autoPlayThread = nil

-- Helper: Find piano toy in workspace
local function findPianoToy()
    -- Search in Workspace for piano models
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            -- Check for piano-related names
            local name = obj.Name:lower()
            if name:find("piano") or name:find("yamarolandsio") or name:find("yamarolansio") then
                -- Verify it has piano keys
                local hasKeys = false
                for _, child in ipairs(obj:GetDescendants()) do
                    if child:IsA("BasePart") and (
                        child.Name == "C" or child.Name == "D" or child.Name == "E" or
                        child.Name:find("Key") or child.Name:find("Button")
                    ) then
                        hasKeys = true
                        break
                    end
                end
                if hasKeys then
                    return obj
                end
            end
        end
    end
    
    -- Also check in Items folder if exists
    local itemsFolder = Workspace:FindFirstChild("Items") or Workspace:FindFirstChild("Toys")
    if itemsFolder then
        for _, item in ipairs(itemsFolder:GetDescendants()) do
            if item:IsA("Model") and item.Name:lower():find("piano") then
                return item
            end
        end
    end
    
    return nil
end

-- Helper: Get all piano keys from piano model
local function getPianoKeys(pianoModel)
    local keys = {}
    
    if not pianoModel then return keys end
    
    for _, obj in ipairs(pianoModel:GetDescendants()) do
        if obj:IsA("BasePart") then
            -- Check if this is a piano key
            for _, keyName in ipairs(PianoKeyNames) do
                if obj.Name == keyName or obj.Name:find(keyName) then
                    keys[keyName] = obj
                    break
                end
            end
        end
    end
    
    return keys
end

-- Helper: Click piano key using different methods
local function clickPianoKey(keyPart)
    if not keyPart then return false end
    
    -- Method 1: Check for ProximityPrompt
    local proximityPrompt = keyPart:FindFirstChildOfClass("ProximityPrompt")
    if not proximityPrompt then
        for _, child in ipairs(keyPart:GetDescendants()) do
            if child:IsA("ProximityPrompt") then
                proximityPrompt = child
                break
            end
        end
    end
    
    if proximityPrompt then
        fireproximityprompt(proximityPrompt)
        return true
    end
    
    -- Method 2: Check for ClickDetector
    local clickDetector = keyPart:FindFirstChildOfClass("ClickDetector")
    if not clickDetector then
        for _, child in ipairs(keyPart:GetDescendants()) do
            if child:IsA("ClickDetector") then
                clickDetector = child
                break
            end
        end
    end
    
    if clickDetector then
        fireclickdetector(clickDetector)
        return true
    end
    
    -- Method 3: Simulate mouse click on part
    local camera = Workspace.CurrentCamera
    local screenPoint = camera:WorldToScreenPoint(keyPart.Position)
    
    VirtualInputManager:SendMouseButtonEvent(screenPoint.X, screenPoint.Y, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(screenPoint.X, screenPoint.Y, 0, false, game, 0)
    
    return true
end

-- Helper: Position camera to look at piano
local function positionCameraAtPiano(pianoModel, keyPart)
    if not Settings.AutoFocusCamera then return end
    if not pianoModel then return end
    
    local targetPos = keyPart and keyPart.Position or pianoModel:GetModelCFrame().Position
    local offset = Vector3.new(0, 5, 10)
    
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = CFrame.new(targetPos + offset, targetPos)
end

-- Helper: Teleport player near piano
local function teleportToPiano(pianoModel)
    if not pianoModel then return end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
    
    local pianoPos = pianoModel:GetModelCFrame().Position
    local teleportPos = pianoPos + Vector3.new(0, 3, 8)
    
    LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(teleportPos))
end

-- Helper: Check if player is close enough to piano
local function isPlayerNearPiano(pianoModel)
    if not pianoModel then return false end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return false end
    
    local playerPos = LocalPlayer.Character.PrimaryPart.Position
    local pianoPos = pianoModel:GetModelCFrame().Position
    local distance = (playerPos - pianoPos).Magnitude
    
    return distance <= Settings.PlayDistance
end

-- Auto play function
local function startAutoPlay()
    if autoPlayThread then
        task.cancel(autoPlayThread)
    end
    
    autoPlayThread = task.spawn(function()
        -- Find piano
        currentPianoModel = findPianoToy()
        
        if not currentPianoModel then
            Rayfield:Notify({
               Title = "❌ ピアノが見つかりません",
               Content = "ゲーム内にピアノのおもちゃが見つかりませんでした",
               Duration = 5,
               Image = 4483362458
            })
            Settings.AutoPlayEnabled = false
            return
        end
        
        -- Get piano keys
        pianoKeys = getPianoKeys(currentPianoModel)
        
        if next(pianoKeys) == nil then
            Rayfield:Notify({
               Title = "❌ ピアノの鍵盤が見つかりません",
               Content = "ピアノモデルに鍵盤が見つかりませんでした",
               Duration = 5,
               Image = 4483362458
            })
            Settings.AutoPlayEnabled = false
            return
        end
        
        Rayfield:Notify({
           Title = "✅ ピアノ発見！",
           Content = "自動演奏を開始します...",
           Duration = 3,
           Image = 4483362458
        })
        
        -- Teleport if enabled
        if Settings.TeleportToPiano then
            teleportToPiano(currentPianoModel)
            task.wait(0.5)
        end
        
        -- Position camera
        positionCameraAtPiano(currentPianoModel, nil)
        
        -- Main play loop
        while Settings.AutoPlayEnabled do
            -- Check if player is still near piano
            if not isPlayerNearPiano(currentPianoModel) and not Settings.TeleportToPiano then
                Rayfield:Notify({
                   Title = "⚠️ ピアノから離れています",
                   Content = "ピアノに近づいてください",
                   Duration = 3,
                   Image = 4483362458
                })
                task.wait(2)
                continue
            end
            
            local currentSong = Songs[Settings.CurrentSong]
            if currentSong then
                for _, noteInfo in ipairs(currentSong.Sequence) do
                    if not Settings.AutoPlayEnabled then break end
                    
                    local noteName = noteInfo[1]
                    local duration = noteInfo[2] or 0.4
                    
                    if noteName ~= "rest" then
                        local keyPart = pianoKeys[noteName]
                        
                        if keyPart then
                            -- Focus camera on key
                            if Settings.AutoFocusCamera then
                                positionCameraAtPiano(currentPianoModel, keyPart)
                            end
                            
                            task.wait(Settings.ClickDelay)
                            
                            -- Click the key
                            local success = clickPianoKey(keyPart)
                            
                            if not success then
                                warn("キーのクリックに失敗:", noteName)
                            end
                        else
                            warn("鍵盤が見つかりません:", noteName)
                        end
                    end
                    
                    task.wait(math.max(duration, Settings.NoteGap))
                end
            end
            
            task.wait(Settings.LoopDelay)
        end
        
        -- Reset camera
        Camera.CameraType = Enum.CameraType.Custom
    end)
end

-- GUI Creation
local MainTab = Window:CreateTab("🎵 メイン操作", 4483362458)
local SettingsTab = Window:CreateTab("⚙️ 設定", 4483362458)
local InfoTab = Window:CreateTab("ℹ️ 情報", 4483362458)

-- Main Tab
local PlaybackSection = MainTab:CreateSection("再生コントロール")

local AutoPlayToggle = MainTab:CreateToggle({
   Name = "🎹 自動演奏を開始",
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
              Title = "⏸️ 演奏停止",
              Content = "自動演奏を停止しました",
              Duration = 3,
              Image = 4483362458
           })
       end
   end
})

local SongDropdown = MainTab:CreateDropdown({
   Name = "曲を選択",
   Options = {
       "きらきら星 (Twinkle Star)",
       "メリーさんの羊 (Mary's Lamb)",
       "ハッピーバースデー (Happy Birthday)",
       "かえるの歌 (Frog Song)",
       "ドレミの歌 (Do-Re-Mi)",
       "チューリップ (Tulip)"
   },
   CurrentOption = {"きらきら星 (Twinkle Star)"},
   MultipleOptions = false,
   Flag = "SongDropdown",
   Callback = function(Option)
       for i, song in ipairs(Songs) do
           if song.Name == Option[1] then
               Settings.CurrentSong = i
               Rayfield:Notify({
                  Title = "🎵 曲変更",
                  Content = "選択: " .. song.Name,
                  Duration = 3,
                  Image = 4483362458
               })
               break
           end
       end
   end
})

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
       local piano = findPianoToy()
       if piano then
           currentPianoModel = piano
           pianoKeys = getPianoKeys(piano)
           Rayfield:Notify({
              Title = "✅ ピアノ発見！",
              Content = "見つかりました: " .. piano.Name .. " (鍵盤数: " .. #pianoKeys .. ")",
              Duration = 4,
              Image = 4483362458
           })
       else
           Rayfield:Notify({
              Title = "❌ ピアノなし",
              Content = "ピアノのおもちゃが見つかりませんでした",
              Duration = 5,
              Image = 4483362458
           })
       end
   end
})

local TeleportNowButton = MainTab:CreateButton({
   Name = "🎹 今すぐピアノへテレポート",
   Callback = function()
       if currentPianoModel then
           teleportToPiano(currentPianoModel)
           Rayfield:Notify({
              Title = "✅ テレポート完了",
              Content = "ピアノの近くに移動しました",
              Duration = 3,
              Image = 4483362458
           })
       else
           Rayfield:Notify({
              Title = "❌ ピアノが未設定",
              Content = "先に「ピアノを探す」を押してください",
              Duration = 3,
              Image = 4483362458
           })
       end
   end
})

-- Settings Tab
local TimingSection = SettingsTab:CreateSection("タイミング設定")

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
   Name = "ループ待機",
   Range = {0.5, 10},
   Increment = 0.5,
   Suffix = "秒",
   CurrentValue = 2,
   Flag = "LoopDelaySlider",
   Callback = function(Value)
       Settings.LoopDelay = Value
   end
})

local DistanceSection = SettingsTab:CreateSection("距離設定")

local PlayDistanceSlider = SettingsTab:CreateSlider({
   Name = "演奏可能距離",
   Range = {5, 30},
   Increment = 1,
   Suffix = " スタッド",
   CurrentValue = 15,
   Flag = "PlayDistanceSlider",
   Callback = function(Value)
       Settings.PlayDistance = Value
   end
})

-- Info Tab
InfoTab:CreateSection("📖 使い方")

InfoTab:CreateParagraph({
    Title = "ステップ 1: ピアノを探す",
    Content = "「ピアノを探す」ボタンを押して、ゲーム内のピアノのおもちゃを探します。"
})

InfoTab:CreateParagraph({
    Title = "ステップ 2: 曲を選択",
    Content = "ドロップダウンメニューから好きな曲を選びます。日本の童謡が用意されています。"
})

InfoTab:CreateParagraph({
    Title = "ステップ 3: 演奏開始",
    Content = "「自動演奏を開始」をオンにすると、自動でピアノを演奏します。"
})

InfoTab:CreateSection("ℹ️ スクリプト情報")

InfoTab:CreateLabel("🎹 物や人を飛ばす - Auto Piano v1.0")
InfoTab:CreateLabel("対応ゲーム: Fling Things and People")
InfoTab:CreateLabel("")
InfoTab:CreateLabel("✓ 自動鍵盤クリック")
InfoTab:CreateLabel("✓ カメラ自動追従")
InfoTab:CreateLabel("✓ 6曲搭載")
InfoTab:CreateLabel("✓ テレポート機能")

InfoTab:CreateSection("⚠️ 注意事項")

InfoTab:CreateParagraph({
    Title = "必要条件",
    Content = "• ゲーム「物や人を飛ばす」でプレイ\n• ピアノのおもちゃがマップに存在\n• Executor が fireproximityprompt をサポート"
})

InfoTab:CreateParagraph({
    Title = "ヒント",
    Content = "• ピアノに近づいてから演奏開始\n• テレポート機能を使うと便利\n• カメラ追従で演奏を見られます"
})

-- Initial notification
Rayfield:Notify({
   Title = "🎹 Auto Piano 読み込み完了",
   Content = "物や人を飛ばす - ピアノ自動演奏スクリプト",
   Duration = 5,
   Image = 4483362458
})

-- Auto-find piano on load
task.spawn(function()
    task.wait(2)
    local piano = findPianoToy()
    if piano then
        currentPianoModel = piano
        pianoKeys = getPianoKeys(piano)
        Rayfield:Notify({
           Title = "✅ ピアノ自動検出",
           Content = "見つかりました: " .. piano.Name,
           Duration = 4,
           Image = 4483362458
        })
    end
end)

print("🎹 物や人を飛ばす - Auto Piano 読み込み完了!")
print("🔍 ピアノを探しています...")
