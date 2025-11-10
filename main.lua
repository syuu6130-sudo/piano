-- Libra Heart Auto Piano
-- For: Fling Things and People (Blue piano by YamaRolanSio)
-- Features: auto-detect piano, move player to ~7 studs behind, face piano, Rayfield UI (toggle/play/stop/speed/loop), fire ClickDetectors / ProximityPrompts
-- NOTE: This script is intended for educational / personal use. Using automated inputs may violate the game's rules.

-- === CONFIG ===
local RAYFIELD_URL = "https://raw.githubusercontent.com/HexagonG/Rayfield/main/source.lua" -- replace with your Rayfield loader if different
local PIANO_NAME_KEYWORD = "piano" -- name must contain this (case-insensitive)
local TARGET_COLOR = Color3.fromRGB(0, 170, 255) -- blue RGB guess; change if needed
local DISTANCE_BEHIND = 7 -- studs behind the piano's PrimaryPart
local CAMERA_HEIGHT_OFFSET = Vector3.new(0, 3, 0) -- camera offset above HRP
local MOVE_TELEPORT = true -- whether to instantly set CFrame (true) or attempt tween (false)
local TWEEN_TIME = 0.35

-- === SONG DATA (simplified / approximate) ===
-- This is a playable approximation of "Libra Heart" melody. Each entry is {partName = "KeyNameOrPart", wait = seconds}
-- You will likely need to adapt `partName` to the actual piano key part names in the game.
local song = {
    -- Intro / motif (example sequence)
    {part = "C4", wait = 0.4}, {part = "E4", wait = 0.4}, {part = "G4", wait = 0.6},
    {part = "E4", wait = 0.4}, {part = "C4", wait = 0.4}, {part = "D4", wait = 0.8},
    -- Add more notes here to fully encode the song. This is a shorter demo.
}

-- === INTERNAL STATE ===
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = workspace

local PianoModel = nil
local Playing = false
local Looping = false
local Speed = 1
local Rayfield = nil

-- Utility: safe wait
local function safeWait(t)
    if t and t > 0 then
        task.wait(t)
    else
        task.wait()
    end
end

-- Try to load Rayfield (graceful)
local function loadRayfield()
    local ok, rf = pcall(function()
        return loadstring(game:HttpGet(RAYFIELD_URL))()
    end)
    if ok and rf then
        Rayfield = rf
        return true
    end
    return false
end

-- Detect piano by name keyword + color matching
local function detectPiano()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") then
            local name = tostring(v.Name):lower()
            if name:find(PIANO_NAME_KEYWORD:lower()) then
                -- try to find a PrimaryPart or a color-bearing descendant
                local primary = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                if primary then
                    -- check color on a few likely properties
                    local foundColor = false
                    local function checkColor(part)
                        if part and part:IsA("BasePart") and part.Color then
                            if (part.Color - TARGET_COLOR).magnitude < 0.1 then
                                return true
                            end
                        end
                        return false
                    end
                    if checkColor(primary) then
                        PianoModel = v
                        return true
                    end
                    -- scan children for matching color
                    for _, c in ipairs(v:GetDescendants()) do
                        if c:IsA("BasePart") and checkColor(c) then
                            PianoModel = v
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Find key parts (by name) inside piano; returns table mapping note->part
local function buildKeyMap(piano)
    local map = {}
    if not piano then return map end
    for _, desc in ipairs(piano:GetDescendants()) do
        if desc:IsA("BasePart") then
            local keyName = tostring(desc.Name)
            map[keyName] = desc
        end
    end
    return map
end

-- Press function: supports ClickDetector and ProximityPrompt
local function pressPart(part)
    if not part then return false end
    -- find ClickDetector children
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("ClickDetector") then
            -- Use legacy fireclickdetector if available on executor env
            local ok, _ = pcall(function() fireclickdetector(child) end)
            if not ok then
                -- try to simulate mouseclick via :MouseClick? Not possible, fallback to touch proximity
                pcall(function() child:Destroy() end)
            end
            return true
        elseif child:IsA("ProximityPrompt") then
            -- fire proximity prompt
            pcall(function() child:InputHoldBegin() end)
            task.wait(0.05)
            pcall(function() child:InputHoldEnd() end)
            return true
        end
    end

    -- If no detectors, attempt to touch the part (may or may not trigger)
    if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local orig = hrp.CFrame
        -- teleport briefly to part, then back
        local success, err = pcall(function()
            hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 2, 0))
        end)
        safeWait(0.06)
        pcall(function() hrp.CFrame = orig end)
        return success
    end
    return false
end

-- Press by note name using keyMap
local function pressNoteByName(keyMap, noteName)
    if not keyMap or not noteName then return false end
    -- try direct lookup
    local part = keyMap[noteName] or keyMap[noteName:lower()] or keyMap[noteName:upper()]
    if part then
        return pressPart(part)
    end
    -- fallback: try to find a part whose name contains the noteName
    for k, p in pairs(keyMap) do
        if tostring(k):lower():find(tostring(noteName):lower()) then
            return pressPart(p)
        end
    end
    return false
end

