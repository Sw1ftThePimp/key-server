local KEY  = (getgenv and getgenv().AdminKey) or "SWIFT"
local H    = game:GetService("HttpService")
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()

local R
for i = 1, 3 do
    local ok, r = pcall(function()
        return request({
            Url = "https://key-server-za8g.onrender.com/getscript",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = H:JSONEncode({ key = KEY, hwid = hwid }),
            Timeout = 60,
        })
    end)
    if ok and r and r.Body then
        R = r
        break
    end
    if i < 3 then
        warn("[Loader] Server sleeping, retry " .. i .. "/3...")
        task.wait(5)
    end
end

if not R then
    warn("[Loader] ❌ Could not reach server — try again in 30s")
    return
end

local D = H:JSONDecode(R.Body)
if not D.script then
    warn("[Loader] ❌ " .. tostring(D.error or "Unknown error"))
    return
end

loadstring(D.script:gsub("%x%x", function(x)
    return string.char(tonumber(x, 16))
end))()
