--[[
    Auto Piano Player for "Fling Things and People"
    Works with spawned blue piano toys
    
    Features:
    - Finds ANY piano in the game (spawned or placed)
    - Clicks piano keys automatically
    - Camera auto-positioning
    - Multiple songs
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "🎹 Fling Piano Auto Player",
   LoadingTitle = "ピアノ自動演奏読み込み中...",
   LoadingSubtitle = "青いピアノ対応版",
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

-- Variables
local Settings = {
    AutoPlayEnabled = false,
    AutoFocusCamera = true,
    ClickDelay = 0.08,
    NoteGap = 0.05,
    LoopDelay = 2,
    CurrentSong = 1,
    TeleportToPiano = false,
    SearchRadius = 500  -- 検索範囲を広げる
}

-- Songs Library
local Songs = {
    {
        Name = "きらきら星",
        Notes = {"C", "C", "G", "G", "A", "A", "G", "F", "F", "E", "E", "D", "D", "C"},
        Durations = {0.4,0.4,0.4,0.4,0.4,0.4,0.8,0.4,0.4,0.4,0.4,0.4,0.4,0.8}
    },
    {
        Name = "メリーさんの羊",
        Notes = {"E","D","C","D","E","E","E","D","D","D","E","G","G"},
        Durations = {0.4,0.4,0.4,0.4,0.4,0.4,0.8,0.4,0.4,0.8,0.4,0.4,0.8}
    },
    {
        Name = "ハッピーバースデー",
        Notes = {"C","C","D","C","F","E","C","C","D","C","G","F"},
        Durations = {0.3,0.3,0.6,0.6,0.6,1.2,0.3,0.3,0.6,0.6,0.6,1.2}
    },
    {
        Name = "かえるの歌",
        Notes = {"C","D","E","F","E","D","C","E","F","G","A","G","F","E"},
        Durations = {0.4,0.4,0.4,0.4,0.4,0.4,0.8,0.4,0.4,0.4,0.4,0.4,0.4,0.8}
    },
    {
        Name = "ドレミの歌",
        Notes = {"C","D","E","C","E","C","E","D","E","F","F","E","D","F"},
        Durations = {0.4,0.4,0.4,0.4,0.4,0.4,0.8,0.4,0.4,0.4,0.4,0.4,0.4,0.8}
    },
    {
        Name = "チューリップ",
        Notes = {"C","D","E","C","E","F","E","D","C","E","G","G","E","D","C"},
        Durations = {0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.8}
    },
    {
        Name = "Libra Heart",
        Notes = {"C","E","G","E","F","A","C","A","G","E","F","G"},
        Durations = {0.4,0.4,0.6,0.4,0.4,0.6,0.4,0.4,0.6,0.4,0.4,0.8}
    }
}

local currentPianoModel = nil
local pianoKeys = {}
local autoPlayThread = nil
local foundPianos = {}

-- Helper: 全てのピアノを検索（広範囲）
local function findAllPianos()
    local pianos = {}
    
    -- Workspace全体を検索
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            
            -- ピアノに関連する名前をチェック
            if name:find("piano") or name:find("yamaha") or name:find("keyboard") or 
               name:find("roland") or name:find("sio") then
                
                -- 青色のパーツがあるか確認
                local hasBlueKeys = false
                local hasKeys = false
                
                for _, part in ipairs(obj:GetDescendants()) do
                    if part:IsA("BasePart") then
                        -- 青色チェック
                        if part.Color == Color3.fromRGB(0, 0, 255) or 
                           part.Color == Color3.fromRGB(13, 105, 172) or
                           part.BrickColor == BrickColor.new("Really blue") or
                           part.BrickColor == BrickColor.new("Bright blue") then
                            hasBlueKeys = true
                        end
                        
                        -- 鍵盤名チェック
                        if part.Name == "C" or part.Name == "D" or part.Name == "E" or
                           part.Name == "F" or part.Name == "G" or part.Name == "A" or
                           part.Name == "B" or part.Name:find("Key") or part.Name:find("Button") then
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
    
    -- 青いパーツが集まっている場所を検索（ピアノの可能性）
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local color = obj.Color
            if (color == Color3.fromRGB(0, 0, 255) or 
                color == Color3.fromRGB(13, 105, 172) or
                obj.BrickColor == BrickColor.new("Really blue") or
                obj.BrickColor == BrickColor.new("Bright blue")) and
               (obj.Name == "C" or obj.Name == "D" or obj.Name == "E" or 
                obj.Name == "F" or obj.Name == "G" or obj.Name == "A" or 
                obj.Name == "B") then
                
                -- 親モデルを取得
                local parent = obj.Parent
                if parent and parent:IsA("Model") and not table.find(pianos, parent) then
                    table.insert(pianos, parent)
                end
            end
        end
    end
    
    return pianos
end

-- Helper: ピアノから鍵盤を取得
local function getPianoKeys(pianoModel)
    local keys = {}
    
    if not pianoModel then return keys end
    
    -- 全ての子孫を検索
    for _, obj in ipairs(pianoModel:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name
            
            -- 音符名のパターンマッチング
            if name == "C" or name == "D" or name == "E" or name == "F" or 
               name == "G" or name == "A" or name == "B" then
                keys[name] = obj
            elseif name:match("^[CDEFGAB]$") then
                local noteName = name:match("^([CDEFGAB])")
                keys[noteName] = obj
            elseif name:find("Key") and (name:find("C") or name:find("D") or 
                   name:find("E") or name:find("F") or name:find("G") or 
                   name:find("A") or name:find("B")) then
                -- "KeyC", "CKey" などの形式
                for _, note in ipairs({"C", "D", "E", "F", "G", "A", "B"}) do
                    if name:find(note) then
                        keys[note] = obj
                        break
                    end
                end
            end
        end
    end
    
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
    
    -- マウスクリックシミュレーション
    pcall(function()
        local camera = Workspace.CurrentCamera
        local screenPoint, onScreen = camera:WorldToScreenPoint(keyPart.Position)
        
        if onScreen then
            VirtualInputManager:SendMouseButtonEvent(screenPoint.X, screenPoint.Y, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(screenPoint.X, screenPoint.Y, 0, false, game, 0)
        end
    end)
    
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
               Content = "マップ内にピアノがありません。スポーンしてください！",
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
        
        if next(pianoKeys) == nil then
            Rayfield:Notify({
               Title = "❌ 鍵盤が見つかりません",
               Content = "ピアノに鍵盤（C, D, E等）が見つかりませんでした",
               Duration = 5,
               Image = 4483362458
            })
            Settings.AutoPlayEnabled = false
            return
        end
        
        Rayfield:Notify({
           Title = "✅ ピアノ発見！",
           Content = string.format("見つかった鍵盤: %d個", #pianoKeys),
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
                for i = 1, #currentSong.Notes do
                    if not Settings.AutoPlayEnabled then break end
                    
                    local noteName = currentSong.Notes[i]
                    local duration = currentSong.Durations[i] or 0.4
                    
                    local keyPart = pianoKeys[noteName]
                    
                    if keyPart then
                        -- カメラを鍵盤に向ける
                        if Settings.AutoFocusCamera then
                            positionCameraAtPiano(currentPianoModel, keyPart)
                        end
                        
                        task.wait(Settings.ClickDelay)
                        
                        -- 鍵盤をクリック
                        pcall(function()
                            clickPianoKey(keyPart)
                        end)
                    end
                    
                    task.wait(math.max(duration, Settings.NoteGap))
                end
            end
            
            task.wait(Settings.LoopDelay)
        end
        
        -- カメラをリセット
        Camera.CameraType = Enum.CameraType.Custom
    end)
end

-- GUI作成
local MainTab = Window:CreateTab("🎵 メイン", 4483362458)
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
   Options = {"きらきら星", "メリーさんの羊", "ハッピーバースデー", "かえるの歌", "ドレミの歌", "チューリップ"},
   CurrentOption = {"きらきら星"},
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
           
           -- 詳細情報を出力
           for i, piano in ipairs(foundPianos) do
               print(string.format("ピアノ %d: %s", i, piano.Name))
           end
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

-- 情報タブ
InfoTab:CreateSection("📖 使い方")

InfoTab:CreateParagraph({
    Title = "ステップ 1",
    Content = "ゲーム内で青いピアノをスポーンする（お店から購入してスポーン）"
})

InfoTab:CreateParagraph({
    Title = "ステップ 2",
    Content = "「ピアノを探す」ボタンを押してピアノを検出"
})

InfoTab:CreateParagraph({
    Title = "ステップ 3",
    Content = "曲を選んで「自動演奏」をオン！"
})

InfoTab:CreateSection("ℹ️ スクリプト情報")

InfoTab:CreateLabel("Fling Things and People - Auto Piano v2.0")
InfoTab:CreateLabel("青いピアノ対応")
InfoTab:CreateLabel("")
InfoTab:CreateLabel("✓ 広範囲ピアノ検索")
InfoTab:CreateLabel("✓ 青色ピアノ自動検出")
InfoTab:CreateLabel("✓ 6曲搭載")
InfoTab:CreateLabel("✓ カメラ追従機能")

InfoTab:CreateSection("⚠️ 注意")

InfoTab:CreateParagraph({
    Title = "ピアノが見つからない場合",
    Content = "• ゲーム内でピアノをスポーンしてください\n• お店（Shop）から青いピアノを購入\n• スポーンした後「ピアノを探す」を押す"
})

InfoTab:CreateParagraph({
    Title = "対応ピアノ",
    Content = "• 青色のピアノ\n• C, D, E, F, G, A, B の鍵盤があるもの\n• ProximityPrompt または ClickDetector付き"
})

-- 初期通知
Rayfield:Notify({
   Title = "🎹 Auto Piano 準備完了",
   Content = "青いピアノをスポーンしてください！",
   Duration = 5,
   Image = 4483362458
})

-- 自動検索
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
           Content = "青いピアノをスポーンしてから「ピアノを探す」を押してください",
           Duration = 5,
           Image = 4483362458
        })
    end
end)

print("🎹 Fling Things and People - Auto Piano 読み込み完了!")
print("🔍 広範囲ピアノ検索モード有効")
