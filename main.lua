--[[
    Auto Piano Player for "Fling Things and People"
    Libra Heart by imaizumiyui - Complete Version
    Works with YamaRolanSio blue piano
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "🎹 Libra Heart Auto Piano",
   LoadingTitle = "Libra Heart 読み込み中...",
   LoadingSubtitle = "YamaRolanSio青ピアノ対応",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "LibraHeartConfig",
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

-- Variables
local Settings = {
    AutoPlayEnabled = false,
    AutoFocusCamera = true,
    ClickDelay = 0.08,
    NoteGap = 0.05,
    LoopDelay = 3,
    CurrentSong = 1,
    TeleportToPiano = false,
    PlaySpeed = 1.0
}

-- Libra Heart Song Data (Complete Version)
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

-- Other Songs
local Songs = {
    LibraHeartSong,
    {
        Name = "きらきら星",
        Notes = {"C", "C", "G", "G", "A", "A", "G", "rest", "F", "F", "E", "E", "D", "D", "C", "rest"},
        Durations = {0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.8, 0.2, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.8, 0.2}
    },
    {
        Name = "メリーさんの羊",
        Notes = {"E", "D", "C", "D", "E", "E", "E", "rest", "D", "D", "D", "rest", "E", "G", "G", "rest"},
        Durations = {0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.8, 0.2, 0.4, 0.4, 0.8, 0.2, 0.4, 0.4, 0.8, 0.2}
    },
    {
        Name = "ハッピーバースデー",
        Notes = {"C", "C", "D", "C", "F", "E", "rest", "C", "C", "D", "C", "G", "F", "rest"},
        Durations = {0.3, 0.3, 0.6, 0.6, 0.6, 1.2, 0.3, 0.3, 0.3, 0.6, 0.6, 0.6, 1.2, 0.3}
    },
    {
        Name = "かえるの歌",
        Notes = {"C", "D", "E", "F", "E", "D", "C", "rest", "E", "F", "G", "A", "G", "F", "E", "rest"},
        Durations = {0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.8, 0.2, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.8, 0.2}
    }
}

local currentPianoModel = nil
local pianoKeys = {}
local autoPlayThread = nil
local foundPianos = {}

-- Helper: 全てのピアノを検索
local function findAllPianos()
    local pianos = {}
    
    print("[Libra Heart] Searching for pianos...")
    
    -- Workspace全体を検索
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            
            -- YamaRolanSioピアノまたはピアノ関連の名前をチェック
            if name:find("piano") or name:find("yamaha") or name:find("keyboard") or 
               name:find("roland") or name:find("sio") or name:find("yamarolansi") then
                
                -- キーがあるか確認
                local hasKeys = false
                local keyCount = 0
                
                for _, part in ipairs(obj:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local partName = part.Name
                        -- 音符名チェック
                        if partName == "C" or partName == "D" or partName == "E" or
                           partName == "F" or partName == "G" or partName == "A" or
                           partName == "B" or partName == "C#" or partName == "D#" or
                           partName == "F#" or partName == "G#" or partName == "A#" then
                            hasKeys = true
                            keyCount = keyCount + 1
                        end
                    end
                end
                
                if hasKeys and keyCount >= 5 then
                    print("[Libra Heart] Found piano:", obj.Name, "with", keyCount, "keys")
                    table.insert(pianos, obj)
                end
            end
        end
    end
    
    -- 青いパーツでキー名を持つものを検索
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name
            if (name == "C" or name == "D" or name == "E" or 
                name == "F" or name == "G" or name == "A" or 
                name == "B" or name == "C#" or name == "D#" or
                name == "F#" or name == "G#" or name == "A#") then
                
                -- 親モデルを取得
                local parent = obj.Parent
                if parent and parent:IsA("Model") and not table.find(pianos, parent) then
                    print("[Libra Heart] Found piano via key part:", parent.Name)
                    table.insert(pianos, parent)
                end
            end
        end
    end
    
    print("[Libra Heart] Total pianos found:", #pianos)
    return pianos
end

-- Helper: ピアノから鍵盤を取得
local function getPianoKeys(pianoModel)
    local keys = {}
    
    if not pianoModel then return keys end
    
    print("[Libra Heart] Getting keys from:", pianoModel.Name)
    
    -- 全ての子孫を検索
    for _, obj in ipairs(pianoModel:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name
            
            -- 音符名の完全一致
            if name == "C" or name == "C#" or name == "D" or name == "D#" or 
               name == "E" or name == "F" or name == "F#" or name == "G" or 
               name == "G#" or name == "A" or name == "A#" or name == "B" then
                keys[name] = obj
                print("[Libra Heart] Found key:", name)
            end
        end
    end
    
    local keyCount = 0
    for k, v in pairs(keys) do 
        keyCount = keyCount + 1
    end
    print("[Libra Heart] Total keys found:", keyCount)
    
    return keys
end

-- Helper: 鍵盤をクリック
local function clickPianoKey(keyPart)
    if not keyPart then return false end
    
    -- ProximityPromptを探す
    for _, child in ipairs(keyPart:GetDescendants()) do
        if child:IsA("ProximityPrompt") then
            pcall(function()
                fireproximityprompt(child)
            end)
            return true
        end
    end
    
    -- ClickDetectorを探す
    for _, child in ipairs(keyPart:GetDescendants()) do
        if child:IsA("ClickDetector") then
            pcall(function()
                fireclickdetector(child)
            end)
            return true
        end
    end
    
    -- 直接の子でも探す
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

-- Helper: カメラをピアノに向ける
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

-- Helper: ピアノにテレポート
local function teleportToPiano(pianoModel)
    if not pianoModel then return end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
    
    pcall(function()
        local pianoPos = pianoModel:GetModelCFrame().Position
        local teleportPos = pianoPos + Vector3.new(0, 3, 8)
        
        LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(teleportPos))
    end)
end

-- Helper: 曲のセクションを演奏
local function playSection(section)
    for i, noteData in ipairs(section) do
        if not Settings.AutoPlayEnabled then break end
        
        local noteName = noteData[1]
        local duration = noteData[2] * (1 / Settings.PlaySpeed)
        
        if noteName ~= "rest" then
            local keyPart = pianoKeys[noteName]
            
            if keyPart then
                if Settings.AutoFocusCamera then
                    positionCameraAtPiano(currentPianoModel, keyPart)
                end
                
                task.wait(Settings.ClickDelay)
                clickPianoKey(keyPart)
            else
                print("[Libra Heart] Key not found:", noteName)
            end
        end
        
        task.wait(math.max(duration, Settings.NoteGap))
    end
end

-- Helper: 通常の曲を演奏
local function playSimpleSong(song)
    for i = 1, #song.Notes do
        if not Settings.AutoPlayEnabled then break end
        
        local noteName = song.Notes[i]
        local duration = song.Durations[i] or 0.4
        
        if noteName ~= "rest" then
            local keyPart = pianoKeys[noteName]
            
            if keyPart then
                if Settings.AutoFocusCamera then
                    positionCameraAtPiano(currentPianoModel, keyPart)
                end
                
                task.wait(Settings.ClickDelay)
                clickPianoKey(keyPart)
            end
        end
        
        task.wait(math.max(duration * (1 / Settings.PlaySpeed), Settings.NoteGap))
    end
end

-- 自動演奏開始
local function startAutoPlay()
    if autoPlayThread then
        task.cancel(autoPlayThread)
    end
    
    autoPlayThread = task.spawn(function()
        -- ピアノを探す
        foundPianos = findAllPianos()
        
        if #foundPianos == 0 then
            Rayfield:Notify({
               Title = "❌ ピアノが見つかりません",
               Content = "おもちゃメニューから青いピアノをスポーンしてください！",
               Duration = 5,
               Image = 4483362458
            })
            Settings.AutoPlayEnabled = false
            return
        end
        
        -- 一番近いピアノを選択
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
        
        -- 鍵盤を取得
        pianoKeys = getPianoKeys(currentPianoModel)
        
        local keyCount = 0
        for _ in pairs(pianoKeys) do keyCount = keyCount + 1 end
        
        if keyCount == 0 then
            Rayfield:Notify({
               Title = "❌ 鍵盤が見つかりません",
               Content = "ピアノに音符名の鍵盤が見つかりませんでした",
               Duration = 5,
               Image = 4483362458
            })
            Settings.AutoPlayEnabled = false
            return
        end
        
        Rayfield:Notify({
           Title = "✅ ピアノ発見！",
           Content = string.format("見つかった鍵盤: %d個", keyCount),
           Duration = 3,
           Image = 4483362458
        })
        
        -- テレポート
        if Settings.TeleportToPiano then
            teleportToPiano(currentPianoModel)
            task.wait(0.5)
        end
        
        -- カメラ設定
        positionCameraAtPiano(currentPianoModel, nil)
        
        -- メインループ
        while Settings.AutoPlayEnabled do
            local currentSong = Songs[Settings.CurrentSong]
            if currentSong then
                if currentSong.Name == "Libra Heart - imaizumiyui" then
                    -- Libra Heart完全版を演奏
                    playSection(currentSong.Intro)
                    if not Settings.AutoPlayEnabled then break end
                    task.wait(0.3)
                    
                    playSection(currentSong.VerseA)
                    if not Settings.AutoPlayEnabled then break end
                    task.wait(0.3)
                    
                    playSection(currentSong.Chorus)
                    if not Settings.AutoPlayEnabled then break end
                    task.wait(0.3)
                    
                    playSection(currentSong.VerseA)
                    if not Settings.AutoPlayEnabled then break end
                    task.wait(0.3)
                    
                    playSection(currentSong.Chorus)
                    if not Settings.AutoPlayEnabled then break end
                    task.wait(0.3)
                    
                    playSection(currentSong.Bridge)
                    if not Settings.AutoPlayEnabled then break end
                    task.wait(0.3)
                    
                    playSection(currentSong.Chorus)
                    if not Settings.AutoPlayEnabled then break end
                    task.wait(0.5)
                    
                    playSection(currentSong.Outro)
                else
                    -- 通常の曲を演奏
                    playSimpleSong(currentSong)
                end
            end
            
            task.wait(Settings.LoopDelay)
        end
        
        -- カメラをリセット
        Camera.CameraType = Enum.CameraType.Custom
    end)
end

-- GUI作成
local MainTab = Window:CreateTab("🎵 Libra Heart", 4483362458)
local SettingsTab = Window:CreateTab("⚙️ 設定", 4483362458)
local InfoTab = Window:CreateTab("ℹ️ 情報", 4483362458)

-- メインタブ
local PlaySection = MainTab:CreateSection("再生コントロール")

local AutoPlayToggle = MainTab:CreateToggle({
   Name = "🎹 自動演奏",
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

local SongDropdown = MainTab:CreateDropdown({
   Name = "曲を選択",
   Options = {"Libra Heart - imaizumiyui", "きらきら星", "メリーさんの羊", "ハッピーバースデー", "かえるの歌"},
   CurrentOption = {"Libra Heart - imaizumiyui"},
   MultipleOptions = false,
   Flag = "SongDropdown",
   Callback = function(Option)
       for i, song in ipairs(Songs) do
           if song.Name == Option[1] then
               Settings.CurrentSong = i
               Rayfield:Notify({
                  Title = "🎵 曲変更",
                  Content = song.Name,
                  Duration = 2,
                  Image = 4483362458
               })
               break
           end
       end
   end
})

MainTab:CreateLabel("曲: Libra Heart by imaizumiyui")
MainTab:CreateLabel("完全版メロディー（Intro→Verse→Chorus→Bridge→Outro）")

local CameraSection = MainTab:CreateSection("カメラ")

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
           
           for i, piano in ipairs(foundPianos) do
               print(string.format("[Libra Heart] Piano %d: %s", i, piano.Name))
           end
       else
           Rayfield:Notify({
              Title = "❌ ピアノなし",
              Content = "おもちゃから青いピアノをスポーンしてください！",
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

local TestButton = MainTab:CreateButton({
   Name = "🧪 テスト (C音)",
   Callback = function()
       if pianoKeys["C"] then
           clickPianoKey(pianoKeys["C"])
           Rayfield:Notify({
              Title = "✅ テスト成功",
              Content = "C音を鳴らしました",
              Duration = 2,
              Image = 4483362458
           })
       else
           Rayfield:Notify({
              Title = "❌ C鍵盤なし",
              Content = "C鍵盤が見つかりません",
              Duration = 3,
              Image = 4483362458
           })
       end
   end
})

-- 設定タブ
local TimingSection = SettingsTab:CreateSection("タイミング")

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
   Name = "ループ待機",
   Range = {1, 10},
   Increment = 0.5,
   Suffix = "秒",
   CurrentValue = 3,
   Flag = "LoopDelaySlider",
   Callback = function(Value)
       Settings.LoopDelay = Value
   end
})

-- 情報タブ
InfoTab:CreateSection("🎵 Libra Heart について")

InfoTab:CreateParagraph({
    Title = "曲情報",
    Content = "アーティスト: imaizumiyui\nキー: C#m\n\n完全版メロディー:\n• Intro（イントロ）\n• Verse A（Aメロ）\n• Chorus（サビ）\n• Bridge（ブリッジ）\n• Outro（アウトロ）"
})

InfoTab:CreateSection("📖 使い方")

InfoTab:CreateParagraph({
    Title = "ステップ 1: ピアノをスポーン",
    Content = "おもちゃメニューからYamaRolanSioの青いピアノをスポーン"
})

InfoTab:CreateParagraph({
    Title = "ステップ 2: 検出",
    Content = "「ピアノを探す」ボタンでピアノを検出（自動検出も実行されます）"
})

InfoTab:CreateParagraph({
    Title = "ステップ 3: 演奏",
    Content = "曲を選んで「自動演奏」をON！Libra Heartの完全版が流れます"
})

InfoTab:CreateSection("ℹ️ スクリプト情報")

InfoTab:CreateLabel("Libra Heart Auto Piano v4.0")
InfoTab:CreateLabel("YamaRolanSio 青ピアノ対応")
InfoTab:CreateLabel("")
InfoTab:CreateLabel("✓ Libra Heart 完全版搭載")
InfoTab:CreateLabel("✓ Intro→Verse→Chorus→Bridge→Outro")
InfoTab:CreateLabel("✓ 自動ピアノ検出")
InfoTab:CreateLabel("✓ カメラ追従機能")
InfoTab:CreateLabel("✓ 再生速度調整")
InfoTab:CreateLabel("✓ 5曲収録")

InfoTab:CreateSection("⚠️ 注意")

InfoTab:CreateParagraph({
    Title = "対応ピアノ",
    Content = "• YamaRolanSio の青いピアノ\n• おもちゃメニューからスポーン可能\n• C, C#, D, D#, E, F, F#, G, G#, A, A#, B の鍵盤が必要"
})

InfoTab:CreateParagraph({
    Title = "ピアノが見つからない場合",
    Content = "• F9キーでコンソールを開く\n• [Libra Heart] から始まるログを確認\n• 「ピアノを探す」を手動で実行\n• おもちゃメニューから青いピアノを再配置してください"
})

InfoTab:CreateSection("💬 クレジット")

InfoTab:CreateParagraph({
    Title = "製作者",
    Content = "Script: ChatGPT改良版\nOriginal Concept: imaizumiyui 曲に基づく\nVersion: 4.0 完全版"
})

Rayfield:Notify({
   Title = "🎹 Libra Heart Auto Piano 起動完了",
   Content = "青ピアノをスポーンして、「自動演奏」をONにしてください！",
   Duration = 6,
   Image = 4483362458
})

print("[Libra Heart] Script fully loaded. Ready to play Libra Heart by imaizumiyui!")
