-- ============================================================
-- Auto-Interact Loader
-- Requires a valid key. Fetches the main script from the server.
-- ============================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- ===== SET YOUR KEY HERE =====
local KEY = "PASTE-YOUR-KEY-HERE"

-- ===== SERVER URL =====
local SERVER_URL = "https://key-server-za8g.onrender.com"

-- ===== GET HWID =====
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

-- ===== VALIDATE KEY =====
if KEY == "" or KEY == "PASTE-YOUR-KEY-HERE" then
    warn("[Loader] ❌ No key set! Edit the KEY variable at the top of the script.")
    return
end

print("[Loader] Fetching script from server...")

-- Retry up to 3 times (handles Render cold starts)
local response = nil
for attempt = 1, 3 do
    local ok, res = pcall(function()
        return request({
            Url = SERVER_URL .. "/getscript",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                key = KEY,
                hwid = MY_HWID,
            }),
            Timeout = 60,
        })
    end)

    if ok and res and res.Body then
        response = res
        break
    end

    if attempt < 3 then
        print("[Loader] ⏳ Server sleeping, retry " .. attempt .. "/3...")
        task.wait(5)
    end
end

if not response then
    warn("[Loader] ❌ Could not reach server after 3 retries")
    return
end

local data
local decodeOk, decodeResult = pcall(function()
    return HttpService:JSONDecode(response.Body)
end)
if decodeOk then
    data = decodeResult
else
    warn("[Loader] ❌ Invalid server response")
    return
end

if not data or not data.script then
    warn("[Loader] ❌ " .. tostring((data and data.error) or "Unknown error"))
    return
end

print("[Loader] Decoding script...")

-- Hex decode
local decoded = {}
for i = 1, #data.script, 2 do
    local byte = tonumber(data.script:sub(i, i + 1), 16)
    if byte then
        table.insert(decoded, string.char(byte))
    end
end
local scriptText = table.concat(decoded)

print("[Loader] Executing (" .. #scriptText .. " chars)...")

local fn = loadstring(scriptText)
if not fn then
    warn("[Loader] ❌ Failed to compile script")
    return
end

fn()
