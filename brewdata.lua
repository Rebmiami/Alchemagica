-- Interpolates between colors depending on TMP and TMP2
-- 1. Base state
-- 2. Pure state
-- 3. Impure state
local brewColorTable = {
    [elements.DEFAULT_PT_NITR] = {{32, 253, 127}, {68, 27, 253}, {57, 12, 4}},
    [elements.DEFAULT_PT_BRMT] = {{187, 18, 202}, {0, 253, 96}, {85, 16, 6}},
    [elements.DEFAULT_PT_EXOT] = {{75, 220, 253}, {64, 250, 32}, {15, 0, 90}},
}

-- If returns nil, particles is not absorbed.
-- If returns false, particle is absorbed as impurity.
-- If returns true, particle is absorbed as progress.
local brewValidityTable = {
    [elements.DEFAULT_PT_NITR] = function(i)
		if sim.partProperty(i, "type") == elements.DEFAULT_PT_FRZZ or sim.partProperty(i, "type") == elements.DEFAULT_PT_FRZW or ((sim.partProperty(i, "type") == elements.DEFAULT_PT_ICE or sim.partProperty(i, "type") == elements.DEFAULT_PT_SNOW) and sim.partProperty(i, "ctype") == elements.DEFAULT_PT_FRZW) then
			return true
		end
		
		-- TODO: Make incorrect powders and liquids add to impurity and ignore solids
		return false
	end,
    [elements.DEFAULT_PT_BRMT] = function(i)
		if sim.partProperty(i, "type") == elements.DEFAULT_PT_RBDM or sim.partProperty(i, "type") == elements.DEFAULT_PT_LRBD then
			return true
		end
		
		return false
	end,
    [elements.DEFAULT_PT_EXOT] = function(i)
		if sim.partProperty(i, "type") == elements.DEFAULT_PT_SALT then
			return true
		end
		
		return false
	end,
}

-- Returns the element that the current blend should convert into
local brewTransitionTable = {
    [elements.DEFAULT_PT_NITR] = elements.DEFAULT_PT_C5,
    [elements.DEFAULT_PT_BRMT] = elements.DEFAULT_PT_FUSE,
    [elements.DEFAULT_PT_EXOT] = elements.DEFAULT_PT_VIBR,
}

-- Returns true if the element can be converted into a brew by charged COND
local brewFormationTable = {
    [elements.DEFAULT_PT_NITR] = function(i) return true end,
    [elements.DEFAULT_PT_BRMT] = function(i) return true end,
    [elements.DEFAULT_PT_EXOT] = function(i) return true end,
}

-- Returns true if the element can be brewed
local function isBrewable(i)
	for a,b in pairs(brewFormationTable) do
		if sim.partProperty(i, "type") == a and b(i) then 
			return true
		end
	end
	return false
end