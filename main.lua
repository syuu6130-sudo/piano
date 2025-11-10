-- Rayfield UIライブラリをロード
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Helper: YamaRolanSioピアノをスポーン
local function spawnYamaRolanSioPiano()
    local success = false
    
    -- プレイヤーのバックパックとキャラクターを検索
    local backpack = LocalPlayer.Backpack
    local character = LocalPlayer.Character
    
    -- "Blue Piano"ツールを探す
    local bluePianoTool = nil
    
    if backpack then
        bluePianoTool = backpack:FindFirstChild("Blue Piano")
    end
    
    if not bluePianoTool and character then
        bluePianoTool = character:FindFirstChild("Blue Piano")
    end
    
    if bluePianoTool and bluePianoTool:IsA("Tool") then
        -- ツールを装備
        if bluePianoTool.Parent == backpack then
            character.Humanoid:EquipTool(bluePianoTool)
            task.wait(0.3)
        end
        
        -- ツールをアクティベート（使用）
        bluePianoTool:Activate()
        task.wait(0.5)
        
        -- ツールを外す
        if character.Humanoid then
            character.Humanoid:UnequipTools()
        end
        
        success = true
    end
    
    return success
end

-- Helper: 全てのピアノを検索（改良版）
local function findAllPianos()
    local pianos = {}
    
    print("[Libra Heart] Searching for YamaRolanSio pianos...")
    
    -- Workspace全体を検索
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            
            -- YamaRolanSioピアノの特定
            if name:find("yamarolansi") or name:find("blue") and name:find("piano") or
               name:find("piano") and obj:FindFirstChild("Piano") then
                
                -- 青い色のパーツがあるか確認
                local hasBlueColor = false
                local hasKeys = false
                local keyCount = 0
                
                for _, part in ipairs(obj:GetDescendants()) do
                    if part:IsA("BasePart") then
                        -- 青色チェック (BrickColorまたはColor)
                        if part.BrickColor == BrickColor.new("Bright blue") or 
                           part.BrickColor == BrickColor.new("Really blue") or
                           (part.Color.B > 0.5 and part.Color.R < 0.5 and part.Color.G < 0.5) then
                            hasBlueColor = true
                        end
                        
                        -- 音符名チェック（柔軟な検索）
                        local partName = part.Name:upper()
                        if partName:match("^[CDEFGAB]#?$") or -- C, D, E, F, G, A, B, C#等
                           partName:find("KEY") or 
                           partName:find("NOTE") then
                            hasKeys = true
                            keyCount = keyCount + 1
                        end
                    end
                end
                
                -- 青色かつキーがある、またはキーが多数ある
                if (hasBlueColor and hasKeys) or keyCount >= 5 then
                    print("[Libra Heart] Found YamaRolanSio piano:", obj.Name, "with", keyCount, "keys")
                    table.insert(pianos, obj)
                end
            end
        end
    end
    
    -- 鍵盤パーツから親ピアノを探す
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:upper()
            -- 音符パターンマッチング
            if name:match("^[CDEFGAB]#?$") then
                local parent = obj.Parent
                
                -- 親がモデルで、まだリストにない
                if parent and parent:IsA("Model") and not table.find(pianos, parent) then
                    -- 青色チェック
                    local isBlue = obj.BrickColor == BrickColor.new("Bright blue") or
                                   obj.BrickColor == BrickColor.new("Really blue") or
                                   (obj.Color.B > 0.5 and obj.Color.R < 0.5)
                    
                    if isBlue then
                        print("[Libra Heart] Found piano via blue key:", parent.Name)
                        table.insert(pianos, parent)
                    end
                end
            end
        end
    end
    
    print("[Libra Heart] Total pianos found:", #pianos)
    return pianos
end

-- Rayfield UIウィンドウを作成
local Window = Rayfield:CreateWindow({
    Name = "🎹 Libra Heart Piano Controller",
    LoadingTitle = "Libra Heart",
    LoadingSubtitle = "by YamaRolanSio",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "LibraHeart"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

-- タブを作成
local MainTab = Window:CreateTab("🎹 メイン", nil)
local SettingsTab = Window:CreateTab("⚙️ 設定", nil)

-- セクションを作成
local PianoSection = MainTab:CreateSection("ピアノ操作")

-- ピアノスポーンボタン
local SpawnButton = MainTab:CreateButton({
    Name = "🎹 ピアノをスポーン",
    Callback = function()
        local success = spawnYamaRolanSioPiano()
        if success then
            Rayfield:Notify({
                Title = "成功",
                Content = "ピアノをスポーンしました！",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "エラー",
                Content = "Blue Pianoツールが見つかりません",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- ピアノ検索ボタン
local FindButton = MainTab:CreateButton({
    Name = "🔍 ピアノを検索",
    Callback = function()
        local pianos = findAllPianos()
        Rayfield:Notify({
            Title = "検索完了",
            Content = #pianos .. "個のピアノが見つかりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- 情報セクション
local InfoSection = SettingsTab:CreateSection("情報")

local InfoLabel = SettingsTab:CreateParagraph({
    Title = "Libra Heart",
    Content = "YamaRolanSioピアノコントローラー\nバージョン: 1.0\n製作者: YamaRolanSio"
})

-- UIを破棄するボタン
local DestroyButton = SettingsTab:CreateButton({
    Name = "❌ UIを閉じる",
    Callback = function()
        Rayfield:Destroy()
    end
})

print("[Libra Heart] Rayfield UI loaded successfully!")
