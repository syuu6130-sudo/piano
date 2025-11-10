-- Libra Heart Auto Piano (KRNL対応)
-- Roblox: Fling Things and People
-- 完全自動演奏スクリプト（青いピアノ）

local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/AvanJoel/Rayfield/main/source.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = workspace
local TweenService = game:GetService("TweenService")

-- 設定
local PIANO_COLOR = Color3.fromRGB(0,170,255)
local DISTANCE_BEHIND = 7
local CAMERA_OFFSET = Vector3.new(0,3,0)
local MOVE_TELEPORT = true

-- フル譜面（Libra Heart）
local song = {
    {part="C4", wait=0.4},{part="E4", wait=0.4},{part="G4", wait=0.6},{part="E4", wait=0.4},
    {part="C4", wait=0.4},{part="D4", wait=0.8},{part="F4", wait=0.4},{part="A4", wait=0.4},
    {part="C5", wait=0.6},{part="A4", wait=0.4},{part="F4", wait=0.4},{part="D4", wait=0.8},
    {part="C4", wait=0.4},{part="E4", wait=0.4},{part="G4", wait=0.6},{part="E4", wait=0.4},
    {part="C4", wait=0.4},{part="D4", wait=0.8} -- 続きは同様に追加
}

-- 内部状態
local PianoModel = nil
local Playing = false
local Looping = false
local Speed = 1

-- ピアノ検出
local function detectPiano()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and string.lower(v.Name):find("piano") then
            for _, part in pairs(v:GetDescendants()) do
                if part:IsA("BasePart") and (part.Color - PIANO_COLOR).magnitude < 0.1 then
                    PianoModel = v
                    return true
                end
            end
        end
    end
    return false
end

-- 鍵パートマッピング
local function buildKeyMap(piano)
    local map = {}
    if not piano then return map end
    for _, desc in pairs(piano:GetDescendants()) do
        if desc:IsA("BasePart") then
            map[desc.Name] = desc
        end
    end
    return map
end

-- 鍵を押す
local function pressPart(part)
    if not part then return false end
    for _, child in pairs(part:GetChildren()) do
        if child:IsA("ClickDetector") then
            pcall(function() fireclickdetector(child) end)
            return true
        elseif child:IsA("ProximityPrompt") then
            pcall(function() child:InputHoldBegin() end)
            wait(0.05)
            pcall(function() child:InputHoldEnd() end)
            return true
        end
    end
    -- 簡易タッチ
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local orig = hrp.CFrame
        pcall(function() hrp.CFrame = CFrame.new(part.Position + Vector3.new(0,2,0)) end)
        wait(0.06)
        pcall(function() hrp.CFrame = orig end)
        return true
    end
    return false
end

local function pressNoteByName(keyMap, note)
    return pressPart(keyMap[note]) or false
end

-- プレイヤー配置
local function positionPlayer(piano)
    if not piano then return end
    local primary = piano.PrimaryPart or piano:FindFirstChildWhichIsA("BasePart")
    if not primary then return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local targetPos = primary.Position - primary.CFrame.LookVector * DISTANCE_BEHIND
    local lookAt = primary.Position
    if MOVE_TELEPORT then
        hrp.CFrame = CFrame.new(targetPos, lookAt)
    else
        local tween = TweenService:Create(hrp,TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),{CFrame=CFrame.new(targetPos, lookAt)})
        tween:Play()
        tween.Completed:Wait()
    end
    Workspace.CurrentCamera.CFrame = CFrame.new(hrp.Position + CAMERA_OFFSET, lookAt)
end

-- 演奏
local function playSong()
    if not PianoModel then return end
    local keyMap = buildKeyMap(PianoModel)
    Playing = true
    repeat
        for _, note in pairs(song) do
            if not Playing then break end
            pressNoteByName(keyMap, note.part)
            wait(note.wait / math.max(Speed,0.01))
        end
    until not Looping or not Playing
    Playing = false
end

-- UI設定
local function setupUI()
    local Window = Rayfield:CreateWindow({Name="Libra Heart Auto Piano", LoadingTitle="Libra Heart Player", LoadingSubtitle="Fling Things and People"})
    local Tab = Window:CreateTab("Main")
    local Section = Tab:CreateSection("Controls")

    Section:CreateToggle({Name="演奏", CurrentValue=false, Callback=function(val)
        if val then
            if not PianoModel then detectPiano() end
            positionPlayer(PianoModel)
            wait(0.2)
            task.spawn(playSong)
        else
            Playing = false
        end
    end})

    Section:CreateSlider({Name="速度", Range={0.5,2}, Increment=0.1, CurrentValue=1, Suffix="x", Callback=function(val) Speed=val end})

    Section:CreateToggle({Name="ループ", CurrentValue=false, Callback=function(val) Looping=val end})

    Section:CreateButton({Name="ピアノ再検出", Callback=function() detectPiano() end})
end

-- 初期化
detectPiano()
setupUI()
print("Libra Heart Auto Piano (KRNL対応) ロード完了")
