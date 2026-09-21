-- ============================================================
-- Auto-Interact: Public + HWID + Auto-Conquer + Adaptive Conquer Best
-- ============================================================

-- ===== GAME ID LOCK =====
local ALLOWED_PLACE_ID = 113987393426315
if game.PlaceId ~= ALLOWED_PLACE_ID then
    warn("[AutoInteract] ❌ Wrong game! PlaceId " .. ALLOWED_PLACE_ID .. " required.")
    return
end

-- ===== SERVICES =====
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== KEY SERVER =====
local KEY_SERVER = "https://key-server-za8g.onrender.com"
local DISCORD_LINK = "https://discord.gg/Ayvc4wbUp"
local VERIFIED_KEY = nil

-- ===== HWID GRABBER =====
local function getHWID()
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and id and id ~= "" then return id end

    if type(gethwid) == "function" then
        local ok2, hwid = pcall(gethwid)
        if ok2 and hwid then return hwid end
    end
    if type(get_hwid) == "function" then
        local ok3, hwid = pcall(get_hwid)
        if ok3 and hwid then return hwid end
    end

    return "user_" .. player.UserId
end

local MY_HWID = getHWID()
print("[HWID] " .. MY_HWID:sub(1, 16) .. "...")

-- ===== CONFIG =====
local CONFIG = {
    COLLECT_OPCODE = "P",
    SELL_OPCODE = "X",
    BUY_OPCODE = ")",
    CONQUER_OPCODE = "R",
    LOOP_DELAY = 0.15,
    CYCLE_DELAY = 0.4,
    SELL_INTERVAL = 5,
    BUY_INTERVAL = 1,
    BUY_ITEM_GAP = 0.1,
    CONQUER_TIMEOUT = 600,
    CONQUER_POLL = 2,
    AUTO_START_COLLECT = false,
    AUTO_START_SELL = false,
    AUTO_START_BUY = false,
    AUTO_START_ANTIAFK = true,
    STRICT_MONEY_CHECK = true,
    ANTIAFK_INTERVAL = 1140,
    MY_PLOT = "1",
    SHOW_DEBUG = false,
    MIN_ACCEPTABLE_TIER = 3,
}

local COLLECT_TYPES = { Farm = true, Military = false, House = false }

-- ===== PRIORITY =====
local PRIORITY = {
    City = 1,
    Lab = 2,
    Garnison = 3,
    MilitaryBase = 4,
    Camp = 5,
}

local BASE_TYPE_DISPLAY = {
    Camp = "Island Outpost",
    Lab = "Oil Rig",
    MilitaryBase = "Lighthouse Island",
    Garnison = "Military Island",
    City = "Headquarters",
}

-- ===== PRICE TABLE =====
local PRICES = {
    FishFarm=500, OilRig=1250, CopperMine=3500, PetrolFactory=10000,
    BrickFactory=15000, SatelliteFactory=75000, QuantumGenerator=125000000000,
    Monolith=250000000000, GunpowderFactory=125000, CommandersHeadquarters=175000,
    ContainerYard=1500000, MineFactory=3500000, GoldMine=50000,
    AntigravityFacility=250000000, Bank=750000, AmmoFactory=12500000,
    Hospital=500000, RubyMine=300000, NuclearFacility=50000000,
    DiamondMine=5000000, Hyprnova=18500000000, RocketFactory=25000000,
    SolarFarm=250000, Prison=7500000,
    FishermansHut=250, Motel=5000, LuxuryResidence=250000,
    OceanicHeightsTower=1000000, ApartmentComplex=75000,
    HotelParabola=5000000, SailorsCottage=500, ThePalace=250000000,
    TwistedTowers=250000000, FishermansLodge=2500, HarborViewBlock=2500000,
    JetHangar=1500000, NukeSilo=2500000, MonstrousBase=1000000000,
    RocketBay=10000000, MissileYard=4000000, HeliPad=15000,
    PatrolBay=500000, NavalYard=5000, RocketStation=125000,
    SubmarineDock=50000, BattleshipDock=25000000, BomberBase=5000000000,
    SkyFort=250000, CarrierPort=1000000000, GuardPost=1500,
    NuclearSubmarineYard=500000, ShadowPort=250000000, EliteAirbase=75000000,
    Lighthouse=250000, Workshop=15000, Road1Yellow=900, StrongWall=9000,
    Road3Yellow=1200, Lamp2=10000, Bench=1300, Water=500, Fountain=25000,
    BuilderStatue=12000, Tree2=4500, FlagPole=50000, Tree=4500,
    Roundabout=40000, Car1=8000, GoldenShark=16000, Lamp1=10000,
    Road3=1200, Boat=5000, CarParking2=1200, CarParking1=1200,
    Car2=8000, Road2=1200, GeneralResidence=250000, Road2Yellow=600,
    CommandCenter=5000000, Reflector=7500, Road1=1200, WorkerStatue=150000,
    Intersection=20000, Dirt=350, StorageCenter=75000, PlayerStatue=10000,
}

-- ===== SHOP CATALOG =====
local SHOP_TABS = { "Farm", "House", "Military", "Decor" }
local SHOP_CATALOG = {
    Farm = {
        {folder="Hospital",display="Hospital"},{folder="RubyMine",display="Ruby Mine"},
        {folder="PetrolFactory",display="Petrol Factory"},{folder="CopperMine",display="Copper Mine"},
        {folder="FishFarm",display="Fish Farm"},{folder="NuclearFacility",display="Nuclear Facility"},
        {folder="DiamondMine",display="Diamond Mine"},{folder="BrickFactory",display="Brick Factory"},
        {folder="SatelliteFactory",display="Satellite Factory"},{folder="QuantumGenerator",display="Quantum Generator"},
        {folder="OilRig",display="Oil Rig"},{folder="Monolith",display="Monolith"},
        {folder="GunpowderFactory",display="Gunpowder Factory"},{folder="CommandersHeadquarters",display="Commander's HQ"},
        {folder="ContainerYard",display="Container Yard"},{folder="MineFactory",display="Mine Factory"},
        {folder="GoldMine",display="Gold Mine"},{folder="AntigravityFacility",display="Antigravity Facility"},
        {folder="Bank",display="Bank"},{folder="AmmoFactory",display="Ammo Factory"},
        {folder="Hyprnova",display="Hypernova Facility"},{folder="RocketFactory",display="Rocket Factory"},
        {folder="SolarFarm",display="Solar Farm"},{folder="Prison",display="Prison"},
    },
    House = {
        {folder="FishermansHut",display="Fisherman's Hut"},{folder="Motel",display="Motel"},
        {folder="LuxuryResidence",display="Luxury Residence"},{folder="OceanicHeightsTower",display="Oceanic Heights Tower"},
        {folder="ApartmentComplex",display="Apartment Complex"},{folder="HotelParabola",display="Hotel Parabola"},
        {folder="SailorsCottage",display="Sailor's Cottage"},{folder="ThePalace",display="The Palace"},
        {folder="TwistedTowers",display="Twisted Towers"},{folder="FishermansLodge",display="Ocean Cabin"},
        {folder="HarborViewBlock",display="Sea Apartment"},
    },
    Military = {
        {folder="JetHangar",display="Jet Hangar"},{folder="NukeSilo",display="Nuke Silo"},
        {folder="MonstrousBase",display="Monstrous Base"},{folder="RocketBay",display="Rocket Bay"},
        {folder="MissileYard",display="Missile Yard"},{folder="HeliPad",display="Heli Pad"},
        {folder="PatrolBay",display="Patrol Bay"},{folder="NavalYard",display="Naval Yard"},
        {folder="RocketStation",display="Rocket Station"},{folder="SubmarineDock",display="Submarine Dock"},
        {folder="BattleshipDock",display="Battleship Dock"},{folder="BomberBase",display="Nuclear Hangar"},
        {folder="SkyFort",display="Sky Fort"},{folder="CarrierPort",display="Carrier Port"},
        {folder="GuardPost",display="Guard Post"},{folder="NuclearSubmarineYard",display="Nuclear Submarine Yard"},
        {folder="ShadowPort",display="Shadow Port"},{folder="EliteAirbase",display="Elite Airbase"},
    },
    Decor = {
        {folder="Lighthouse",display="Lighthouse"},{folder="Workshop",display="Workshop"},
        {folder="Road1Yellow",display="Road 1 (Yellow)"},{folder="StrongWall",display="Strong Wall"},
        {folder="Road3Yellow",display="Road 3 (Yellow)"},{folder="Lamp2",display="Lamp 2"},
        {folder="Bench",display="Bench"},{folder="Water",display="Water"},
        {folder="Fountain",display="Fountain"},{folder="BuilderStatue",display="Builder Statue"},
        {folder="Tree2",display="Tree 2"},{folder="FlagPole",display="Flag Pole"},
        {folder="Tree",display="Tree"},{folder="Roundabout",display="Roundabout"},
        {folder="Car1",display="Car 1"},{folder="GoldenShark",display="Golden Shark"},
        {folder="Lamp1",display="Lamp 1"},{folder="Road3",display="Road 3"},
        {folder="Boat",display="Boat"},{folder="CarParking2",display="Car Parking 2"},
        {folder="CarParking1",display="Car Parking 1"},{folder="Car2",display="Car 2"},
        {folder="Road2",display="Road 2"},{folder="GeneralResidence",display="General Residence"},
        {folder="Road2Yellow",display="Road 2 (Yellow)"},{folder="CommandCenter",display="Command Center"},
        {folder="Reflector",display="Reflector"},{folder="Road1",display="Road 1"},
        {folder="WorkerStatue",display="Worker Statue"},{folder="Intersection",display="Intersection"},
        {folder="Dirt",display="Dirt"},{folder="StorageCenter",display="Storage Center"},
        {folder="PlayerStatue",display="Player Statue"},
    },
}

