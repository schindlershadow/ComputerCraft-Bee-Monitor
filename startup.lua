-- envdisplay.lua
-- Uses Advanced Peripherals Environment Detector (right)
-- and a Monitor (bottom) to display: Day/Night, Raining, Thunder, Bee count (16 blocks)

local env = peripheral.wrap("right")
local mon = peripheral.wrap("bottom")

if not env then error("Environment Detector not found on the right.") end
if not mon then error("Monitor not found on the bottom.") end

-- Monitor setup
mon.setBackgroundColor(colors.blue)
mon.setTextColor(colors.white)
mon.setTextScale(1)

local function centerText(y, text, color)
    local w, _ = mon.getSize()
    local x = math.floor((w - #text) / 2) + 1
    mon.setCursorPos(x, y)
    if color then mon.setTextColor(color) else mon.setTextColor(colors.white) end
    mon.write(text)
end

-- Day/Night via ComputerCraft time (0..24)
local function isDaytime()
    local t = os.time()
    return t >= 6 and t < 18
end

-- Try hard to decide if an entity entry is a bee
local function isBeeEntity(e)
    -- Check common string fields for exact/namespace matches
    local fields = { e.name, e.displayName, e.type, e.entity, e.identifier }
    for _, v in ipairs(fields) do
        if type(v) == "string" then
            local s = string.lower(v)
            if s == "bee" or s == "minecraft:bee" or s:match("[:/%.]bee$") or s:match("^entity%.minecraft%.bee") then
                return true
            end
            -- Avoid false positives like "beetle"
            if s:find("bee", 1, true) and not s:find("beetle", 1, true) then
                -- If it's a loose match, only accept if it ends with "bee"
                if s:match("bee$") then return true end
            end
        end
    end
    -- Check tags if present
    if type(e.tags) == "table" then
        for _, t in ipairs(e.tags) do
            if type(t) == "string" then
                local s = string.lower(t)
                if s == "minecraft:bee" or s:match("[:/%.]bee$") then
                    return true
                end
            end
        end
    end
    return false
end

local function countBees(range)
    local ok, entities = pcall(env.scanEntities, range)
    if not ok or type(entities) ~= "table" then return 0 end
    local n = 0
    for _, e in ipairs(entities) do
        if type(e) == "table" and isBeeEntity(e) then
            n = n + 1
        end
    end
    return n
end

-- Count bees + track injured ones
local function scanBees(range)
    local ok, entities = pcall(env.scanEntities, range)
    if not ok or type(entities) ~= "table" then return 0, false end
    local n = 0
    local injured = false
    for _, e in ipairs(entities) do
        if type(e) == "table" and isBeeEntity(e) then
            n = n + 1
            if e.health and e.maxHealth and e.health < e.maxHealth/2 then
                injured = true
            end
        end
    end
    return n, injured
end

while true do
    

    local day = isDaytime()
    local raining = env.isRaining()
    local thundering = env.isThunder()  -- <-- corrected API
    local bees, injured = scanBees(16)
    mon.clear()

    if day then
        if raining then
            mon.setBackgroundColor(colors.red)
        else
            mon.setBackgroundColor(colors.blue)
        end
        else
            mon.setBackgroundColor(colors.black)
    end
    centerText(2, "Bee Environment Status", colors.yellow)
    centerText(4, "Time: " .. (day and "Day" or "Night"), day and colors.orange or colors.blue)
    centerText(6, "Raining: " .. (raining and "Yes" or "No"), raining and colors.lightBlue or colors.gray)
    centerText(8, "Thundering: " .. (thundering and "Yes" or "No"), thundering and colors.red or colors.green)
    if bees == 0 then
        centerText(10, ("No Bees nearby"), colors.red)
    else
        centerText(10, ("Bees nearby: %d"):format(bees), colors.yellow)
    end
    if injured then
        centerText(11, "⚠ Some bees are hurt! ⚠", colors.red)
    end

    sleep(2) -- refresh every 2 seconds
end
