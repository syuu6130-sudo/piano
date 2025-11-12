-- PART 2 OF 2 - Continue from Part 1

-- 自動演奏開始
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
               Content = "ピアノに鍵盤（C, D, E等）が見つかりませんでした",
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
        
        -- ピアノの前にテレポート
        teleportToPiano(currentPianoModel)
        task.wait(0.5)
        
        -- 位置固定を開始
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
        
        -- 位置固定を解除
        if positionLockThread then
            task.cancel(positionLockThread)
        end
        
        Camera.CameraType = Enum.CameraType.Custom
    end)
end

-- GUI作成
local MainTab = Window:CreateTab("🎵 メイン", 4483362458)
local SettingsTab = Window:CreateTab("⚙️ 設定", 4483362458)
local InfoTab = Window:CreateTab("ℹ️ 情報", 4483362458)

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
           if positionLockThread then
               task.cancel(positionLockThread)
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
   Options = {"きらきら星", "メリーさんの羊", "ハッピーバースデー", "かえるの歌", "ドレミの歌", "チューリップ", "Libra Heart - imaizumiyui"},
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

local StayAtPianoToggle = MainTab:CreateToggle({
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
              Content = "ピアノの前に移動しました",
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

local TimingSection = SettingsTab:CreateSection("再生速度")

local PlaySpeedSlider = SettingsTab:CreateSlider({
   Name = "🎵 再生速度",
   Range = {0.25, 3.0},
   Increment = 0.25,
   Suffix = "x",
   CurrentValue = 1.0,
   Flag = "PlaySpeedSlider",
   Callback = function(Value)
       Settings.PlaySpeed = Value
       Rayfield:Notify({
          Title = "⚡ 速度変更",
          Content = string.format("%.2fx 速度", Value),
          Duration = 2,
          Image = 4483362458
       })
   end
})

SettingsTab:CreateLabel("0.25x = 超ゆっくり | 1.0x = 通常 | 3.0x = 超高速")

local AdvancedTimingSection = SettingsTab:CreateSection("詳細タイミング")

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
    Content = "曲を選んで「自動演奏」をオン！自動的にピアノの前にテレポートします"
})

InfoTab:CreateSection("ℹ️ スクリプト情報")

InfoTab:CreateLabel("Fling Things and People - Auto Piano v2.5")
InfoTab:CreateLabel("青いピアノ対応")
InfoTab:CreateLabel("")
InfoTab:CreateLabel("✓ 広範囲ピアノ検索")
InfoTab:CreateLabel("✓ 青色ピアノ自動検出")
InfoTab:CreateLabel("✓ 7曲搭載（Libra Heart含む）")
InfoTab:CreateLabel("✓ カメラ追従機能")
InfoTab:CreateLabel("✓ シャープ(#)鍵盤対応")
InfoTab:CreateLabel("✓ 再生速度調整 (0.25x - 3.0x)")
InfoTab:CreateLabel("✓ ピアノ前固定機能")

InfoTab:CreateSection("🎵 搭載曲")

InfoTab:CreateLabel("1. きらきら星")
InfoTab:CreateLabel("2. メリーさんの羊")
InfoTab:CreateLabel("3. ハッピーバースデー")
InfoTab:CreateLabel("4. かえるの歌")
InfoTab:CreateLabel("5. ドレミの歌")
InfoTab:CreateLabel("6. チューリップ")
InfoTab:CreateLabel("7. Libra Heart - imaizumiyui ⭐NEW")

InfoTab:CreateSection("⚡ 新機能")

InfoTab:CreateParagraph({
    Title = "再生速度調整",
    Content = "0.25x（超ゆっくり）から3.0x（超高速）まで調整可能！曲のテンポを自由に変更できます。"
})

InfoTab:CreateParagraph({
    Title = "位置固定機能",
    Content = "演奏中、ピアノの正面に自動でテレポートし、その場に固定されます。演奏に集中できます！"
})

InfoTab:CreateSection("⚠️ 注意")

InfoTab:CreateParagraph({
    Title = "ピアノが見つからない場合",
    Content = "• ゲーム内でピアノをスポーンしてください\n• お店（Shop）から青いピアノを購入\n• スポーンした後「ピアノを探す」を押す"
})

InfoTab:CreateParagraph({
    Title = "対応ピアノ",
    Content = "• 青色のピアノ\n• C, D, E, F, G, A, B の鍵盤があるもの\n• シャープ(#)鍵盤: C#, D#, F#, G#, A#\n• ProximityPrompt または ClickDetector付き"
})

InfoTab:CreateParagraph({
    Title = "Libra Heartについて",
    Content = "Libra Heartを演奏するにはシャープ(#)付きの黒鍵が必要です。青いピアノに黒鍵がない場合、一部の音が鳴らない可能性があります。"
})

Rayfield:Notify({
   Title = "🎹 Auto Piano v2.5 準備完了",
   Content = "再生速度調整＆位置固定機能追加！",
   Duration = 5,
   Image = 4483362458
})

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

print("🎹 Fling Things and People - Auto Piano v2.5 読み込み完了!")
print("🔍 広範囲ピアノ検索モード有効")
print("🎵 Libra Heart 搭載！")
print("⚡ 再生速度調整機能搭載！")
print("📍 位置固定機能搭載！")
-- PART 2 OF 2 - Continue from Part 1

