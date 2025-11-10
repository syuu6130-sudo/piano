--// Rayfield Piano Auto Player
--// Song: Libra Heart (imaizumiyui)
--// Game: Fling Things and People
--// Author: @jpneko03016 + ChatGPT (Extended Full Version)

--// ⚙️ ライブラリ読み込み
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--// 🧩 設定
local Settings = {
    AutoPlayEnabled = false,
    AutoFocusCamera = true,
    ClickDelay = 0.08,
    NoteGap = 0.05,
    LoopDelay = 3,
    PlaySpeed = 1.0,
    TeleportToPiano = false
}

--// 🎵 曲データ
local LibraHeartSong = {
    Name = "Libra Heart - imaizumiyui",
    Intro = {
        {Key="C4",Length=0.25},{Key="E4",Length=0.25},{Key="G4",Length=0.5},
        {Key="C5",Length=0.5},{Key="E5",Length=0.5},{Key="G5",Length=1.0}
    },
    VerseA = {
        {Key="E4",Length=0.25},{Key="F4",Length=0.25},{Key="G4",Length=0.25},
        {Key="A4",Length=0.5},{Key="G4",Length=0.5},{Key="F4",Length=0.5}
    },
    Chorus = {
        {Key="C5",Length=0.25},{Key="D5",Length=0.25},{Key="E5",Length=0.5},
        {Key="F5",Length=0.25},{Key="G5",Length=0.25},{Key="A5",Length=0.5},
        {Key="G5",Length=0.75},{Key="E5",Length=0.5}
    },
    Bridge = {
        {Key="A4",Length=0.25},{Key="G4",Length=0.25},{Key="E4",Length=0.25},
        {Key="D4",Length=0.25},{Key="C4",Length=0.5}
    },
    Outro = {
        {Key="C5",Length=0.5},{Key="G4",Length=0.5},{Key="E4",Length=0.5},
        {Key="C4",Length=1.0}
    }
}

--// 🧠 ピアノ検出
local pianoKeys = {}

local function findAllPianos()
    local pianos = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("C4") then
            table.insert(pianos, obj)
        end
    end
    return pianos
end

local function getPianoKeys(piano)
    local keys = {}
    for _, part in ipairs(piano:GetDescendants()) do
        if part:IsA("BasePart") and string.match(part.Name, "[A-G]#?%d") then
            keys[part.Name] = part
        end
    end
    return keys
end

--// 🎯 鍵盤クリック処理
local function clickPianoKey(keyPart)
    if not keyPart then return end
    local click = keyPart:FindFirstChildOfClass("ClickDetector")
    local prox = keyPart:FindFirstChildOfClass("ProximityPrompt")
    if click then
        fireclickdetector(click)
    elseif prox then
        fireproximityprompt(prox)
    end
end

--// 🎥 カメラ制御
local function focusCameraOnPiano(piano)
    if not Settings.AutoFocusCamera then return end
    local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and piano:FindFirstChild("C4") then
        workspace.CurrentCamera.CameraSubject = piano:FindFirstChild("C4")
    end
end

--// 🧍 テレポート
local function teleportToPiano(piano)
    local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and piano.PrimaryPart then
        hrp.CFrame = piano.PrimaryPart.CFrame * CFrame.new(0, 0, -5)
    end
end

--// 🎶 演奏処理
local function playSection(piano, section)
    for _, note in ipairs(section) do
        if not Settings.AutoPlayEnabled then return end
        local part = pianoKeys[note.Key]
        if part then
            clickPianoKey(part)
        end
        task.wait((note.Length + Settings.NoteGap) * (1 / Settings.PlaySpeed))
    end
end

--// 🔁 メイン再生
local function startAutoPlay(song)
    local pianos = findAllPianos()
    if #pianos == 0 then
        Rayfield:Notify({Title = "エラー", Content = "ピアノが見つかりません。近くに移動してください。", Duration = 4})
        return
    end

    local piano = pianos[1]
    pianoKeys = getPianoKeys(piano)

    if Settings.TeleportToPiano then
        teleportToPiano(piano)
    end

    focusCameraOnPiano(piano)

    Rayfield:Notify({Title = "開始", Content = song.Name .. " を演奏します。", Duration = 3})

    while Settings.AutoPlayEnabled do
        for _, section in pairs(song) do
            if typeof(section) == "table" then
                playSection(piano, section)
            end
        end
        task.wait(Settings.LoopDelay)
    end

    Rayfield:Notify({Title = "停止", Content = "自動演奏を停止しました。", Duration = 3})
end

--// 🖥️ UI構築
local Window = Rayfield:CreateWindow({
    Name = "🎹 Libra Heart Auto Piano",
    LoadingTitle = "Libra Heart - imaizumiyui",
    LoadingSubtitle = "Rayfield Auto Player",
    ConfigurationSaving = {Enabled = true, FolderName = "AutoPiano"}
})

local Tab = Window:CreateTab("🎼 演奏")
local SettingsTab = Window:CreateTab("⚙️ 設定")

Tab:CreateToggle({
    Name = "🎵 自動演奏 (Libra Heart)",
    CurrentValue = false,
    Callback = function(value)
        Settings.AutoPlayEnabled = value
        if value then
            startAutoPlay(LibraHeartSong)
        end
    end
})

Tab:CreateButton({
    Name = "🔍 ピアノ検出",
    Callback = function()
        local pianos = findAllPianos()
        Rayfield:Notify({
            Title = "ピアノ検出",
            Content = tostring(#pianos) .. " 台のピアノを見つけました。",
            Duration = 3
        })
    end
})

SettingsTab:CreateToggle({
    Name = "📹 カメラ追従",
    CurrentValue = Settings.AutoFocusCamera,
    Callback = function(v) Settings.AutoFocusCamera = v end
})

SettingsTab:CreateToggle({
    Name = "🚶‍♂️ ピアノへ自動移動",
    CurrentValue = Settings.TeleportToPiano,
    Callback = function(v) Settings.TeleportToPiano = v end
})

SettingsTab:CreateSlider({
    Name = "🎚️ 再生速度",
    Range = {0.5, 2.0},
    Increment = 0.1,
    CurrentValue = 1.0,
    Callback = function(v) Settings.PlaySpeed = v end
})

SettingsTab:CreateSlider({
    Name = "⏱️ 音符間隔",
    Range = {0.0, 0.2},
    Increment = 0.01,
    CurrentValue = Settings.NoteGap,
    Callback = function(v) Settings.NoteGap = v end
})

SettingsTab:CreateSlider({
    Name = "🔁 ループ間隔",
    Range = {0, 5},
    Increment = 0.5,
    CurrentValue = Settings.LoopDelay,
    Callback = function(v) Settings.LoopDelay = v end
})

Rayfield:Notify({
    Title = "🎹 Libra Heart Piano",
    Content = "ロード完了！UIから演奏を開始できます。",
    Duration = 4
})
