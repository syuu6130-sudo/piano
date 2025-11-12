--[[
    Auto Piano Player for "Fling Things and People"
    Works with spawned blue piano toys
    
    Features:
    - Finds ANY piano in the game (spawned or placed)
    - Clicks piano keys automatically
    - Camera auto-positioning
    - Multiple songs including Libra Heart
    - Position lock at piano
    - Playback speed control
    
    PART 1 OF 2
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "🎹 Fling Piano Auto Player",
   LoadingTitle = "ピアノ自動演奏読み込み中...",
   LoadingSubtitle = "青いピアノ対応版 v3.0",
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

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Settings = {
    AutoPlayEnabled = false,
    AutoFocusCamera = true,
    ClickDelay = 0.08,
    NoteGap = 0.05,
    LoopDelay = 2,
    CurrentSong = 1,
    TeleportToPiano = false,
    SearchRadius = 500,
    PlaySpeed = 1.0,
    StayAtPiano = true
}

local Songs = {
    {
        Name = "きらきら星",
        Notes = {"C", "C", "G", "G", "A", "A", "G", "F", "F", "E", "E", "D", "D", "C"},
        Durations = {0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.8, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.8}
    },
    {
        Name = "メリーさんの羊",
        Notes = {"E", "D", "C", "D", "E", "E", "E", "D", "D", "D", "E", "G", "G"},
        Durations = {0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.8, 0.4, 0.4, 0.8, 0.4, 0.4, 0.8}
    },
    {
        Name = "ハッピーバースデー",
        Notes = {"C", "C", "D", "C", "F", "E", "C", "C", "D", "C", "G", "F"},
        Durations = {0.3, 0.3, 0.6, 0.6, 0.6, 1.2, 0.3, 0.3, 0.6, 0.6, 0.6, 1.2}
    },
    {
        Name = "かえるの歌",
        Notes = {"C", "D", "E", "F", "E", "D", "C", "E", "F", "G", "A", "G", "F", "E"},
        Durations = {0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.8, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.8}
    },
    {
        Name = "ドレミの歌",
        Notes = {"C", "D", "E", "C", "E", "C", "E", "D", "E", "F", "F", "E", "D", "F"},
        Durations = {0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.8, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.8}
    },
    {
        Name = "チューリップ",
        Notes = {"C", "D", "E", "C", "E", "F", "E", "D", "C", "E", "G", "G", "E", "D", "C"},
        Durations = {0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.8}
    },
    {
        Name = "Libra Heart - imaizumiyui",
        Notes = {
            "D#", "F#", "G#", "A#", "G#", "F#", "D#", "rest",
            "D#", "F#", "G#", "B", "A#", "G#", "F#",
            "C#", "D#", "F#", "F#", "G#", "F#", "D#", "rest",
            "D#", "F#", "G#", "A#", "B", "A#", "G#", "rest",
            "C#", "D#", "F#", "F#", "G#", "A#", "B", "rest",
            "B", "A#", "G#", "F#", "D#", "F#", "G#",
            "B", "B", "A#", "G#", "F#", "G#", "F#", "D#", "rest",
            "D#", "F#", "G#", "A#", "B", "B", "A#", "rest",
            "B", "B", "C#", "D#", "F#", "G#", "F#", "D#", "rest",
            "F#", "G#", "A#", "B", "A#", "G#", "F#",
            "D#", "D#", "F#", "G#", "A#", "B", "A#", "G#", "rest",
            "F#", "F#", "G#", "A#", "B", "C#", "D#", "rest",
            "B", "A#", "G#", "F#", "G#", "F#", "D#", "rest",
            "D#", "F#", "G#", "B", "A#", "G#", "F#"
        },
        Durations = {
            0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.6, 0.2,
            0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.8,
            0.3, 0.3, 0.5, 0.3, 0.3, 0.3, 0.5, 0.2,
            0.3, 0.3, 0.5, 0.3, 0.4, 0.4, 0.6, 0.2,
            0.3, 0.3, 0.5, 0.3, 0.3, 0.3, 0.5, 0.2,
            0.3, 0.3, 0.5, 0.3, 0.4, 0.4, 0.8,
            0.4, 0.3, 0.3, 0.4, 0.3, 0.3, 0.4, 0.4, 0.2,
            0.3, 0.3, 0.4, 0.4, 0.4, 0.4, 0.6, 0.2,
            0.4, 0.3, 0.3, 0.4, 0.4, 0.4, 0.4, 0.4, 0.2,
            0.3, 0.3, 0.4, 0.4, 0.4, 0.4, 0.8,
            0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.2,
            0.3, 0.3, 0.4, 0.4, 0.4, 0.4, 0.8, 0.3,
            0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.6, 0.2,
            0.4, 0.4, 0.4, 0.4, 0.6, 0.6, 1.2
        }
    }
}

local currentPianoModel = nil
local pianoKeys = {}
local autoPlayThread = nil
local foundPianos = {}
local positionLockThread = nil

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
                           part.Name == "F#" or part.Name == "G#" or part.Name == "A#" or
                           part.Name:find("Key") or part.Name:find("Button") then
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
               (obj.Name == "C" or obj.Name == "D" or obj.Name == "E" or 
                obj.Name == "F" or obj.Name == "G" or obj.Name == "A" or 
                obj.Name == "B" or obj.Name == "C#" or obj.Name == "D#" or
                obj.Name == "F#" or obj.Name == "G#" or obj.Name == "A#") then
                
                local parent = obj.Parent
                if parent and parent:IsA("Model") and not table.find(pianos, parent) then
                    table.insert(pianos, parent)
                end
            end
        end
    end
    
    return pianos
end

local function getPianoKeys(pianoModel)
    local keys = {}
    
    if not pianoModel then return keys end
    
    for _, obj in ipairs(pianoModel:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name
            
            if name == "C" or name == "D" or name == "E" or name == "F" or 
               name == "G" or name == "A" or name == "B" or
               name == "C#" or name == "D#" or name == "F#" or 
               name == "G#" or name == "A#" then
                keys[name] = obj
            elseif name:match("^[CDEFGAB]#?$") then
                keys[name] = obj
            elseif name:find("Key") and (name:find("C") or name:find("D") or 
                   name:find("E") or name:find("F") or name:find("G") or 
                   name:find("A") or name:find("B")) then
                for _, note in ipairs({"C", "D", "E", "F", "G", "A", "B", "C#", "D#", "F#", "G#", "A#"}) do
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

local function teleportToPiano(pianoModel)
    if not pianoModel then return end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
    
    pcall(function()
        local pianoPos = pianoModel:GetModelCFrame().Position
        local pianoCFrame = pianoModel:GetModelCFrame()
        local frontOffset = pianoCFrame.LookVector * -5
        local teleportPos = pianoPos + frontOffset + Vector3.new(0, 3, 0)
        
        LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(teleportPos, pianoPos))
    end)
end

local function lockPlayerPosition(pianoModel)
    if positionLockThread then
        task.cancel(positionLockThread)
    end
    
    if not Settings.StayAtPiano then return end
    
    positionLockThread = task.spawn(function()
        while Settings.AutoPlayEnabled and Settings.StayAtPiano do
            if pianoModel and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                pcall(function()
                    local pianoPos = pianoModel:GetModelCFrame().Position
                    local pianoCFrame = pianoModel:GetModelCFrame()
                    local frontOffset = pianoCFrame.LookVector * -5
                    local targetPos = pianoPos + frontOffset + Vector3.new(0, 3, 0)
                    
                    LocalPlayer.Character.PrimaryPart.CFrame = CFrame.new(targetPos, pianoPos)
                    LocalPlayer.Character.PrimaryPart.Velocity = Vector3.new(0, 0, 0)
                    LocalPlayer.Character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end)
            end
            task.wait(0.1)
        end
    end)
end

print("🎹 Part 1 loaded! Copy and run Part 2 next...")
-- PART 2 OF 2 - Continue from Part 1

local function startAutoPlay()
    if autoPlayThread then
        task.cancel(autoPlayThread)
    end
    
    autoPlayThread = task.spawn(function()
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
        
        local keyCount = 0
        for _ in pairs(pianoKeys) do
            keyCount = keyCount + 1
        end
        
        Rayfield:Notify({
           Title = "✅ ピアノ発見！",
           Content = string.format("見つかった鍵盤: %d個", keyCount),
           Duration = 3,
           Image = 4483362458
        })
        
        teleportToPiano(currentPianoModel)
        task.wait(0.5)
        
        lockPlayerPosition(currentPianoModel)
        positionCameraAtPiano(currentPianoModel, nil)
        
        while Settings.AutoPlayEnabled do
            local currentSong = Songs[Settings.CurrentSong]
            if currentSong then
                for i = 1, #currentSong.Notes do
                    if not Settings.AutoPlayEnabled then break end
                    
                    local noteName = currentSong.Notes[i]
                    local duration = (currentSong.Durations[i] or 0.4) / Settings.PlaySpeed
                    
                    if noteName ~= "rest" then
                        local keyPart = pianoKeys[noteName]
                        
                        if keyPart then
                            if Settings.AutoFocusCamera then
                                positionCameraAtPiano(currentPianoModel, keyPart)
                            end
                            
                            task.wait(Settings.ClickDelay / Settings.PlaySpeed)
                            
                            pcall(function()
                                clickPianoKey(keyPart)
                            end)
                        end
                    end
                    
                    task.wait(math.max(duration, Settings.NoteGap / Settings.PlaySpeed))
                end
            end
            
            task.wait(Settings.LoopDelay)
        end
        
        if positionLockThread then
            task.cancel(positionLockThread)
        end
        
        Camera.CameraType = Enum.CameraType.Custom
    end)
end

local MainTab = Window:CreateTab("🎵 メイン", 4483362458)
local SettingsTab = Window:CreateTab("⚙️ 設定", 4483362458)
local InfoTab = Window:CreateTab("ℹ️ 情報", 4483362458)

local PlaySection = MainTab:CreateSection("再生コントロール")

MainTab:CreateToggle({
   Name = "🎹 自動演奏",
   CurrentValue = false,
   Flag = "AutoPlayToggle",
   Callback = function(Value)
       Settings.AutoPlayEnabled = Value
       if Value then
           startAutoPlay()
       else
           if autoPlayThread then task.cancel(autoPlayThread) end
           if positionLockThread then task.cancel(positionLockThread) end
           Camera.CameraType = Enum.CameraType.Custom
           Rayfield:Notify({Title = "⏸️ 停止", Content = "演奏を停止しました", Duration = 2, Image = 4483362458})
       end
   end
})

MainTab:CreateDropdown({
   Name = "曲を選択",
   Options = {"きらきら星", "メリーさんの羊", "ハッピーバースデー", "かえるの歌", "ドレミの歌", "チューリップ", "Libra Heart - imaizumiyui"},
   CurrentOption = {"きらきら星"},
   MultipleOptions = false,
   Flag = "SongDropdown",
   Callback = function(Option)
       for i, song in ipairs(Songs) do
           if song.Name == Option[1] then
               Settings.CurrentSong = i
               Rayfield:Notify({Title = "🎵 曲変更", Content = song.Name, Duration = 2, Image = 4483362458})
               break
           end
       end
   end
})

local CameraSection = MainTab:CreateSection("カメラ＆位置")

MainTab:CreateToggle({
   Name = "📹 カメラ自動追従",
   CurrentValue = true,
   Flag = "AutoFocusToggle",
   Callback = function(Value)
       Settings.AutoFocusCamera = Value
       if not Value then Camera.CameraType = Enum.CameraType.Custom end
   end
})

MainTab:CreateToggle({
   Name = "📍 ピアノの前に固定",
   CurrentValue = true,
   Flag = "StayAtPianoToggle",
   Callback = function(Value)
       Settings.StayAtPiano = Value
       if Value and Settings.AutoPlayEnabled and currentPianoModel then
           lockPlayerPosition(currentPianoModel)
       elseif not Value and positionLockThread then
           task.cancel(positionLockThread)
       end
   end
})

local ManualSection = MainTab:CreateSection("手動操作")

MainTab:CreateButton({
   Name = "🔍 ピアノを探す",
   Callback = function()
       foundPianos = findAllPianos()
       if #foundPianos > 0 then
           Rayfield:Notify({Title = "✅ ピアノ発見！", Content = string.format("%d個のピアノが見つかりました", #foundPianos), Duration = 4, Image = 4483362458})
           for i, piano in ipairs(foundPianos) do print(string.format("ピアノ %d: %s", i, piano.Name)) end
       else
           Rayfield:Notify({Title = "❌ ピアノなし", Content = "青いピアノをスポーンしてください！", Duration = 5, Image = 4483362458})
       end
   end
})

MainTab:CreateButton({
   Name = "🎹 今すぐテレポート",
   Callback = function()
       if currentPianoModel then
           teleportToPiano(currentPianoModel)
           Rayfield:Notify({Title = "✅ テレポート完了", Content = "ピアノの前に移動しました", Duration = 2, Image = 4483362458})
       else
           Rayfield:Notify({Title = "❌ ピアノ未設定", Content = "先に「ピアノを探す」を押してください", Duration = 3, Image = 4483362458})
       end
   end
})

MainTab:CreateButton({
   Name = "🧪 テスト (C音)",
   Callback = function()
       if pianoKeys["C"] then
           clickPianoKey(pianoKeys["C"])
           Rayfield:Notify({Title = "✅ テスト成功", Content = "C音を鳴らしました", Duration = 2, Image = 4483362458})
       else
           Rayfield:Notify({Title = "❌ C鍵盤なし", Content = "C鍵盤が見つかりません", Duration = 3, Image = 4483362458})
       end
   end
})

local SpeedSection = SettingsTab:CreateSection("⚡ 再生速度")

SettingsTab:CreateSlider({
   Name = "🎵 再生速度",
   Range = {0.25, 3.0},
   Increment = 0.25,
   Suffix = "x",
   CurrentValue = 1.0,
   Flag = "PlaySpeedSlider",
   Callback = function(Value)
       Settings.PlaySpeed = Value
       Rayfield:Notify({Title = "⚡ 速度変更", Content = string.format("%.2fx 速度", Value), Duration = 2, Image = 4483362458})
   end
})

SettingsTab:CreateLabel("0.25x = 超ゆっくり | 1.0x = 通常 | 3.0x = 超高速")

local TimingSection = SettingsTab:CreateSection("詳細タイミング")

SettingsTab:CreateSlider({Name = "クリック遅延", Range = {0.01, 0.3}, Increment = 0.01, Suffix = "秒", CurrentValue = 0.08, Flag = "ClickDelaySlider", Callback = function(Value) Settings.ClickDelay = Value end})
SettingsTab:CreateSlider({Name = "音符間隔", Range = {0.01, 0.5}, Increment = 0.01, Suffix = "秒", CurrentValue = 0.05, Flag = "NoteGapSlider", Callback = function(Value) Settings.NoteGap = Value end})
SettingsTab:CreateSlider({Name = "ループ待機", Range = {0.5, 10}, Increment = 0.5, Suffix = "秒", CurrentValue = 2, Flag = "LoopDelaySlider", Callback = function(Value) Settings.LoopDelay = Value end})

InfoTab:CreateSection("📖 使い方")
InfoTab:CreateParagraph({Title = "ステップ 1", Content = "ゲーム内で青いピアノをスポーンする"})
InfoTab:CreateParagraph({Title = "ステップ 2", Content = "「ピアノを探す」ボタンを押してピアノを検出"})
InfoTab:CreateParagraph({Title = "ステップ 3", Content = "曲を選んで「自動演奏」をオン！自動的にピアノの前にテレポートします"})

InfoTab:CreateSection("ℹ️ スクリプト情報")
InfoTab:CreateLabel("Fling Piano Auto Player v3.0")
InfoTab:CreateLabel("✓ 7曲搭載（Libra Heart含む）")
InfoTab:CreateLabel("✓ 再生速度調整 (0.25x - 3.0x)")
InfoTab:CreateLabel("✓ ピアノ前固定機能")
InfoTab:CreateLabel("✓ シャープ(#)鍵盤対応")

InfoTab:CreateSection("🎵 搭載曲")
InfoTab:CreateLabel("1-6. 童謡6曲")
InfoTab:CreateLabel("7. Libra Heart - imaizumiyui ⭐")

Rayfield:Notify({Title = "🎹 Auto Piano v3.0 準備完了", Content = "再生速度調整＆位置固定機能搭載！", Duration = 5, Image = 4483362458})

task.spawn(function()
    task.wait(3)
    foundPianos = findAllPianos()
    if #foundPianos > 0 then
        Rayfield:Notify({Title = "✅ ピアノ自動検出", Content = string.format("%d個のピアノが見つかりました！", #foundPianos), Duration = 4, Image = 4483362458})
    else
        Rayfield:Notify({Title = "ℹ️ ピアノ未検出", Content = "青いピアノをスポーンしてください", Duration = 5, Image = 4483362458})
    end
end)

print("🎹 Auto Piano v3.0 読み込み完了!")
print("⚡ 新機能: 再生速度調整 & ピアノ前固定")