local SHOP_BY_ITEM = {}
for shopName, items in pairs(SHOP_CATALOG) do
    for _, item in ipairs(items) do
        SHOP_BY_ITEM[item.folder] = shopName
    end
end

-- ============================================================
-- KEY VALIDATION
-- ============================================================
local function httpRequest(url, body)
    local ok, response = pcall(function()
        return request({
            Url = url, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(body),
            Timeout = 60,
        })
    end)
    if not ok or not response then return nil, "Network error" end
    local decodeOk, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
    if not decodeOk then return nil, "Invalid response" end
    return data
end

local function validateKey(key)
    local data, err = httpRequest(KEY_SERVER .. "/validate", {
        key = key,
        hwid = MY_HWID
    })
    if not data then return nil, err end
    if data.valid then return true, data.message end
    return false, data.error or "Invalid key"
end

-- ============================================================
-- FILE API
-- ============================================================
local HAS_FILE_API = (type(writefile) == "function")
    and (type(readfile) == "function")
    and (type(isfile) == "function")

local KEY_FILE = "autointeract_key.txt"
local memoryKey = nil

local function saveVerifiedKey(key)
    if HAS_FILE_API then pcall(function() writefile(KEY_FILE, key) end)
    else memoryKey = key end
end

local function loadVerifiedKey()
    if HAS_FILE_API then
        local ok, content = pcall(function()
            if isfile(KEY_FILE) then return readfile(KEY_FILE) end
        end)
        if ok and content then return content:gsub("%s+", "") end
    end
    return memoryKey
end

-- ============================================================
-- KEY PANEL UI
-- ============================================================
local keyGui = Instance.new("ScreenGui")
keyGui.Name = "AutoInteractKeyGate"
keyGui.ResetOnSpawn = false
keyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
keyGui.Parent = playerGui

local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 340, 0, 320)
keyFrame.Position = UDim2.new(0.5, -170, 0.5, -160)
keyFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
keyFrame.BorderSizePixel = 0
keyFrame.Active = true
keyFrame.Draggable = true
keyFrame.Parent = keyGui

local kCorner = Instance.new("UICorner")
kCorner.CornerRadius = UDim.new(0, 10)
kCorner.Parent = keyFrame

local kStroke = Instance.new("UIStroke")
kStroke.Color = Color3.fromRGB(80, 200, 120)
kStroke.Thickness = 2
kStroke.Parent = keyFrame

local kTitle = Instance.new("TextLabel")
kTitle.Size = UDim2.new(1, 0, 0, 40)
kTitle.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
kTitle.BorderSizePixel = 0
kTitle.Text = "🔑 Auto-Interact — Key Required"
kTitle.TextColor3 = Color3.fromRGB(230, 230, 240)
kTitle.TextSize = 15
kTitle.Font = Enum.Font.GothamBold
kTitle.Parent = keyFrame

local kTitleCorner = Instance.new("UICorner")
kTitleCorner.CornerRadius = UDim.new(0, 10)
kTitleCorner.Parent = kTitle

local kTitleMask = Instance.new("Frame")
kTitleMask.Size = UDim2.new(1, 0, 0, 8)
kTitleMask.Position = UDim2.new(0, 0, 1, -8)
kTitleMask.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
kTitleMask.BorderSizePixel = 0
kTitleMask.Parent = kTitle

local warnLabel = Instance.new("TextLabel")
warnLabel.Size = UDim2.new(1, -20, 0, 32)
warnLabel.Position = UDim2.new(0, 10, 0, 46)
warnLabel.BackgroundColor3 = Color3.fromRGB(80, 40, 20)
warnLabel.BorderSizePixel = 0
warnLabel.Text = "⚠ STAND ON YOUR PLOT WHEN YOU VALIDATE KEY"
warnLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
warnLabel.TextSize = 12
warnLabel.Font = Enum.Font.GothamBold
warnLabel.TextWrapped = true
warnLabel.Parent = keyFrame

local warnCorner = Instance.new("UICorner")
warnCorner.CornerRadius = UDim.new(0, 6)
warnCorner.Parent = warnLabel

local hwidLabel = Instance.new("TextLabel")
hwidLabel.Size = UDim2.new(1, -20, 0, 14)
hwidLabel.Position = UDim2.new(0, 10, 0, 82)
hwidLabel.BackgroundTransparency = 1
hwidLabel.Text = "HWID: " .. MY_HWID:sub(1, 20) .. "..."
hwidLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
hwidLabel.TextSize = 10
hwidLabel.Font = Enum.Font.Code
hwidLabel.TextXAlignment = Enum.TextXAlignment.Left
hwidLabel.Parent = keyFrame

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, -40, 0, 40)
keyInput.Position = UDim2.new(0, 20, 0, 102)
keyInput.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
keyInput.BorderSizePixel = 0
keyInput.Text = ""
keyInput.PlaceholderText = "Enter your key..."
keyInput.TextColor3 = Color3.fromRGB(230, 230, 240)
keyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
keyInput.TextSize = 13
keyInput.Font = Enum.Font.Code
keyInput.ClearTextOnFocus = false
keyInput.Parent = keyFrame

local kiCorner = Instance.new("UICorner")
kiCorner.CornerRadius = UDim.new(0, 6)
kiCorner.Parent = keyInput

local verifyBtn = Instance.new("TextButton")
verifyBtn.Size = UDim2.new(1, -40, 0, 40)
verifyBtn.Position = UDim2.new(0, 20, 0, 154)
verifyBtn.BackgroundColor3 = Color3.fromRGB(40, 130, 70)
verifyBtn.BorderSizePixel = 0
verifyBtn.Text = "Verify Key"
verifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
verifyBtn.TextSize = 14
verifyBtn.Font = Enum.Font.GothamBold
verifyBtn.Parent = keyFrame

local vbCorner = Instance.new("UICorner")
vbCorner.CornerRadius = UDim.new(0, 6)
vbCorner.Parent = verifyBtn

local keyStatus = Instance.new("TextLabel")
keyStatus.Size = UDim2.new(1, -40, 0, 44)
keyStatus.Position = UDim2.new(0, 20, 0, 202)
keyStatus.BackgroundTransparency = 1
keyStatus.Text = ""
keyStatus.TextColor3 = Color3.fromRGB(180, 180, 190)
keyStatus.TextSize = 12
keyStatus.Font = Enum.Font.Gotham
keyStatus.TextWrapped = true
keyStatus.Parent = keyFrame

local discordBtn = Instance.new("TextButton")
discordBtn.Size = UDim2.new(1, -40, 0, 32)
discordBtn.Position = UDim2.new(0, 20, 0, 252)
discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
discordBtn.BorderSizePixel = 0
discordBtn.Text = "Get a Key → " .. DISCORD_LINK:gsub("https://", "")
discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
discordBtn.TextSize = 11
discordBtn.Font = Enum.Font.GothamBold
discordBtn.Parent = keyFrame

local dbCorner = Instance.new("UICorner")
dbCorner.CornerRadius = UDim.new(0, 6)
dbCorner.Parent = discordBtn

local function setKeyStatus(text, color)
    keyStatus.Text = text
    keyStatus.TextColor3 = color or Color3.fromRGB(180, 180, 190)
end

discordBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        pcall(function() setclipboard(DISCORD_LINK) end)
        setKeyStatus("Discord link copied!", Color3.fromRGB(120, 200, 240))
    else
        setKeyStatus("Join: " .. DISCORD_LINK, Color3.fromRGB(120, 200, 240))
    end
end)

-- ============================================================
-- PLOT DETECTOR
-- ============================================================
local function detectPlot()
    local slot = player:GetAttribute("CurrentBaseSlot")
    if slot ~= nil then
        local s = tostring(slot)
        if s ~= "0" and s ~= "" then
            print("[PlotDetect] CurrentBaseSlot = " .. s)
            return s
        end
    end

    local plots = workspace:FindFirstChild("MilitaryMap")
        and workspace.MilitaryMap:FindFirstChild("PlayerPlots")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

    if plots and root then
        local closest, dist = nil, math.huge
        for _, plot in ipairs(plots:GetChildren()) do
            local spawn = plot:FindFirstChild("SpawnPart")
            local part = spawn and spawn:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local d = (part.Position - root.Position).Magnitude
                if d < dist then dist = d; closest = plot.Name end
            end
        end
        if closest then return tostring(closest) end
    end

    return CONFIG.MY_PLOT
end