-- 自動演奏開始
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
               Content = "ピアノに鍵盤（C, D, E等）が見つかりませんでした",
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
        
        -- ピアノの前にテレポート
        teleportToPiano(currentPianoModel)
        task.wait(0.5)
        
        -- 位置固定を開始
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
        
        -- 位置固定を解除
        if positionLockThread then
            task.cancel(positionLockThread)
        end
        
        Camera.CameraType = Enum.CameraType.Custom
    end)
end

-- GUI作成
local MainTab = Window:CreateTab("🎵 メイン", 4483362458)
local SettingsTab = Window:CreateTab("⚙️ 設定", 4483362458)
local InfoTab = Window:CreateTab("ℹ️ 情報", 4483362458)

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
           if positionLockThread then
               task.cancel(positionLockThread)
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
   Options = {"きらきら星", "メリーさんの羊", "ハッピーバースデー", "かえるの歌", "ドレミの歌", "チューリップ", "Libra Heart - imaizumiyui"},
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

local StayAtPianoToggle = MainTab:CreateToggle({
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
              Content = "ピアノの前に移動しました",
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

local TimingSection = SettingsTab:CreateSection("再生速度")

local PlaySpeedSlider = SettingsTab:CreateSlider({
   Name = "🎵 再生速度",
   Range = {0.25, 3.0},
   Increment = 0.25,
   Suffix = "x",
   CurrentValue = 1.0,
   Flag = "PlaySpeedSlider",
   Callback = function(Value)
       Settings.PlaySpeed = Value
       Rayfield:Notify({
          Title = "⚡ 速度変更",
          Content = string.format("%.2fx 速度", Value),
          Duration = 2,
          Image = 4483362458
       })
   end
})

SettingsTab:CreateLabel("0.25x = 超ゆっくり | 1.0x = 通常 | 3.0x = 超高速")

local AdvancedTimingSection = SettingsTab:CreateSection("詳細タイミング")

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
    Content = "曲を選んで「自動演奏」をオン！自動的にピアノの前にテレポートします"
})

InfoTab:CreateSection("ℹ️ スクリプト情報")

InfoTab:CreateLabel("Fling Things and People - Auto Piano v2.5")
InfoTab:CreateLabel("青いピアノ対応")
InfoTab:CreateLabel("")
InfoTab:CreateLabel("✓ 広範囲ピアノ検索")
InfoTab:CreateLabel("✓ 青色ピアノ自動検出")
InfoTab:CreateLabel("✓ 7曲搭載（Libra Heart含む）")
InfoTab:CreateLabel("✓ カメラ追従機能")
InfoTab:CreateLabel("✓ シャープ(#)鍵盤対応")
InfoTab:CreateLabel("✓ 再生速度調整 (0.25x - 3.0x)")
InfoTab:CreateLabel("✓ ピアノ前固定機能")

InfoTab:CreateSection("🎵 搭載曲")

InfoTab:CreateLabel("1. きらきら星")
InfoTab:CreateLabel("2. メリーさんの羊")
InfoTab:CreateLabel("3. ハッピーバースデー")
InfoTab:CreateLabel("4. かえるの歌")
InfoTab:CreateLabel("5. ドレミの歌")
InfoTab:CreateLabel("6. チューリップ")
InfoTab:CreateLabel("7. Libra Heart - imaizumiyui ⭐NEW")

InfoTab:CreateSection("⚡ 新機能")

InfoTab:CreateParagraph({
    Title = "再生速度調整",
    Content = "0.25x（超ゆっくり）から3.0x（超高速）まで調整可能！曲のテンポを自由に変更できます。"
})

InfoTab:CreateParagraph({
    Title = "位置固定機能",
    Content = "演奏中、ピアノの正面に自動でテレポートし、その場に固定されます。演奏に集中できます！"
})

InfoTab:CreateSection("⚠️ 注意")

InfoTab:CreateParagraph({
    Title = "ピアノが見つからない場合",
    Content = "• ゲーム内でピアノをスポーンしてください\n• お店（Shop）から青いピアノを購入\n• スポーンした後「ピアノを探す」を押す"
})

InfoTab:CreateParagraph({
    Title = "対応ピアノ",
    Content = "• 青色のピアノ\n• C, D, E, F, G, A, B の鍵盤があるもの\n• シャープ(#)鍵盤: C#, D#, F#, G#, A#\n• ProximityPrompt または ClickDetector付き"
})

InfoTab:CreateParagraph({
    Title = "Libra Heartについて",
    Content = "Libra Heartを演奏するにはシャープ(#)付きの黒鍵が必要です。青いピアノに黒鍵がない場合、一部の音が鳴らない可能性があります。"
})

Rayfield:Notify({
   Title = "🎹 Auto Piano v2.5 準備完了",
   Content = "再生速度調整＆位置固定機能追加！",
   Duration = 5,
   Image = 4483362458
})

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

print("🎹 Fling Things and People - Auto Piano v2.5 読み込み完了!")
print("🔍 広範囲ピアノ検索モード有効")
print("🎵 Libra Heart 搭載！")
print("⚡ 再生速度調整機能搭載！")
print("📍 位置固定機能搭載！")
