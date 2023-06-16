-- For debugging
-- Thanks LBPHacker
-- do
--   local env = getfenv(1)
--   setfenv(1, setmetatable({}, { __index = function(_, k)
--     if env[k] ~= nil then
--       return env[k]
--     end
--     error("__index on env with " .. tostring(k), 2)
--   end, __newindex = function(_, k)
--     error("__newindex on env with " .. tostring(k), 2)
--   end }))
-- end

-- Check if the current snapshot supports tmp3/tmp4
-- Otherwise, use pavg0/1
local tmp3 = "pavg0"
local tmp4 = "pavg1"
if sim.FIELD_TMP3 then -- Returns nil if tmp3 is not part of the current snapshot
	tmp3 = "tmp3"
	tmp4 = "tmp4"
end

-- Utility functions

local function clamp(val, low, high)
	if val > high then
		return high
	elseif val < low then
		return low
	end
	return val
end

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function hsvToRgb(h, s, v)
	h = h % 360
	local c = v * s
	local x = c * (1 - math.abs((h / 60) % 2 - 1))
	local m = v - c
	local rgbTable = {
		{c, x, 0},
		{x, c, 0},
		{0, c, x},
		{0, x, c},
		{x, 0, c},
		{c, 0, x},
	}
	local rgb = rgbTable[clamp(math.floor(h / 60) + 1, 1, 6)]
	local r, g, b = (rgb[1] + m) * 255, (rgb[2] + m) * 255, (rgb[3] + m) * 255
	return r, g, b
end


local shields = {elements.DEFAULT_PT_SHLD1, elements.DEFAULT_PT_SHLD2, elements.DEFAULT_PT_SHLD3, elements.DEFAULT_PT_SHLD4}

local unbrewable = {mana, catl}

local transmutationTable = {
    [elements.DEFAULT_PT_GLAS] = function(i) return sim.partProperty(i, "type") == elements.DEFAULT_PT_GOO end,
    [elements.DEFAULT_PT_SAND] = function(i) return has_value(shields, sim.partProperty(i, "type")) end,
    [elements.DEFAULT_PT_GEL] = function(i) return sim.partProperty(i, "type") == elements.DEFAULT_PT_SPNG end,
    [elements.DEFAULT_PT_WATR] = function(i) return sim.partProperty(i, "type") == elements.DEFAULT_PT_SAWD end,
    [elements.DEFAULT_PT_FIRW] = function(i) return sim.partProperty(i, "type") == elements.DEFAULT_PT_CLST end,
}

-- Returns the CTYPE of the element to transmute to
local function isTransmutable(i)
	for a,b in pairs(transmutationTable) do
		if b(i) then 
			return a
		end
	end
	return -1
end

local alchTransmutationTable = {
    [elements.DEFAULT_PT_OIL] = function(i) return sim.partProperty(i, "type") == elements.DEFAULT_PT_BCOL or sim.partProperty(i, "type") == elements.DEFAULT_PT_COAL end,
    [elements.DEFAULT_PT_GLOW] = function(i) return sim.partProperty(i, "type") == elements.DEFAULT_PT_SLCN end,
    [elements.DEFAULT_PT_MERC] = function(i) return IsMetal(i) end
}
-- Returns the TYPE of the element to transmute to
local function isAlchTransmutable(i)
	for a,b in pairs(alchTransmutationTable) do
		if b(i) then 
			return a
		end
	end
	return -1
end