-- ============================================================
-- MAIN SCRIPT
-- ============================================================
local function startMainScript()
    keyGui:Destroy()

    CONFIG.MY_PLOT = detectPlot()
    print("[AutoInteract] Plot set to: " .. CONFIG.MY_PLOT)

    local function parseMoneyValue(v)
        if type(v) == "number" then return v end
        if type(v) ~= "string" then return 0 end
        v = v:gsub("[%$,%s]", "")
        local num, suffix = v:match("^([%d%.]+)([KkMmBb]?)$")
        if not num then return 0 end
        num = tonumber(num)
        if not num then return 0 end
        if suffix == "K" or suffix == "k" then return num * 1e3 end
        if suffix == "M" or suffix == "m" then return num * 1e6 end
        if suffix == "B" or suffix == "b" then return num * 1e9 end
        return num
    end

    local function getMyMoney()
        local ls = player:FindFirstChild("leaderstats")
        local m = ls and ls:FindFirstChild("Money")
        if not m then return 0 end
        return parseMoneyValue(m.Value)
    end

    local bridgenet = ReplicatedStorage:WaitForChild("ncxyzero_bridgenet2-fork@1.1.5")
    local dataRemoteEvent = bridgenet:WaitForChild("dataRemoteEvent")

    local CONFIG_FILE = "autointeract_config.json"
    local memoryConfig = nil

    local state = {
        collecting = CONFIG.AUTO_START_COLLECT,
        selling = CONFIG.AUTO_START_SELL,
        buying = CONFIG.AUTO_START_BUY,
        antiAfkEnabled = CONFIG.AUTO_START_ANTIAFK,
        strictMoney = CONFIG.STRICT_MONEY_CHECK,
        collectFires = 0, sellFires = 0, buyFires = 0, buySkips = 0, antiAfkSaves = 0,
        startTime = tick(),
        myBuildingsFolder = nil,
        selectedItems = {},
        currentShop = "Farm",
        activeTab = "Collect",
        connections = {}, threads = {},
        unloaded = false, screenGui = nil, panel = nil, reopenBtn = nil,
    }

    local KNOWN_TYPES = { Farm = true, Military = true, House = true }
    local CLASS_COLORS = {
        Farm = Color3.fromRGB(80, 200, 120),
        Military = Color3.fromRGB(200, 80, 80),
        House = Color3.fromRGB(90, 150, 220),
        Other = Color3.fromRGB(120, 120, 130),
    }

    local function classifyBuilding(building)
        local t = building:GetAttribute("type")
        if t == nil then return "Other" end
        t = tostring(t)
        if KNOWN_TYPES[t] then return t end
        return "Other"
    end

    local function findMyBuildings()
        local mm = workspace:FindFirstChild("MilitaryMap")
        if not mm then return nil end
        local plots = mm:FindFirstChild("PlayerPlots")
        if not plots then return nil end
        local plot = plots:FindFirstChild(CONFIG.MY_PLOT)
            or plots[tostring(CONFIG.MY_PLOT)]
            or plots[tonumber(CONFIG.MY_PLOT) or -1]
        if not plot then return nil end
        local inner = plot:FindFirstChild("Plot")
        local b = inner and inner:FindFirstChild("Buildings")
        if b then return b end
        b = plot:FindFirstChild("Buildings")
        if b then return b end
        for _, d in ipairs(plot:GetDescendants()) do
            if d.Name == "Buildings" then return d end
        end
        return nil
    end

    state.myBuildingsFolder = findMyBuildings()

    table.insert(state.threads, task.spawn(function()
        while not state.unloaded do
            task.wait(CONFIG.ANTIAFK_INTERVAL)
            if state.unloaded then break end
            if state.antiAfkEnabled then
                pcall(function()
                    local char = player.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.Jump = true
                        state.antiAfkSaves = state.antiAfkSaves + 1
                    end
                end)
            end
        end
    end))

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoInteractGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    state.screenGui = screenGui

    local function trackConnection(c)
        table.insert(state.connections, c)
        return c
    end

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 340, 0, 400)
    panel.Position = UDim2.new(0, 20, 0.5, -200)
    panel.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Draggable = true
    panel.Parent = screenGui
    state.panel = panel

    local pc = Instance.new("UICorner")
    pc.CornerRadius = UDim.new(0, 8)
    pc.Parent = panel

    local ps = Instance.new("UIStroke")
    ps.Color = Color3.fromRGB(60, 60, 70)
    ps.Thickness = 1
    ps.Parent = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 32)
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    title.BorderSizePixel = 0
    title.Text = "  ⚙ Auto-Interact"
    title.TextColor3 = Color3.fromRGB(230, 230, 240)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = panel

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 8)
    tc.Parent = title

    local tmask = Instance.new("Frame")
    tmask.Size = UDim2.new(1, 0, 0, 8)
    tmask.Position = UDim2.new(0, 0, 1, -8)
    tmask.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    tmask.BorderSizePixel = 0
    tmask.Parent = title

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 24, 0, 24)
    minBtn.Position = UDim2.new(1, -56, 0, 4)
    minBtn.BackgroundColor3 = Color3.fromRGB(200, 160, 60)
    minBtn.BorderSizePixel = 0
    minBtn.Text = "−"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.TextSize = 18
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Parent = title

    local mc = Instance.new("UICorner")
    mc.CornerRadius = UDim.new(0, 6)
    mc.Parent = minBtn

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -28, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = title

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent = closeBtn

    local TAB_HEIGHT = 28
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -20, 0, TAB_HEIGHT)
    tabBar.Position = UDim2.new(0, 10, 0, 40)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = panel

    local TAB_NAMES = { "Collect", "Buildings", "Buy", "Sell", "Conquer", "Settings" }
    local tabButtons = {}
    local tabPages = {}

    for i, tabName in ipairs(TAB_NAMES) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1/6, -2, 1, 0)
        btn.Position = UDim2.new((i-1) * (1/6), 1, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
        btn.BorderSizePixel = 0
        btn.Text = tabName
        btn.TextColor3 = Color3.fromRGB(220, 220, 230)
        btn.TextSize = 10
        btn.Font = Enum.Font.GothamBold
        btn.Parent = tabBar
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 5)
        bc.Parent = btn
        tabButtons[tabName] = btn
    end

    local pageHolder = Instance.new("Frame")
    pageHolder.Size = UDim2.new(1, -20, 1, -40 - TAB_HEIGHT - 10)
    pageHolder.Position = UDim2.new(0, 10, 0, 40 + TAB_HEIGHT + 6)
    pageHolder.BackgroundTransparency = 1
    pageHolder.ClipsDescendants = true
    pageHolder.Parent = panel

    local function makePage(name)
        local p = Instance.new("Frame")
        p.Size = UDim2.new(1, 0, 1, 0)
        p.BackgroundTransparency = 1
        p.Visible = false
        p.Parent = pageHolder
        tabPages[name] = p
        return p
    end

    local collectPage = makePage("Collect")
    local buildingsPage = makePage("Buildings")
    local buyPage = makePage("Buy")
    local sellPage = makePage("Sell")
    local conquerPage = makePage("Conquer")
    local settingsPage = makePage("Settings")

    local function makeButton(parent, yPos, text, height)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -16, 0, height or 30)
        btn.Position = UDim2.new(0, 8, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(230, 230, 240)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.Parent = parent
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn
        return btn
    end

    -- COLLECT
    local collectBtn = makeButton(collectPage, 8, "Auto-Collect: OFF", 40)
    local farmBtn = makeButton(collectPage, 54, "Farm: ON", 30)
    local milBtn = makeButton(collectPage, 88, "Military: OFF", 30)
    local houseBtn = makeButton(collectPage, 122, "House: OFF", 30)
    local antiAfkBtn = makeButton(collectPage, 158, "Anti-AFK: ON (19 min)", 30)

    local collectStatus = Instance.new("TextLabel")
    collectStatus.Size = UDim2.new(1, -16, 0, 18)
    collectStatus.Position = UDim2.new(0, 8, 0, 194)
    collectStatus.BackgroundTransparency = 1
    collectStatus.Text = "Initializing..."
    collectStatus.TextColor3 = Color3.fromRGB(160, 160, 170)
    collectStatus.TextSize = 12
    collectStatus.Font = Enum.Font.Gotham
    collectStatus.TextXAlignment = Enum.TextXAlignment.Left
    collectStatus.Parent = collectPage

    local collectStats = Instance.new("TextLabel")
    collectStats.Size = UDim2.new(1, -16, 0, 60)
    collectStats.Position = UDim2.new(0, 8, 0, 216)
    collectStats.BackgroundTransparency = 1
    collectStats.Text = "Buildings: 0\nCollect fires: 0\nAnti-AFK saves: 0"
    collectStats.TextColor3 = Color3.fromRGB(200, 200, 210)
    collectStats.TextSize = 11
    collectStats.Font = Enum.Font.Code
    collectStats.TextXAlignment = Enum.TextXAlignment.Left
    collectStats.TextYAlignment = Enum.TextYAlignment.Top
    collectStats.Parent = collectPage

    -- BUILDINGS
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = buildingsPage
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 6)
    sc.Parent = scroll
    local sPad = Instance.new("UIPadding")
    sPad.PaddingTop = UDim.new(0, 4)
    sPad.PaddingBottom = UDim.new(0, 4)
    sPad.PaddingLeft = UDim.new(0, 4)
    sPad.PaddingRight = UDim.new(0, 4)
    sPad.Parent = scroll
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 3)
    listLayout.Parent = scroll

    -- BUY
    local buyToggleBtn = makeButton(buyPage, 6, "Auto-Buy: OFF", 32)

    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Size = UDim2.new(1, -16, 0, 14)
    moneyLabel.Position = UDim2.new(0, 8, 0, 40)
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.Text = "Money: loading..."
    moneyLabel.TextColor3 = Color3.fromRGB(180, 220, 180)
    moneyLabel.TextSize = 11
    moneyLabel.Font = Enum.Font.Code
    moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
    moneyLabel.Parent = buyPage

    local tabRow = Instance.new("Frame")
    tabRow.Size = UDim2.new(1, -16, 0, 22)
    tabRow.Position = UDim2.new(0, 8, 0, 56)
    tabRow.BackgroundTransparency = 1
    tabRow.Parent = buyPage

    local shopButtons = {}
    for i, shopName in ipairs(SHOP_TABS) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.25, -3, 1, 0)
        btn.Position = UDim2.new((i-1) * 0.25, 1.5, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
        btn.BorderSizePixel = 0
        btn.Text = shopName
        btn.TextColor3 = Color3.fromRGB(220, 220, 230)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.Parent = tabRow
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 4)
        bc.Parent = btn
        shopButtons[shopName] = btn
    end

    local itemScroll = Instance.new("ScrollingFrame")
    itemScroll.Size = UDim2.new(1, -16, 1, -134)
    itemScroll.Position = UDim2.new(0, 8, 0, 84)
    itemScroll.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    itemScroll.BorderSizePixel = 0
    itemScroll.ScrollBarThickness = 4
    itemScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
    itemScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    itemScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    itemScroll.Parent = buyPage
    local isc = Instance.new("UICorner")
    isc.CornerRadius = UDim.new(0, 6)
    isc.Parent = itemScroll
    local isPad = Instance.new("UIPadding")
    isPad.PaddingTop = UDim.new(0, 4)
    isPad.PaddingBottom = UDim.new(0, 4)
    isPad.PaddingLeft = UDim.new(0, 4)
    isPad.PaddingRight = UDim.new(0, 4)
    isPad.Parent = itemScroll
    local itemLayout = Instance.new("UIListLayout")
    itemLayout.Padding = UDim.new(0, 3)
    itemLayout.Parent = itemScroll

    local selectAllBtn = Instance.new("TextButton")
    selectAllBtn.Size = UDim2.new(0.32, -3, 0, 26)
    selectAllBtn.Position = UDim2.new(0, 8, 1, -58)
    selectAllBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 85)
    selectAllBtn.BorderSizePixel = 0
    selectAllBtn.Text = "All"
    selectAllBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
    selectAllBtn.TextSize = 12
    selectAllBtn.Font = Enum.Font.GothamBold
    selectAllBtn.Parent = buyPage
    local sac = Instance.new("UICorner")
    sac.CornerRadius = UDim.new(0, 6)
    sac.Parent = selectAllBtn

    local clearAllBtn = Instance.new("TextButton")
    clearAllBtn.Size = UDim2.new(0.32, -3, 0, 26)
    clearAllBtn.Position = UDim2.new(0.34, 0, 1, -58)
    clearAllBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 85)
    clearAllBtn.BorderSizePixel = 0
    clearAllBtn.Text = "None"
    clearAllBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
    clearAllBtn.TextSize = 12
    clearAllBtn.Font = Enum.Font.GothamBold
    clearAllBtn.Parent = buyPage
    local cac = Instance.new("UICorner")
    cac.CornerRadius = UDim.new(0, 6)
    cac.Parent = clearAllBtn

    local buyNowBtn = Instance.new("TextButton")
    buyNowBtn.Size = UDim2.new(0.32, -3, 0, 26)
    buyNowBtn.Position = UDim2.new(0.68, 0, 1, -58)
    buyNowBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 70)
    buyNowBtn.BorderSizePixel = 0
    buyNowBtn.Text = "Buy Now"
    buyNowBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
    buyNowBtn.TextSize = 12
    buyNowBtn.Font = Enum.Font.GothamBold
    buyNowBtn.Parent = buyPage
    local bnc = Instance.new("UICorner")
    bnc.CornerRadius = UDim.new(0, 6)
    bnc.Parent = buyNowBtn

    local selectedCountLabel = Instance.new("TextLabel")
    selectedCountLabel.Size = UDim2.new(1, -16, 0, 14)
    selectedCountLabel.Position = UDim2.new(0, 8, 1, -30)
    selectedCountLabel.BackgroundTransparency = 1
    selectedCountLabel.Text = "Selected: 0"
    selectedCountLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    selectedCountLabel.TextSize = 11
    selectedCountLabel.Font = Enum.Font.Gotham
    selectedCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedCountLabel.Parent = buyPage

    -- SELL
    local sellToggleBtn = makeButton(sellPage, 8, "Auto-Sell: OFF", 40)

    local sellIntervalBox = Instance.new("TextBox")
    sellIntervalBox.Size = UDim2.new(1, -16, 0, 28)
    sellIntervalBox.Position = UDim2.new(0, 8, 0, 56)
    sellIntervalBox.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    sellIntervalBox.BorderSizePixel = 0
    sellIntervalBox.Text = "5"
    sellIntervalBox.TextColor3 = Color3.fromRGB(220, 220, 230)
    sellIntervalBox.TextSize = 13
    sellIntervalBox.Font = Enum.Font.Code
    sellIntervalBox.ClearTextOnFocus = false
    sellIntervalBox.Parent = sellPage
    local sic = Instance.new("UICorner")
    sic.CornerRadius = UDim.new(0, 6)
    sic.Parent = sellIntervalBox

    local intervalLabel = Instance.new("TextLabel")
    intervalLabel.Size = UDim2.new(1, -16, 0, 16)
    intervalLabel.Position = UDim2.new(0, 8, 0, 88)
    intervalLabel.BackgroundTransparency = 1
    intervalLabel.Text = "  └ sell interval (seconds)"
    intervalLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
    intervalLabel.TextSize = 11
    intervalLabel.Font = Enum.Font.Gotham
    intervalLabel.TextXAlignment = Enum.TextXAlignment.Left
    intervalLabel.Parent = sellPage

    local sellStats = Instance.new("TextLabel")
    sellStats.Size = UDim2.new(1, -16, 0, 20)
    sellStats.Position = UDim2.new(0, 8, 0, 112)
    sellStats.BackgroundTransparency = 1
    sellStats.Text = "Sell fires: 0"
    sellStats.TextColor3 = Color3.fromRGB(200, 200, 210)
    sellStats.TextSize = 12
    sellStats.Font = Enum.Font.Code
    sellStats.TextXAlignment = Enum.TextXAlignment.Left
    sellStats.Parent = sellPage

    -- ============================================================
    -- CONQUER PAGE
    -- ============================================================
    local conquerBestBtn = makeButton(conquerPage, 6, "⭐ CONQUER BEST (Adaptive)", 32)
    conquerBestBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 30)
    conquerBestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    conquerBestBtn.TextSize = 12

    local conquerToggleBtn = makeButton(conquerPage, 42, "Auto-Conquer: OFF", 30)

    local armyLabel = Instance.new("TextLabel")
    armyLabel.Size = UDim2.new(1, -16, 0, 14)
    armyLabel.Position = UDim2.new(0, 8, 0, 76)
    armyLabel.BackgroundTransparency = 1
    armyLabel.Text = "Navy Index (1-4):"
    armyLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    armyLabel.TextSize = 11
    armyLabel.Font = Enum.Font.Gotham
    armyLabel.TextXAlignment = Enum.TextXAlignment.Left
    armyLabel.Parent = conquerPage

    local armyBox = Instance.new("TextBox")
    armyBox.Size = UDim2.new(1, -16, 0, 24)
    armyBox.Position = UDim2.new(0, 8, 0, 92)
    armyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    armyBox.BorderSizePixel = 0
    armyBox.Text = "1"
    armyBox.TextColor3 = Color3.fromRGB(220, 220, 230)
    armyBox.TextSize = 12
    armyBox.Font = Enum.Font.Code
    armyBox.ClearTextOnFocus = false
    armyBox.Parent = conquerPage
    local ac1 = Instance.new("UICorner")
    ac1.CornerRadius = UDim.new(0, 6)
    ac1.Parent = armyBox

    local conquerTypes = {
        Camp = true, Lab = true, MilitaryBase = true, Garnison = true, City = true,
    }

    local typeToggleButtons = {}
    local ty = 122
    for _, baseType in ipairs({ "Camp", "Lab", "MilitaryBase", "Garnison", "City" }) do
        local btn = makeButton(conquerPage, ty, BASE_TYPE_DISPLAY[baseType] .. ": ON", 22)
        btn.BackgroundColor3 = Color3.fromRGB(40, 130, 70)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 10
        typeToggleButtons[baseType] = btn
        ty = ty + 24
    end

    local conquerStatus = Instance.new("TextLabel")
    conquerStatus.Size = UDim2.new(1, -16, 0, 60)
    conquerStatus.Position = UDim2.new(0, 8, 0, ty + 2)
    conquerStatus.BackgroundTransparency = 1
    conquerStatus.Text = "Idle"
    conquerStatus.TextColor3 = Color3.fromRGB(180, 180, 190)
    conquerStatus.TextSize = 10
    conquerStatus.Font = Enum.Font.Code
    conquerStatus.TextXAlignment = Enum.TextXAlignment.Left
    conquerStatus.TextYAlignment = Enum.TextYAlignment.Top
    conquerStatus.TextWrapped = true
    conquerStatus.Parent = conquerPage

    local conquerStats = Instance.new("TextLabel")
    conquerStats.Size = UDim2.new(1, -16, 0, 16)
    conquerStats.Position = UDim2.new(0, 8, 0, ty + 66)
    conquerStats.BackgroundTransparency = 1
    conquerStats.Text = "Dropped: 0  |  Captured: 0  |  Slots: 0/0"
    conquerStats.TextColor3 = Color3.fromRGB(200, 200, 210)
    conquerStats.TextSize = 10
    conquerStats.Font = Enum.Font.Code
    conquerStats.TextXAlignment = Enum.TextXAlignment.Left
    conquerStats.Parent = conquerPage

    local conquerState = {
        enabled = false, capturedCount = 0, timeoutCount = 0, lastTarget = nil,
    }

    local function getAllOutposts()
        local root = workspace:FindFirstChild("MilitaryMap")
        root = root and root:FindFirstChild("Object")
        if not root then return {} end

        local outposts = {}
        for _, faction in ipairs(root:GetChildren()) do
            if faction:IsA("Folder") or faction:IsA("Model") then
                for _, child in ipairs(faction:GetChildren()) do
                    if child:IsA("Model") then
                        local baseType = child:GetAttribute("baseType")
                        if baseType then
                            table.insert(outposts, { instance = child, baseType = baseType })
                        end
                    end
                end
            end
        end
        return outposts
    end

    local function sendArmyTo(armyIndex, targetInstance)
        local ok = pcall(function()
            dataRemoteEvent:FireServer({
                { armyIndex = armyIndex, capturePoint = targetInstance },
                CONFIG.CONQUER_OPCODE
            })
        end)
        return ok
    end

    local function getPriority(instance)
        local bt = instance:GetAttribute("baseType")
        return PRIORITY[bt] or 99
    end

    local function isOwnedByMe(instance)
        return instance:GetAttribute("Owner") == player.Name
    end

    -- ============================================================
    -- UNCLAIM: finds the "Unclaim base" prompt by ActionText
    -- ============================================================
    local function unclaimOutpost(instance)
        print("[Unclaim] ══════════════════════════════════")
        print("[Unclaim] Target: " .. instance:GetFullName())

        local holder = instance:FindFirstChild("PromptHolder")
        if not holder then
            print("[Unclaim] ❌ No PromptHolder")
            return false, "No PromptHolder"
        end

        local prompt = nil
        local allPrompts = {}
        for _, child in ipairs(holder:GetChildren()) do
            if child:IsA("ProximityPrompt") then
                table.insert(allPrompts, child)
                local action = tostring(child.ActionText or ""):lower()
                if action:find("unclaim") then
                    prompt = child
                    print("[Unclaim] ✅ Found UNCLAIM prompt: " .. tostring(child.ActionText))
                    break
                end
            end
        end

        if not prompt then
            for _, child in ipairs(holder:GetDescendants()) do
                if child:IsA("ProximityPrompt") then
                    local action = tostring(child.ActionText or ""):lower()
                    if action:find("unclaim") then
                        prompt = child
                        print("[Unclaim] ✅ Found UNCLAIM prompt (descendant): " .. tostring(child.ActionText))
                        break
                    end
                end
            end
        end

        if not prompt then
            print("[Unclaim] ❌ No 'Unclaim' prompt found. Prompts in holder:")
            for _, p in ipairs(allPrompts) do
                print("    - " .. tostring(p.ActionText) .. " (Key=" .. tostring(p.KeyboardKeyCode) .. ")")
            end
            return false, "No unclaim prompt"
        end

        local flagPos = nil
        if prompt.Parent and prompt.Parent:IsA("Attachment") then
            local ok, wp = pcall(function() return prompt.Parent.WorldPosition end)
            if ok and wp then flagPos = wp end
        end
        if not flagPos and prompt.Parent and prompt.Parent:IsA("BasePart") then
            flagPos = prompt.Parent.Position
        end
        if not flagPos and holder:IsA("Attachment") then
            local ok, wp = pcall(function() return holder.WorldPosition end)
            if ok and wp then flagPos = wp end
        end
        if not flagPos then
            local bp = instance:FindFirstChildWhichIsA("BasePart", true)
            if bp then flagPos = bp.Position end
        end

        if not flagPos then
            print("[Unclaim] ❌ Could not determine flag position")
            return false, "No flag position"
        end

        print("[Unclaim] Flag pos: " .. tostring(flagPos))

        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            print("[Unclaim] ❌ No character")
            return false, "No character"
        end

        local targetPos = flagPos + Vector3.new(0, 3, 0)
        print("[Unclaim] Teleporting to: " .. tostring(targetPos))

        for attempt = 1, 5 do
            pcall(function()
                root.CFrame = CFrame.new(targetPos)
            end)
            task.wait(0.08)
        end

        local dist = (root.Position - flagPos).Magnitude
        print("[Unclaim] Distance after TP: " .. math.floor(dist) .. " studs")

        task.wait(0.5)

        if not prompt.Enabled then
            local waitStart = tick()
            while not prompt.Enabled and tick() - waitStart < 3 do
                task.wait(0.1)
            end
        end
        print("[Unclaim] Prompt enabled: " .. tostring(prompt.Enabled))

        if type(fireproximityprompt) == "function" then
            print("[Unclaim] Firing fireproximityprompt on: " .. tostring(prompt.ActionText))
            pcall(fireproximityprompt, prompt)
            task.wait(1.5)
            if instance:GetAttribute("Owner") ~= player.Name then
                print("[Unclaim] ✅ SUCCESS via fireproximityprompt")
                return true
            end
            print("[Unclaim] ⚠ fireproximityprompt didn't change owner")
        end

        print("[Unclaim] Trying prompt.Triggered:Fire...")
        pcall(function()
            prompt.Triggered:Fire(player)
        end)
        task.wait(1.5)
        if instance:GetAttribute("Owner") ~= player.Name then
            print("[Unclaim] ✅ SUCCESS via Triggered")
            return true
        end

        print("[Unclaim] Trying VirtualUser: Hold R...")
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ButtonDown(Enum.KeyCode.R)
        end)
        task.wait(3)
        pcall(function()
            VirtualUser:ButtonUp(Enum.KeyCode.R)
        end)
        task.wait(1.5)

        if instance:GetAttribute("Owner") ~= player.Name then
            print("[Unclaim] ✅ SUCCESS via VirtualUser")
            return true
        end

        print("[Unclaim] ❌ All methods failed")
        return false, "All failed"
    end

    local function areConquersFull()
        local label = player:FindFirstChild("PlayerGui")
            and player.PlayerGui:FindFirstChild("ArmyControl")
            and player.PlayerGui.ArmyControl:FindFirstChild("Holder")
            and player.PlayerGui.ArmyControl.Holder:FindFirstChild("ArmyControlFrame")
            and player.PlayerGui.ArmyControl.Holder.ArmyControlFrame:FindFirstChild("Conquered")
            and player.PlayerGui.ArmyControl.Holder.ArmyControlFrame.Conquered:FindFirstChild("TotalconqueredBasses")

        if label and label:IsA("TextLabel") then
            local cur, max = label.Text:match("(%d+)%s*/%s*(%d+)")
            if cur and max then
                cur = tonumber(cur)
                max = tonumber(max)
                if cur and max and max > 0 and cur >= max then
                    return true, cur, max
                end
                return false, cur, max
            end
        end
        return false, 0, 8
    end

    local function waitForCapture(targetInstance, dispName)
        local startTime = tick()
        while tick() - startTime < CONFIG.CONQUER_TIMEOUT do
            if state.unloaded then return false end
            local owner = targetInstance:GetAttribute("Owner")
            if owner == player.Name then return true end

            local progress = targetInstance:GetAttribute("ClaimProgress")
            local progressText
            if progress == nil or progress == -1 then
                progressText = "idle"
            elseif type(progress) == "number" then
                progressText = string.format("%d%%", math.floor(progress * 100))
            else
                progressText = tostring(progress)
            end

            local elapsed = math.floor(tick() - startTime)
            local _, cur, max = areConquersFull()
            conquerStatus.Text = string.format(
                "🎯 [%d/%d] Capturing %s (%s)\nOwner: %s | Progress: %s | %ds",
                cur or 0, max or 0, targetInstance.Name, dispName or "",
                tostring(owner), progressText, elapsed
            )
            task.wait(CONFIG.CONQUER_POLL)
        end
        return false
    end

    -- ============================================================
    -- ADAPTIVE CONQUER BEST (continuous loop)
    -- ============================================================
    local conquerBestRunning = false
    local conquerBestLoop = false

    local function runConquerBest()
        if conquerBestRunning then
            conquerBestLoop = not conquerBestLoop
            if not conquerBestLoop then
                conquerBestRunning = false
                conquerBestBtn.Text = "⭐ CONQUER BEST (Adaptive)"
                conquerBestBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 30)
                conquerStatus.Text = "Adaptive mode stopped"
                conquerStatus.TextColor3 = Color3.fromRGB(180, 180, 190)
            end
            return
        end

        conquerBestRunning = true
        conquerBestLoop = true
        conquerBestBtn.Text = "⏹ STOP ADAPTIVE"
        conquerBestBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)

        task.spawn(function()
            local armyIndex = tonumber(armyBox.Text) or 1
            armyIndex = math.clamp(math.floor(armyIndex), 1, 4)

            local droppedCount = 0
            local capturedCount = 0

            while conquerBestLoop and not state.unloaded do
                local full, cur, max = areConquersFull()
                cur = cur or 0
                max = max or 8

                local owned = {}
                local unowned = {}
                for _, o in ipairs(getAllOutposts()) do
                    if isOwnedByMe(o.instance) then
                        table.insert(owned, o)
                    else
                        table.insert(unowned, o)
                    end
                end

                -- Find low-value owned
                local lowValueOwned = {}
                for _, o in ipairs(owned) do
                    local tier = getPriority(o.instance)
                    if tier > CONFIG.MIN_ACCEPTABLE_TIER then
                        table.insert(lowValueOwned, o)
                    end
                end

                -- ADAPTIVE STEP 1: Drop low-value outposts
                if #lowValueOwned > 0 then
                    table.sort(lowValueOwned, function(a, b)
                        return getPriority(a.instance) > getPriority(b.instance)
                    end)

                    local target = lowValueOwned[1]
                    local tier = getPriority(target.instance)
                    local disp = BASE_TYPE_DISPLAY[target.baseType] or target.baseType

                    conquerStatus.Text = string.format(
                        "🧹 Dropping %s (tier %d)...",
                        disp, tier
                    )
                    conquerStatus.TextColor3 = Color3.fromRGB(220, 180, 100)

                    local ok, err = unclaimOutpost(target.instance)
                    print("[Adaptive] Unclaim " .. target.instance:GetFullName() .. ": " .. tostring(ok))

                    if not ok then
                        conquerStatus.Text = "❌ Unclaim failed: " .. tostring(err)
                        task.wait(5)
                    else
                        local waitStart = tick()
                        while isOwnedByMe(target.instance) do
                            if tick() - waitStart > 15 then break end
                            task.wait(0.5)
                        end
                        droppedCount = droppedCount + 1
                        task.wait(2)
                    end

                    local _, c2, m2 = areConquersFull()
                    conquerStats.Text = string.format(
                        "Dropped: %d  |  Captured: %d  |  Slots: %d/%d",
                        droppedCount, capturedCount, c2 or 0, m2 or 0
                    )
                    continue
                end

                -- ADAPTIVE STEP 2: Best first
                table.sort(unowned, function(a, b)
                    return getPriority(a.instance) < getPriority(b.instance)
                end)

                if #unowned == 0 then
                    conquerStatus.Text = string.format(
                        "✅ All outposts optimized!\nDropped: %d | Captured: %d",
                        droppedCount, capturedCount
                    )
                    conquerStatus.TextColor3 = Color3.fromRGB(120, 220, 120)
                    task.wait(10)
                    continue
                end

                if cur < max then
                    local bestTarget = unowned[1]
                    local bestTier = getPriority(bestTarget.instance)
                    local bestDisp = BASE_TYPE_DISPLAY[bestTarget.baseType] or bestTarget.baseType

                    if bestTier <= CONFIG.MIN_ACCEPTABLE_TIER then
                        conquerStatus.Text = string.format(
                            "🎯 [%d/%d] Capturing %s (%s)...",
                            cur, max, bestTarget.instance.Name, bestDisp
                        )
                        conquerStatus.TextColor3 = Color3.fromRGB(180, 180, 190)

                        sendArmyTo(armyIndex, bestTarget.instance)
                        if waitForCapture(bestTarget.instance, bestDisp) then
                            capturedCount = capturedCount + 1
                        end
                        task.wait(2)
                    else
                        conquerStatus.Text = string.format(
                            "✅ Own only %d good outposts. Waiting for better targets...\nDropped: %d | Captured: %d",
                            #owned, droppedCount, capturedCount
                        )
                        conquerStatus.TextColor3 = Color3.fromRGB(120, 220, 120)
                        task.wait(10)
                    end
                else
                    conquerStatus.Text = string.format(
                        "✅ At cap with all good outposts!\nDropped: %d | Captured: %d",
                        droppedCount, capturedCount
                    )
                    conquerStatus.TextColor3 = Color3.fromRGB(120, 220, 120)
                    task.wait(10)
                end

                local _, c2, m2 = areConquersFull()
                conquerStats.Text = string.format(
                    "Dropped: %d  |  Captured: %d  |  Slots: %d/%d",
                    droppedCount, capturedCount, c2 or 0, m2 or 0
                )
            end

            conquerBestRunning = false
            conquerBestBtn.Text = "⭐ CONQUER BEST (Adaptive)"
            conquerBestBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 30)
        end)
    end

    -- Main auto-conquer loop
    table.insert(state.threads, task.spawn(function()
        while not state.unloaded do
            task.wait(1)

            if not conquerState.enabled then
                task.wait(1)
                continue
            end

            local full, cur, max = areConquersFull()
            if full then
                conquerState.enabled = false
                conquerToggleBtn.Text = "Auto-Conquer: OFF"
                conquerToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                conquerStatus.Text = string.format("🛑 SLOTS FULL (%d/%d)", cur, max)
                conquerStatus.TextColor3 = Color3.fromRGB(220, 180, 100)
                continue
            end

            local armyIndex = tonumber(armyBox.Text) or 1
            armyIndex = math.clamp(math.floor(armyIndex), 1, 4)

            local candidates = {}
            for _, o in ipairs(getAllOutposts()) do
                if not isOwnedByMe(o.instance) and conquerTypes[o.baseType] then
                    table.insert(candidates, o)
                end
            end

            if #candidates == 0 then
                conquerStatus.Text = "✅ All enabled outposts owned!"
                task.wait(5)
                continue
            end

            local target = candidates[1]
            local disp = BASE_TYPE_DISPLAY[target.baseType] or target.baseType

            sendArmyTo(armyIndex, target.instance)
            if waitForCapture(target.instance, disp) then
                conquerState.capturedCount = conquerState.capturedCount + 1
            else
                conquerState.timeoutCount = conquerState.timeoutCount + 1
            end

            local _, c2, m2 = areConquersFull()
            conquerStats.Text = string.format("Captured: %d  |  Timed out: %d  |  Slots: %d/%d",
                conquerState.capturedCount, conquerState.timeoutCount, c2 or 0, m2 or 0)
        end
    end))

    trackConnection(conquerBestBtn.MouseButton1Click:Connect(runConquerBest))

    trackConnection(conquerToggleBtn.MouseButton1Click:Connect(function()
        conquerState.enabled = not conquerState.enabled
        if conquerState.enabled then
            conquerToggleBtn.Text = "Auto-Conquer: ON"
            conquerToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 130, 70)
        else
            conquerToggleBtn.Text = "Auto-Conquer: OFF"
            conquerToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        end
    end))

    for baseType, btn in pairs(typeToggleButtons) do
        trackConnection(btn.MouseButton1Click:Connect(function()
            conquerTypes[baseType] = not conquerTypes[baseType]
            if conquerTypes[baseType] then
                btn.Text = BASE_TYPE_DISPLAY[baseType] .. ": ON"
                btn.BackgroundColor3 = Color3.fromRGB(40, 130, 70)
            else
                btn.Text = BASE_TYPE_DISPLAY[baseType] .. ": OFF"
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            end
        end))
    end

    -- SETTINGS (public — no admin features)
    local saveCfgBtn = makeButton(settingsPage, 8, "💾 Save Config", 26)
    local loadCfgBtn = makeButton(settingsPage, 38, "📂 Load Config", 26)
    local delCfgBtn = makeButton(settingsPage, 68, "🗑 Delete Saved Config", 26)
    local strictMoneyBtn = makeButton(settingsPage, 98, "Strict Money Check: ON", 26)
    local resetKeyBtn = makeButton(settingsPage, 128, "🔑 Reset Key", 26)

    local settingsStatus = Instance.new("TextLabel")
    settingsStatus.Size = UDim2.new(1, -16, 0, 60)
    settingsStatus.Position = UDim2.new(0, 8, 0, 162)
    settingsStatus.BackgroundTransparency = 1
    settingsStatus.Text = "File API: " .. tostring(HAS_FILE_API)
    settingsStatus.TextColor3 = Color3.fromRGB(180, 180, 190)
    settingsStatus.TextSize = 10
    settingsStatus.Font = Enum.Font.Code
    settingsStatus.TextXAlignment = Enum.TextXAlignment.Left
    settingsStatus.TextYAlignment = Enum.TextYAlignment.Top
    settingsStatus.TextWrapped = true
    settingsStatus.Parent = settingsPage

    local renderShopItems, updateUI, saveConfig, loadConfig

    local function setSettingsStatus(msg, color)
        settingsStatus.Text = msg
        settingsStatus.TextColor3 = color or Color3.fromRGB(180, 180, 190)
    end

    local function showTab(tabName)
        state.activeTab = tabName
        for name, page in pairs(tabPages) do page.Visible = (name == tabName) end
        for name, btn in pairs(tabButtons) do
            btn.BackgroundColor3 = (name == tabName)
                and Color3.fromRGB(80, 130, 90) or Color3.fromRGB(50, 55, 70)
            btn.TextColor3 = (name == tabName)
                and Color3.fromRGB(240, 255, 245) or Color3.fromRGB(220, 220, 230)
        end
    end

    for tabName, btn in pairs(tabButtons) do
        trackConnection(btn.MouseButton1Click:Connect(function() showTab(tabName) end))
    end
    showTab("Collect")

    local function setVisible(v)
        state.panel.Visible = v
        state.reopenBtn.Visible = not v
    end

    local reopenBtn = Instance.new("TextButton")
    reopenBtn.Size = UDim2.new(0, 44, 0, 44)
    reopenBtn.Position = UDim2.new(0, 12, 0, 60)
    reopenBtn.BackgroundColor3 = Color3.fromRGB(40, 130, 70)
    reopenBtn.BorderSizePixel = 0
    reopenBtn.Text = "S"
    reopenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    reopenBtn.TextSize = 22
    reopenBtn.Font = Enum.Font.GothamBold
    reopenBtn.Visible = false
    reopenBtn.Parent = screenGui
    state.reopenBtn = reopenBtn
    local rbc = Instance.new("UICorner")
    rbc.CornerRadius = UDim.new(1, 0)
    rbc.Parent = reopenBtn
    local rbs = Instance.new("UIStroke")
    rbs.Color = Color3.fromRGB(80, 200, 120)
    rbs.Thickness = 2
    rbs.Parent = reopenBtn

    trackConnection(reopenBtn.MouseButton1Click:Connect(function() setVisible(true) end))
    trackConnection(minBtn.MouseButton1Click:Connect(function() setVisible(false) end))

    local function unload()
        if state.unloaded then return end
        state.unloaded = true
        state.collecting = false
        state.selling = false
        state.buying = false
        conquerState.enabled = false
        conquerBestLoop = false
        conquerBestRunning = false
        for _, conn in ipairs(state.connections) do pcall(function() conn:Disconnect() end) end
        state.connections = {}
        if state.screenGui then pcall(function() state.screenGui:Destroy() end) end
        print("[AutoInteract] Unloaded.")
    end
    closeBtn.MouseButton1Click:Connect(unload)

    local function serializeTable(t)
        local function enc(v)
            local ty = type(v)
            if ty == "string" then return string.format("%q", v) end
            if ty == "number" or ty == "boolean" then return tostring(v) end
            if ty == "table" then
                local parts = {}
                for k, val in pairs(v) do
                    local key = type(k) == "string" and string.format("[%q]", k) or "[" .. tostring(k) .. "]"
                    table.insert(parts, key .. "=" .. enc(val))
                end
                return "{" .. table.concat(parts, ",") .. "}"
            end
            return "nil"
        end
        return enc(t)
    end

    local function deserializeTable(str)
        local fn = loadstring("return " .. str)
        if not fn then return nil end
        local ok, result = pcall(fn)
        if ok and type(result) == "table" then return result end
        return nil
    end

    local function formatMoney(n)
        if n >= 1e9 then return string.format("%.2fB", n / 1e9) end
        if n >= 1e6 then return string.format("%.2fM", n / 1e6) end
        if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
        return tostring(math.floor(n))
    end

    local function getSelectedCount()
        local n = 0
        for _, v in pairs(state.selectedItems) do if v then n = n + 1 end end
        return n
    end

    renderShopItems = function()
        for _, c in ipairs(itemScroll:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
        end
        for shopName, btn in pairs(shopButtons) do
            btn.BackgroundColor3 = (shopName == state.currentShop)
                and Color3.fromRGB(80, 130, 90) or Color3.fromRGB(50, 55, 70)
        end
        local items = SHOP_CATALOG[state.currentShop] or {}
        for _, item in ipairs(items) do
            local folderName = item.folder
            local displayName = item.display
            local price = PRICES[folderName]

            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1, -4, 0, 22)
            row.BackgroundColor3 = Color3.fromRGB(38, 38, 44)
            row.BorderSizePixel = 0
            row.Text = ""
            row.AutoButtonColor = false
            row.Parent = itemScroll
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 4)
            c.Parent = row

            local check = Instance.new("TextLabel")
            check.Size = UDim2.new(0, 20, 1, 0)
            check.Position = UDim2.new(0, 4, 0, 0)
            check.BackgroundTransparency = 1
            check.Text = state.selectedItems[folderName] and "☑" or "☐"
            check.TextColor3 = state.selectedItems[folderName]
                and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(150, 150, 160)
            check.TextSize = 15
            check.Font = Enum.Font.GothamBold
            check.Parent = row

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -100, 1, 0)
            label.Position = UDim2.new(0, 26, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = displayName
            label.TextColor3 = Color3.fromRGB(220, 220, 230)
            label.TextSize = 11
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.Parent = row

            local priceLabel = Instance.new("TextLabel")
            priceLabel.Size = UDim2.new(0, 70, 1, 0)
            priceLabel.Position = UDim2.new(1, -74, 0, 0)
            priceLabel.BackgroundTransparency = 1
            priceLabel.Text = price and ("$" .. formatMoney(price)) or "?"
            priceLabel.TextColor3 = price and Color3.fromRGB(180, 220, 180) or Color3.fromRGB(160, 160, 160)
            priceLabel.TextSize = 10
            priceLabel.Font = Enum.Font.Code
            priceLabel.TextXAlignment = Enum.TextXAlignment.Right
            priceLabel.Parent = row

            local capturedFolder = folderName
            row.MouseButton1Click:Connect(function()
                state.selectedItems[capturedFolder] = not state.selectedItems[capturedFolder]
                check.Text = state.selectedItems[capturedFolder] and "☑" or "☐"
                check.TextColor3 = state.selectedItems[capturedFolder]
                    and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(150, 150, 160)
                selectedCountLabel.Text = "Selected: " .. getSelectedCount()
            end)
        end
        selectedCountLabel.Text = "Selected: " .. getSelectedCount()
    end

    for shopName, btn in pairs(shopButtons) do
        trackConnection(btn.MouseButton1Click:Connect(function()
            state.currentShop = shopName
            renderShopItems()
        end))
    end

    trackConnection(selectAllBtn.MouseButton1Click:Connect(function()
        for _, item in ipairs(SHOP_CATALOG[state.currentShop] or {}) do
            state.selectedItems[item.folder] = true
        end
        renderShopItems()
    end))
    trackConnection(clearAllBtn.MouseButton1Click:Connect(function()
        for _, item in ipairs(SHOP_CATALOG[state.currentShop] or {}) do
            state.selectedItems[item.folder] = nil
        end
        renderShopItems()
    end))

    local function buyItem(folderName)
        local shop = SHOP_BY_ITEM[folderName]
        if not shop then return false end
        local ok = pcall(function()
            dataRemoteEvent:FireServer({
                { item = folderName, shop = shop },
                CONFIG.BUY_OPCODE
            })
        end)
        if ok then state.buyFires = state.buyFires + 1 end
        return ok
    end

    local function getSelectedList()
        local list = {}
        for folderName, sel in pairs(state.selectedItems) do
            if sel then table.insert(list, folderName) end
        end
        return list
    end

    local function buyAllSelected()
        local list = getSelectedList()
        if #list == 0 then return end
        local myMoney = getMyMoney()
        for _, folderName in ipairs(list) do
            if state.unloaded then return end
            local price = PRICES[folderName]
            if state.strictMoney then
                if not price then state.buySkips = state.buySkips + 1
                elseif myMoney >= price then
                    buyItem(folderName)
                    myMoney = myMoney - price
                    task.wait(CONFIG.BUY_ITEM_GAP)
                else
                    state.buySkips = state.buySkips + 1
                end
            else
                buyItem(folderName)
                task.wait(CONFIG.BUY_ITEM_GAP)
            end
        end
    end

    trackConnection(buyNowBtn.MouseButton1Click:Connect(function() task.spawn(buyAllSelected) end))

    local function createRow(building, classification)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 22)
        row.BackgroundColor3 = Color3.fromRGB(38, 38, 44)
        row.BorderSizePixel = 0
        row.Parent = scroll
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = row
        local tag = Instance.new("TextLabel")
        tag.Size = UDim2.new(0, 62, 1, -4)
        tag.Position = UDim2.new(0, 2, 0, 2)
        tag.BackgroundColor3 = CLASS_COLORS[classification] or CLASS_COLORS.Other
        tag.BorderSizePixel = 0
        tag.Text = classification:upper()
        tag.TextColor3 = Color3.fromRGB(20, 20, 25)
        tag.TextSize = 9
        tag.Font = Enum.Font.GothamBold
        tag.Parent = row
        local rtc = Instance.new("UICorner")
        rtc.CornerRadius = UDim.new(0, 3)
        rtc.Parent = tag
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -70, 1, 0)
        label.Position = UDim2.new(0, 68, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = building.Name
        label.TextColor3 = Color3.fromRGB(210, 210, 220)
        label.TextSize = 11
        label.Font = Enum.Font.Code
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.Parent = row
    end

    local function refreshList()
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        local folder = state.myBuildingsFolder
        if not folder then return end
        for _, building in ipairs(folder:GetChildren()) do
            createRow(building, classifyBuilding(building))
        end
    end

    local function collectOnce()
        if state.unloaded or not state.collecting then return end
        local folder = state.myBuildingsFolder
        if not folder then return end
        for _, building in ipairs(folder:GetChildren()) do
            if state.unloaded or not state.collecting then return end
            local class = classifyBuilding(building)
            if COLLECT_TYPES[class] then
                dataRemoteEvent:FireServer({ building, CONFIG.COLLECT_OPCODE })
                state.collectFires = state.collectFires + 1
                task.wait(CONFIG.LOOP_DELAY)
            end
        end
    end

    table.insert(state.threads, task.spawn(function()
        while not state.unloaded do
            task.wait(CONFIG.CYCLE_DELAY)
            if state.collecting then collectOnce() end
        end
    end))

    table.insert(state.threads, task.spawn(function()
        while not state.unloaded do
            local interval = tonumber(sellIntervalBox.Text) or CONFIG.SELL_INTERVAL
            if interval < 0.5 then interval = 0.5 end
            task.wait(interval)
            if state.selling and not state.unloaded then
                dataRemoteEvent:FireServer({ nil, CONFIG.SELL_OPCODE })
                state.sellFires = state.sellFires + 1
            end
        end
    end))

    table.insert(state.threads, task.spawn(function()
        while not state.unloaded do
            task.wait(CONFIG.BUY_INTERVAL)
            if state.buying and not state.unloaded then buyAllSelected() end
        end
    end))

    table.insert(state.threads, task.spawn(function()
        while not state.unloaded do
            task.wait(5)
            local current = player:GetAttribute("CurrentBaseSlot")
            if current and tostring(current) ~= CONFIG.MY_PLOT then
                CONFIG.MY_PLOT = tostring(current)
                state.myBuildingsFolder = findMyBuildings()
                refreshList()
            end
        end
    end))

    local typeButtons = { Farm = farmBtn, Military = milBtn, House = houseBtn }

    updateUI = function()
        collectBtn.Text = state.collecting and "Auto-Collect: ON" or "Auto-Collect: OFF"
        collectBtn.BackgroundColor3 = state.collecting and Color3.fromRGB(40, 130, 70) or Color3.fromRGB(60, 60, 70)
        sellToggleBtn.Text = state.selling
            and ("Auto-Sell: ON (" .. (tonumber(sellIntervalBox.Text) or 5) .. "s)") or "Auto-Sell: OFF"
        sellToggleBtn.BackgroundColor3 = state.selling and Color3.fromRGB(40, 130, 70) or Color3.fromRGB(60, 60, 70)
        buyToggleBtn.Text = state.buying and ("Auto-Buy: ON (" .. getSelectedCount() .. ")") or "Auto-Buy: OFF"
        buyToggleBtn.BackgroundColor3 = state.buying and Color3.fromRGB(40, 130, 70) or Color3.fromRGB(60, 60, 70)
        antiAfkBtn.Text = state.antiAfkEnabled and "Anti-AFK: ON (19 min)" or "Anti-AFK: OFF"
        antiAfkBtn.BackgroundColor3 = state.antiAfkEnabled and Color3.fromRGB(40, 130, 70) or Color3.fromRGB(60, 60, 70)
        strictMoneyBtn.Text = state.strictMoney and "Strict Money Check: ON" or "Strict Money Check: OFF"
        strictMoneyBtn.BackgroundColor3 = state.strictMoney and Color3.fromRGB(40, 130, 70) or Color3.fromRGB(120, 80, 60)
        for typeName, btn in pairs(typeButtons) do
            if COLLECT_TYPES[typeName] then
                btn.Text = typeName .. ": ON"
                btn.BackgroundColor3 = CLASS_COLORS[typeName]
                btn.TextColor3 = Color3.fromRGB(20, 20, 25)
            else
                btn.Text = typeName .. ": OFF"
                btn.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
                btn.TextColor3 = Color3.fromRGB(220, 220, 230)
            end
        end
    end

    trackConnection(collectBtn.MouseButton1Click:Connect(function() state.collecting = not state.collecting; updateUI() end))
    trackConnection(sellToggleBtn.MouseButton1Click:Connect(function() state.selling = not state.selling; updateUI() end))
    trackConnection(buyToggleBtn.MouseButton1Click:Connect(function() state.buying = not state.buying; updateUI() end))
    trackConnection(antiAfkBtn.MouseButton1Click:Connect(function() state.antiAfkEnabled = not state.antiAfkEnabled; updateUI() end))
    trackConnection(strictMoneyBtn.MouseButton1Click:Connect(function() state.strictMoney = not state.strictMoney; updateUI() end))
    trackConnection(sellIntervalBox.FocusLost:Connect(function() updateUI() end))
    for typeName, btn in pairs(typeButtons) do
        trackConnection(btn.MouseButton1Click:Connect(function()
            COLLECT_TYPES[typeName] = not COLLECT_TYPES[typeName]; updateUI()
        end))
    end

    trackConnection(resetKeyBtn.MouseButton1Click:Connect(function()
        if HAS_FILE_API then
            pcall(function() if isfile(KEY_FILE) then delfile(KEY_FILE) end end)
        end
        memoryKey = nil
        setSettingsStatus("🔑 Key reset — rejoin to enter new key", Color3.fromRGB(220, 180, 100))
    end))

    saveConfig = function()
        local data = {
            selectedItems = state.selectedItems,
            collecting = state.collecting, selling = state.selling, buying = state.buying,
            antiAfkEnabled = state.antiAfkEnabled, strictMoney = state.strictMoney,
            collectTypes = COLLECT_TYPES,
            conquerTypes = conquerTypes,
            armyIndex = tonumber(armyBox.Text) or 1,
            sellInterval = tonumber(sellIntervalBox.Text) or 5,
        }
        local serialized = serializeTable(data)
        if HAS_FILE_API then
            local ok = pcall(function() writefile(CONFIG_FILE, serialized) end)
            if ok then return true, "Saved" end
        end
        memoryConfig = serialized
        return true, "Saved to memory"
    end

    loadConfig = function()
        local serialized
        if HAS_FILE_API then
            local ok, contents = pcall(function()
                if isfile(CONFIG_FILE) then return readfile(CONFIG_FILE) end
            end)
            if ok and contents then serialized = contents end
        end
        if not serialized and memoryConfig then serialized = memoryConfig end
        if not serialized then return false, "No saved config" end
        local data = deserializeTable(serialized)
        if not data then return false, "Corrupt config" end
        if data.selectedItems then state.selectedItems = data.selectedItems end
        if data.collecting ~= nil then state.collecting = data.collecting end
        if data.selling ~= nil then state.selling = data.selling end
        if data.buying ~= nil then state.buying = data.buying end
        if data.antiAfkEnabled ~= nil then state.antiAfkEnabled = data.antiAfkEnabled end
        if data.strictMoney ~= nil then state.strictMoney = data.strictMoney end
        if data.collectTypes then for k, v in pairs(data.collectTypes) do COLLECT_TYPES[k] = v end end
        if data.conquerTypes then
            for k, v in pairs(data.conquerTypes) do
                conquerTypes[k] = v
                if typeToggleButtons[k] then
                    if v then
                        typeToggleButtons[k].Text = BASE_TYPE_DISPLAY[k] .. ": ON"
                        typeToggleButtons[k].BackgroundColor3 = Color3.fromRGB(40, 130, 70)
                    else
                        typeToggleButtons[k].Text = BASE_TYPE_DISPLAY[k] .. ": OFF"
                        typeToggleButtons[k].BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                    end
                end
            end
        end
        if data.armyIndex then armyBox.Text = tostring(data.armyIndex) end
        if data.sellInterval then sellIntervalBox.Text = tostring(data.sellInterval) end
        return true, "Loaded"
    end

    trackConnection(saveCfgBtn.MouseButton1Click:Connect(function()
        local ok, msg = saveConfig()
        setSettingsStatus(ok and ("✅ " .. msg) or ("❌ " .. tostring(msg)),
            ok and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(220, 120, 120))
    end))

    trackConnection(loadCfgBtn.MouseButton1Click:Connect(function()
        local ok, msg = loadConfig()
        if ok then
            setSettingsStatus("✅ " .. msg, Color3.fromRGB(120, 220, 120))
            updateUI(); renderShopItems()
        else
            setSettingsStatus("⚠ " .. tostring(msg), Color3.fromRGB(220, 180, 100))
        end
    end))

    trackConnection(delCfgBtn.MouseButton1Click:Connect(function()
        if HAS_FILE_API then
            pcall(function() if isfile(CONFIG_FILE) then delfile(CONFIG_FILE) end end)
        end
        memoryConfig = nil
        setSettingsStatus("🗑 Config deleted", Color3.fromRGB(180, 180, 190))
    end))

    local watchedFolder, folderConnA, folderConnB
    local function watchFolder()
        if folderConnA then pcall(function() folderConnA:Disconnect() end) end
        if folderConnB then pcall(function() folderConnB:Disconnect() end) end
        watchedFolder = state.myBuildingsFolder
        if watchedFolder then
            folderConnA = watchedFolder.ChildAdded:Connect(refreshList)
            folderConnB = watchedFolder.ChildRemoved:Connect(refreshList)
            table.insert(state.connections, folderConnA)
            table.insert(state.connections, folderConnB)
        end
        refreshList()
    end

    watchFolder()
    updateUI()
    renderShopItems()

    task.spawn(function()
        task.wait(1)
        local ok, msg = loadConfig()
        if ok then
            updateUI(); renderShopItems()
            setSettingsStatus("✅ Auto-loaded: " .. msg, Color3.fromRGB(120, 220, 120))
        end
    end)

    table.insert(state.threads, task.spawn(function()
        while not state.unloaded do
            task.wait(0.5)
            if watchedFolder ~= state.myBuildingsFolder then watchFolder() end
            local count = state.myBuildingsFolder and #state.myBuildingsFolder:GetChildren() or 0
            collectStats.Text = string.format("Buildings: %d\nCollect fires: %d\nAnti-AFK saves: %d",
                count, state.collectFires, state.antiAfkSaves)
            sellStats.Text = "Sell fires: " .. state.sellFires
            moneyLabel.Text = "Money: $" .. formatMoney(getMyMoney()) .. "   |   Skips: " .. state.buySkips
            if state.myBuildingsFolder then
                collectStatus.Text = "✅ Plot " .. CONFIG.MY_PLOT .. " ready"
                collectStatus.TextColor3 = Color3.fromRGB(120, 200, 120)
            else
                collectStatus.Text = "⚠ Plot " .. CONFIG.MY_PLOT .. " not found"
                collectStatus.TextColor3 = Color3.fromRGB(220, 180, 100)
            end
        end
    end))

    print("[AutoInteract] Public script loaded. Plot: " .. CONFIG.MY_PLOT)
end

-- ============================================================
-- KEY GATE
-- ============================================================
local function attemptValidation(key)
    setKeyStatus("⏳ Verifying (HWID binding)...", Color3.fromRGB(220, 200, 120))
    verifyBtn.Text = "Verifying..."
    verifyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)

    task.spawn(function()
        local success, err
        for attempt = 1, 3 do
            success, err = validateKey(key)
            if success ~= nil then break end
            if attempt < 3 then
                setKeyStatus("⏳ Server sleeping, retry " .. attempt .. "/3...", Color3.fromRGB(220, 200, 120))
                task.wait(5)
            end
        end

        if success == true then
            setKeyStatus("✅ Valid! 🔒 Bound to this PC. Loading...", Color3.fromRGB(120, 220, 120))
            VERIFIED_KEY = key
            saveVerifiedKey(key)
            task.wait(0.5)
            startMainScript()
        elseif success == false then
            setKeyStatus("❌ " .. tostring(err), Color3.fromRGB(220, 120, 120))
            verifyBtn.Text = "Verify Key"
            verifyBtn.BackgroundColor3 = Color3.fromRGB(40, 130, 70)
        else
            setKeyStatus("❌ " .. tostring(err), Color3.fromRGB(220, 120, 120))
            verifyBtn.Text = "Verify Key"
            verifyBtn.BackgroundColor3 = Color3.fromRGB(40, 130, 70)
        end
    end)
end

verifyBtn.MouseButton1Click:Connect(function()
    local entered = keyInput.Text:gsub("%s+", "")
    if entered == "" then
        setKeyStatus("⚠ Enter a key first", Color3.fromRGB(220, 180, 100))
        return
    end
    attemptValidation(entered)
end)

keyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local entered = keyInput.Text:gsub("%s+", "")
        if entered ~= "" then attemptValidation(entered) end
    end
end)

task.spawn(function()
    task.wait(0.5)
    local savedKey = loadVerifiedKey()
    if savedKey and savedKey ~= "" then
        keyInput.Text = savedKey
        setKeyStatus("🔍 Auto-verifying saved key...", Color3.fromRGB(180, 180, 190))
        attemptValidation(savedKey)
    else
        setKeyStatus("Enter a key to begin.", Color3.fromRGB(180, 180, 190))
    end
end)

print("[AutoInteract] Public version loaded. HWID: " .. MY_HWID:sub(1, 16) .. "...")