-- Move player behind piano and face it
local function positionPlayerAtPiano(piano)
    if not piano then return false end
    local primary = piano.PrimaryPart or piano:FindFirstChildWhichIsA("BasePart")
    if not primary then return false end
    if not LocalPlayer or not LocalPlayer.Character then return false end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local targetPos = primary.Position - primary.CFrame.LookVector * DISTANCE_BEHIND
    local lookAt = primary.Position

    if MOVE_TELEPORT then
        hrp.CFrame = CFrame.new(targetPos, lookAt)
    else
        local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        local goal = {CFrame = CFrame.new(targetPos, lookAt)}
        local tw = TweenService:Create(hrp, tweenInfo, goal)
        tw:Play()
        tw.Completed:Wait()
    end

    -- set camera
    if workspace.CurrentCamera then
        workspace.CurrentCamera.CFrame = CFrame.new(hrp.Position + CAMERA_HEIGHT_OFFSET, lookAt)
    end
    return true
end

-- Play routine
local function playRoutine()
    if not PianoModel then
        if Rayfield then Rayfield:Notify({Title = "ピアノ未検出", Content = "ピアノが見つかりません。", Duration = 3}) end
        return
    end

    local keyMap = buildKeyMap(PianoModel)
    if Rayfield then Rayfield:Notify({Title = "検出完了", Content = "ピアノを検出しました。演奏を開始します。", Duration = 3}) end

    Playing = true
    repeat
        for _, note in ipairs(song) do
            if not Playing then break end
            local pressed = pressNoteByName(keyMap, note.part)
            -- optional: notify failures for debugging
            -- if not pressed and Rayfield then Rayfield:Notify({Title = "Key not found", Content = note.part, Duration = 2}) end
            safeWait((note.wait or 0.4) / math.max(Speed, 0.01))
        end
    until not Looping or not Playing
    Playing = false
    if Rayfield then Rayfield:Notify({Title = "演奏終了", Content = "Stopped playing.", Duration = 2}) end
end

-- Set up UI
local function setupUI()
    local ok = loadRayfield()
    if not ok then
        warn("Rayfield could not be loaded. UI will not be available.")
        return
    end

    local Window = Rayfield:CreateWindow({
        Name = "Libra Heart Auto Piano",
        LoadingTitle = "Libra Heart Player",
        LoadingSubtitle = "Fling Things and People",
        ConfigurationSaving = {Enabled = true, FolderName = nil, FileName = "LibraHeartConfig"}
    })

    local Tab = Window:CreateTab("Main")
    local Section = Tab:CreateSection("Player Controls")

    Section:CreateToggle({
        Name = "🎶 自動演奏",
        CurrentValue = false,
        Flag = "AutoPlay",
        Callback = function(val)
            if val then
                -- Ensure piano present and position player
                if not PianoModel then
                    local found = detectPiano()
                    if not found then
                        Rayfield:Notify({Title = "ピアノが見つかりません", Content = "ワークスペースを確認してください。", Duration = 4})
                        return
                    end
                end
                positionPlayerAtPiano(PianoModel)
                Rayfield:Notify({Title = "演奏開始", Content = "Libra Heart を再生します。", Duration = 2})
                task.spawn(playRoutine)
            else
                Playing = false
                Rayfield:Notify({Title = "停止", Content = "演奏を停止しました。", Duration = 2})
            end
        end
    })

    Section:CreateSlider({
        Name = "⏱ 再生速度",
        Range = {0.5, 2},
        Increment = 0.1,
        Suffix = "x",
        CurrentValue = 1,
        Flag = "Speed",
        Callback = function(val)
            Speed = val
        end
    })

    Section:CreateToggle({
        Name = "🔁 ループ",
        CurrentValue = false,
        Flag = "Loop",
        Callback = function(val)
            Looping = val
        end
    })

    Section:CreateButton({
        Name = "🔍 再検出: ピアノを検索",
        Callback = function()
            local ok = detectPiano()
            if ok then
                Rayfield:Notify({Title = "ピアノ検出", Content = "ピアノを見つけました。", Duration = 3})
            else
                Rayfield:Notify({Title = "未検出", Content = "ピアノが見つかりません。名前や色の条件を確認してください。", Duration = 4})
            end
        end
    })

    Section:CreateParagraph({Name = "使い方",\Content = "ピアノを検出 -> 自動演奏トグルをオン -> 必要であれば速度/ループを調整してください。"})
end

-- Auto-detect piano on load
local function init()
    -- attempt detect several times (for loading games)
    local attempts = 0
    while attempts < 6 and not PianoModel do
        if detectPiano() then
            break
        end
        attempts = attempts + 1
        task.wait(1)
    end

    if PianoModel then
        warn("Piano detected: " .. tostring(PianoModel.Name))
    else
        warn("Piano not detected automatically. Use the UI to re-scan.")
    end

    setupUI()
end

-- Run
init()

-- Exports for console tweaking
_G.LibraHeart = {
    SetSpeed = function(s) Speed = s end,
    Start = function() if not Playing then task.spawn(playRoutine) end end,
    Stop = function() Playing = false end,
    SetLoop = function(b) Looping = b end,
    Detect = detectPiano,
    Piano = function() return PianoModel end,
}

print("Libra Heart Auto Piano (script loaded)")
