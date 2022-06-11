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

-- Elements
local alch = elements.allocate("alchmag", "ALCH")
local eflm = elements.allocate("alchmag", "EFLM")
local catl = elements.allocate("alchmag", "CATL")
local cond = elements.allocate("alchmag", "COND")
local mana = elements.allocate("alchmag", "MANA")
local brew = elements.allocate("alchmag", "BREW")
local scnv = elements.allocate("alchmag", "SCNV")

-- Alchemical powder
elements.element(alch, elements.element(elements.DEFAULT_PT_DUST))
elements.property(alch, 'Name', 'ALCH')
elements.property(alch, 'Description', 'Alchemical powder. Reacts with metals and some powders. Flammable.')
elements.property(alch, 'Color', 0xFFFE5C)
elements.property(alch, 'MenuSection', elem.SC_POWDERS)
elements.property(alch, 'Flammable', 5)
elements.property(alch, 'Advection', 0.8)
elements.property(alch, 'Weight', 65)
elements.property(alch, 'Diffusion', 0.25)
elements.property(alch, "HotAir", -0.000002)

elements.property(alch, "Update", function(i, x, y, s, n)
--Update Function
	
	
	if sim.partProperty(i, "tmp") == 0 then
	
		local r = sim.partID(x + math.random(3) - 2, y + math.random(3) - 2)
		-- for r in sim.neighbors(x, y, 1, 1) do
		if r ~= nil then
			if sim.partProperty(r, "type") == elements.DEFAULT_PT_FIRE then
				sim.partProperty(r, "type", eflm)
			end
			
			if sim.partProperty(r, "type") == eflm then
				sim.partProperty(i, "tmp", 1)
				sim.partProperty(i, "life", 240)
				-- break
			end
			
			if math.random(3) == 1 then 
				local t = isAlchTransmutable(r)
				if t ~= -1 then
					local px, py = sim.partPosition(r)
					sim.partKill(r)
					sim.partCreate(-1, px, py, t)
				end
			end
		end
	else
		sim.partProperty(i, "life", sim.partProperty(i, "life") - 1);
		sim.partCreate(-1, x + math.random(2) - 1, y + math.random(2) - 1, eflm)
		if sim.partProperty(i, "life") == 0 then
			sim.partKill(i)
		end
	end
	
end)
elements.property(alch, "Graphics", function(i, r, g, b)

	local style = ren.FIRE_ADD + ren.PMODE_FLAT
	-- Only sparkle if the particle is lonely
	if tpt.get_property("life", i) < 2 then 
		style = style + ren.PMODE_FLARE
	end
	
	return 0, style, 255, r, g, b, 25, r, g, b
end)


-- Magic flame
elements.element(eflm, elements.element(elements.DEFAULT_PT_FIRE))
elements.property(eflm, "Name", "EFLM")
elements.property(eflm, "Description", "Magical flame. Created by certain reactions or by burning ALCH. Reacts with many different elements.")
elements.property(eflm, "Colour", 0x10FF30)
elements.property(eflm, "MenuSection", elem.SC_EXPLOSIVE)
elements.property(eflm, "Properties", elem.TYPE_GAS + elem.PROP_LIFE_DEC + elem.PROP_LIFE_KILL)

elements.property(eflm, "Create", function(i, x, y, t, v)

	sim.partProperty(i, "life", math.random(120, 169));
end
)

elements.property(eflm, "Update", function(i, x, y, s, n)
	
	if math.random(10) == 1 then
		for r in sim.neighbors(x, y, 1, 1) do
			local t = isTransmutable(r)
			if t ~= -1 then
				sim.partProperty(r, "type", scnv)
				sim.partProperty(r, "life", 4)
				sim.partProperty(r, "ctype", t)
			end
		end
	end
end
)

elements.property(eflm, "Graphics", function(i, r, g, b)

	local position = sim.partProperty(i, "life") / 200;

	local colr = r;
	local colg = g * position;
	local colb = b;
	
	local firea = position * 255;
	local firer = colr;
	local fireg = colg;
	local fireb = colb;

	local pixel_mode = ren.PMODE_NONE;
	pixel_mode = ren.FIRE_ADD + ren.PMODE_NONE;
	if sim.partProperty(i, "life") % 60 > 54 then
		pixel_mode = ren.PMODE_FLARE + ren.PMODE_FLAT;
	end
	
	return 0,pixel_mode,255,colr,colg,colb,firea,firer,fireg,fireb;
end
)




-- For the purposes of this mod, metals are defined as materials that conduct electricity, are solid, and melt into lava.
function IsMetal(i)
	local melt = elements.property(sim.partProperty(i, "type"), "HighTemperatureTransition") == elem.DEFAULT_PT_LAVA;
	local conduct = bit.band(elements.property(sim.partProperty(i, "type"), "Properties"), elements.PROP_CONDUCTS) ~= 0;
	local solid = elements.property(sim.partProperty(i, "type"), "Loss") == 0
	
	return melt and conduct and solid;
end

function ConvertToConduit(i)
	sim.partProperty(i, "type", cond)
	sim.partProperty(i, "life", 30)
	sim.partProperty(i, "tmp", 0)
end

-- Catalyst
elements.element(catl, elements.element(elements.DEFAULT_PT_DUST))
elements.property(catl, "Name", "CATL")
elements.property(catl, "Description", "Catalyst. Last step in most alchemical reactions. Use in small amounts.")
elements.property(catl, "Colour", 0xFF6020)
elements.property(catl, "MenuSection", elem.SC_SPECIAL)

elements.property(catl, "Update", function(i, x, y, s, n)
	
	local consume = false;
	for r in sim.neighbors(x, y, 1, 1) do
		-- Attempt to prime the catalyst. An already-primed catalyst cannot be primed to a different ctype and ctypes will spread to unprimed catalysts
		if (sim.partProperty(i, "ctype") == 0) then
		
			if sim.partProperty(r, "type") == mana then
				sim.partProperty(i, "ctype", mana)
				break
			end
			
			if sim.partProperty(r, "type") == catl and sim.partProperty(r, "ctype") ~= 0 then
				sim.partProperty(i, "ctype", sim.partProperty(r, "ctype"))
				break
			end
		
		end
		
		if sim.partProperty(i, "ctype") == mana then
			if IsMetal(r) or sim.partProperty(r, "type") == cond then
				for s in sim.neighbors(x, y, 3, 3) do
					if sim.partProperty(s, "type") == cond then
						sim.partProperty(s, "life", 30);
						consume = true
					elseif IsMetal(s) then
						ConvertToConduit(s)
						consume = true
					end
					
				end
				break
			end
		end
		
		if sim.partProperty(r, "type") == brew then
			for s in sim.neighbors(x, y, 3, 3) do
				if sim.partProperty(s, "type") == brew then
					sim.partProperty(s, "life", 4);
					consume = true
				end
			end
			break
		end
	end
	
	if consume then
		sim.partKill(i)
	end
end
)

elements.property(catl, "Graphics", function(i, r, g, b)

	local colr = r;
	local colg = g;
	local colb = b;
	
	local firea = 10;

	local pixel_mode = ren.PMODE_FLAT;
	if sim.partProperty(i, "ctype") == mana then
		pixel_mode = ren.PMODE_FLARE + ren.PMODE_FLAT;
		colr = 255;
		colg = 255;
		colb = 255;
		
		local firea = 255;
		
	end
	local firer = colr;
	local fireg = colg;
	local fireb = colb;
	
	return 0,pixel_mode,255,colr,colg,colb,firea,firer,fireg,fireb;
end)


-- Conduit
elements.element(cond, elements.element(elements.DEFAULT_PT_METL))
elements.property(cond, "Name", "COND")
elements.property(cond, "Description", "Conduit metal. Charged by MANA and EFLM. Assists many reactions but loses stability when overcharged.")
elements.property(cond, "Colour", 0x5566AA)
elements.property(cond, "MenuSection", elem.SC_SOLIDS)
elements.property(cond, "Properties", elem.TYPE_SOLID + elem.PROP_LIFE_DEC + elem.PROP_HOT_GLOW)
elements.property(cond, "HighTemperatureTransition", -1)
elements.property(cond, "Create", function(i, x, y, t, v)

	sim.partProperty(i, "life", 30);
end
)
elements.property(cond, "Update", function(i, x, y, s, n)
	
	local conversionCost = 1
	local brewCost = 5
	local tmpPerMana = 10
	
	if (sim.partProperty(i, "tmp2") > 0) then
		-- Overloaded behavior
		
		sim.partCreate(-1, x + math.random(2) - 1, y + math.random(2) - 1, eflm)
		
		sim.partProperty(i, "tmp", sim.partProperty(i, "tmp") - 1)
		
		if sim.partProperty(i, "tmp") <= 0 then
			simulation.pressure(x / 4, y / 4, 10)
			sim.partKill(i)
			-- In a future version, this should also spawn RESD
			local boomMana = sim.partCreate(-1, x, y, mana)
			if boomMana ~= -1 then sim.partProperty(boomMana, "temp", 10000) end
			
			for r in sim.neighbors(x, y, 1, 1) do
				if sim.partProperty(r, "type") == cond then
					sim.partProperty(r, "tmp2", 1)
				end
			end
		end
	else
		-- Normal behavior
		
		local npart = sim.neighbors(x, y, 1, 1)
		
		local randomCondNeighbor = sim.partID(x + math.random(5) - 3, y + math.random(5) - 3)
		
		if randomCondNeighbor ~= nil and sim.partProperty(randomCondNeighbor, "type") == cond then
		
			local totalNeighborMagic = 0
			local condNeighbors = 0
			
			local condArray = {}
			
			totalNeighborMagic = sim.partProperty(i, "tmp") + sim.partProperty(randomCondNeighbor, "tmp");
			condNeighbors = 2;
			table.insert(condArray, randomCondNeighbor)
			table.insert(condArray, i)
			
			
			-- Add a "high CPU" mode that makes COND distribute magic faster?
			
			-- Absorb MANA and EFLM and convert metals to more COND
			-- for r in npart do
			-- 	local neighborType = sim.partProperty(r, "type")
			-- 
			-- 	
			-- 	
			-- 	if neighborType == cond then
			-- 		totalNeighborMagic = totalNeighborMagic + sim.partProperty(r, "tmp");
			-- 		condNeighbors = condNeighbors + 1;
			-- 		table.insert(condArray, r)
			-- 	end
			-- end
			
			
			-- Distribute magic among neighbors evenly
			
			local flooredAverageMagic = math.floor(totalNeighborMagic / condNeighbors)
			for g,v in pairs(condArray) do
				sim.partProperty(v, "tmp", flooredAverageMagic)
			end
			for j = (totalNeighborMagic % (condNeighbors)), 1, -1 do
				local b = condArray[math.random(#condArray)]
				sim.partProperty(b, "tmp", sim.partProperty(b, "tmp") + 1)
				
				if sim.partProperty(b, "tmp2") > 0 then
					sim.partProperty(i, "tmp2", sim.partProperty(i, "tmp"))
				end
			end
		end
		
		local randomNeighbor = sim.partID(x + math.random(3) - 2, y + math.random(3) - 2)
		
		
		if randomNeighbor ~= nil then
			local neighborType = sim.partProperty(randomNeighbor, "type")
			-- If life is low, make certain interactions less likely.
			if sim.partProperty(i, "life") > 0 or 0.40 > math.random() then
				if neighborType == mana then
					sim.partProperty(i, "tmp", sim.partProperty(i, "tmp") + tmpPerMana)
					sim.partKill(randomNeighbor)
				elseif IsMetal(randomNeighbor) and sim.partProperty(i, "tmp") >= conversionCost then
					ConvertToConduit(randomNeighbor)
					sim.partProperty(i, "tmp", sim.partProperty(i, "tmp") - conversionCost)
				end
			elseif neighborType == eflm then
				sim.partProperty(i, "tmp", sim.partProperty(i, "tmp") + 1)
				sim.partKill(r)
			-- Convert certain elements to BREW
			elseif isBrewable(randomNeighbor) and sim.partProperty(i, "tmp") >= brewCost then
				sim.partProperty(randomNeighbor, "ctype", sim.partProperty(randomNeighbor, "type"))
				sim.partProperty(randomNeighbor, "type", brew)
				sim.partProperty(randomNeighbor, "life", 0)
				sim.partProperty(randomNeighbor, "tmp", 0)
				sim.partProperty(randomNeighbor, "tmp2", 0)
				
				sim.partProperty(i, "tmp", sim.partProperty(i, "tmp") - brewCost)
			end
		end
		
		
		
		-- Overload logic
		local threshold = 200
		
		local overheat = math.max (sim.partProperty(i, "temp") - 273, 0)
		if overheat > 0 then
			threshold = threshold - overheat / 5
		end
		
		local chill = math.max(253 - sim.partProperty(i, "temp"), 0)
		if chill > 0 then
			threshold = threshold + chill
		end
		
		if sim.partProperty(i, "tmp") > threshold and sim.partProperty(i, "tmp") > tmpPerMana then
			if chill > 0 or sim.partProperty(i, "tmp") < 30 then
				local dropMana = sim.partCreate(-1, x + math.random(2) - 1, y + math.random(2) - 1, mana)
				if dropMana ~= -1 then
					sim.partProperty(i, "tmp", sim.partProperty(i, "tmp") - tmpPerMana)
					sim.partProperty(dropMana, "temp", sim.partProperty(i, "temp"))
				end
			else
				sim.partProperty(i, "tmp2", sim.partProperty(i, "tmp"))
			end
		end
	end
	
end
)
elements.property(cond, "Graphics", function(i, r, g, b)
	
	local flash = sim.partProperty(i, "life") / 30
	local colr = r + flash * 255;
	local colg = g + flash * 255;
	local colb = b + flash * 255;
	
	colr = colr + sim.partProperty(i, "tmp") * 0.2
	colg = colg + sim.partProperty(i, "tmp") * 0.5
	colb = colb + sim.partProperty(i, "tmp") * 1.2
	
	local firer = r;
	local fireg = g;
	local fireb = b;
	
	
	local firea = math.min(sim.partProperty(i, "tmp"), 50);

	local pixel_mode = ren.PMODE_FLAT + ren.FIRE_ADD
	
	if (sim.partProperty(i, "life") > 15) then
	
		pixel_mode = ren.PMODE_FLAT + ren.PMODE_FLARE
	end
	
	if (sim.partProperty(i, "tmp") > 50 + math.random(50)) then
		pixel_mode = ren.PMODE_FLAT + ren.PMODE_FLARE + ren.FIRE_ADD
	end
	
	if sim.partProperty(i, "tmp2") ~= 0 then
		pixel_mode = ren.PMODE_FLAT + ren.PMODE_LFLARE + ren.FIRE_ADD
		colr = 40
		colg = 220
		colb = 200 - sim.partProperty(i, "tmp")
	end
	
	
	if (sim.partProperty(i, "tmp") > 50 + math.random(100)) then
		local c = math.random()
		local frequency = 3.14 * 2;
		firer = math.sin(frequency * (c + 0)) * 127 + 150;
		fireg = math.sin(frequency * (c + 0.33)) * 127 + 150;
		fireb = math.sin(frequency * (c + 0.67)) * 127 + 150;
	end
	
	return 0,pixel_mode,255,colr,colg,colb,firea,firer,fireg,fireb;
end)

-- Mana
elements.element(mana, elements.element(elements.DEFAULT_PT_DSTW))
elements.property(mana, "Name", "MANA")
elements.property(mana, "Description", "Liquid magical essence. Behaves strangely at extreme temperatures. Absorbed into COND.")
elements.property(mana, "Colour", 0x0010DD)
elements.property(mana, "MenuSection", elem.SC_SPECIAL)
elements.property(mana, "HighTemperatureTransition", -1)
elements.property(mana, "LowTemperatureTransition", -1)

elements.property(mana, "Update", function(i, x, y, s, n)

	-- Heating up MANA will cause it to agitate and move more erratically 
	local agitation = 0.01 + math.max((sim.partProperty(i, "temp") - 293) * 0.001, 0)
	
	if (math.random() < agitation) then
		sim.partProperty(i, "vx", (math.random() - 0.5) + sim.partProperty(i, "vx"))
		sim.partProperty(i, "vy", (math.random() - 0.5) * 2 + sim.partProperty(i, "vy"))
	end
	
	local coalesce = 1 - math.min(sim.partProperty(i, "temp"), 200) / 200
	
	sim.gravMap(x / 4, y / 4, 1, 1, coalesce)
end
)


local manaVisual = 0;
elements.property(mana, "Graphics", function(i, r, g, b)
	
	local px, py = sim.partPosition(i)
	
	local totalVel = math.sqrt( sim.partProperty(i, "vx") ^ 2 + sim.partProperty(i, "vy") ^ 2)
	
	local freeze = 0
	local heat = math.min(math.max((sim.partProperty(i, "temp") - 393), 0), 900) / 900
	
	local flash = (math.sin((px + py) * 0.04 + manaVisual * 0.02 + math.sin(py * 0.12 + manaVisual * 0.01) * 0.7) + 1) * 0.07 + totalVel * 0.5
	
	local colr = r + (200 * heat) + flash * 255;
	local colg = g + (10 * heat) + flash * 255;
	local colb = b * (1 - heat) + flash * 255;
	
	local firea = 20 + totalVel * 10 + heat * 100;

	local pixel_mode = ren.PMODE_FLAT + ren.PMODE_SPARK + ren.PMODE_BLUR
	
	if (totalVel > 0.1) then
		pixel_mode = pixel_mode + ren.PMODE_FLARE
	end
	
	if (heat > 0.2) then
		pixel_mode = pixel_mode + ren.FIRE_ADD
	end
	
	local firer = colr;
	local fireg = colg;
	local fireb = colb;
	
	return 0,pixel_mode,255,colr,colg,colb,firea,firer,fireg,fireb;
end)

event.register(event.tick, function() manaVisual = manaVisual + 1 end) 



-- Brew (liquid)
elements.element(brew, elements.element(elements.DEFAULT_PT_DSTW))
elements.property(brew, "Name", "BREW")
elements.property(brew, "Description", "Hidden element. Handles alchemical recipes.")
elements.property(brew, "Colour", 0x000000)
elements.property(brew, "MenuSection", -1)
elements.property(brew, "HighTemperatureTransition", -1)
elements.property(brew, "LowTemperatureTransition", -1)
elements.property(brew, "Weight", 1)
-- elements.property(brew, "Properties", elem.PROP_LIFE_DEC)
elements.property(brew, "Update", function(i, x, y, s, n)
	
	local ctype = sim.partProperty(i, "ctype")
	local randomNeighbor = sim.partID(x + math.random(3) - 2, y + math.random(3) - 2)
	
	-- unbrewable
	
	-- TODO: Improve system for determining if an element can be dissolved
	
	if math.random() > 0.9 and randomNeighbor ~= nil and randomNeighbor ~= i and sim.partProperty(randomNeighbor, "type") ~= brew and ctype ~= sim.partProperty(randomNeighbor, "type") and brewTransitionTable[ctype] ~= sim.partProperty(randomNeighbor, "type") then
	-- elements.property(sim.partProperty(randomNeighbor, "type"), "MenuSection") ~= elem.SC_SPECIAL
		local canBrew = brewValidityTable[ctype](randomNeighbor)
		if canBrew ~= nil then
			if canBrew and sim.partProperty(i, "tmp") < 20 then
				sim.partProperty(i, "tmp", sim.partProperty(i, "tmp") + 8)
				sim.partKill(randomNeighbor)
			elseif sim.partProperty(i, "tmp2") < 20 and bit.band(elements.property(sim.partProperty(randomNeighbor, "type"), "Properties"), elements.TYPE_SOLID) == 0 and not has_value(unbrewable, sim.partProperty(randomNeighbor, "type")) then
				if not canBrew or math.random() > 0.8 then
					sim.partProperty(i, "tmp2", sim.partProperty(i, "tmp2") + 5)
					sim.partKill(randomNeighbor)
				end
			end
			
		end
		
		-- if sim.partProperty(randomNeighbor, "type") == brew then
		-- 
		-- end
	end
	
	local randomNeighbor = sim.partID(x + math.random(3) - 2, y + math.random(3) - 2)
	if randomNeighbor ~= nil and sim.partProperty(randomNeighbor, "type") == brew and sim.partProperty(randomNeighbor, "ctype") == sim.partProperty(i, "ctype") then
		if sim.partProperty(i, "tmp") > sim.partProperty(randomNeighbor, "tmp") then
			sim.partProperty(i, "tmp", sim.partProperty(i, "tmp") - 1)
			sim.partProperty(randomNeighbor, "tmp", sim.partProperty(randomNeighbor, "tmp") + 1)
		elseif sim.partProperty(i, "tmp") < sim.partProperty(randomNeighbor, "tmp") then
			sim.partProperty(i, "tmp", sim.partProperty(i, "tmp") + 1)
			sim.partProperty(randomNeighbor, "tmp", sim.partProperty(randomNeighbor, "tmp") - 1)
		end
		
		if sim.partProperty(i, "tmp2") > sim.partProperty(randomNeighbor, "tmp2") then
			sim.partProperty(i, "tmp2", sim.partProperty(i, "tmp2") - 1)
			sim.partProperty(randomNeighbor, "tmp2", sim.partProperty(randomNeighbor, "tmp2") + 1)
		elseif sim.partProperty(i, "tmp2") < sim.partProperty(randomNeighbor, "tmp2") then
			sim.partProperty(i, "tmp2", sim.partProperty(i, "tmp2") + 1)
			sim.partProperty(randomNeighbor, "tmp2", sim.partProperty(randomNeighbor, "tmp2") - 1)
		end
	end
	
	-- if brewConditionTable[ctype](i) or (randomNeighbor ~= nil and sim.partProperty(randomNeighbor, "type") == brew and sim.partProperty(randomNeighbor, "ctype") == brewTransitionTable[ctype]) then
	-- 	sim.partProperty(i, "ctype", brewTransitionTable[ctype])
	-- 	sim.partProperty(i, "tmp2", sim.partProperty(i, "tmp2") + (20 - sim.partProperty(i, "tmp")))
	-- 	sim.partProperty(i, "tmp", 0)
	-- end
	
	if sim.partProperty(i, "life") > 0 then
		for r in sim.neighbors(x, y, 2, 2) do
			if sim.partProperty(i, "life") < 4 and sim.partProperty(r, "life") == 0 and sim.partProperty(r, "type") == brew then
				sim.partProperty(r, "life", 4)
			end
		end
		
		sim.partProperty(i, "life", sim.partProperty(i, "life") - 1)
		
		if sim.partProperty(i, "life") == 0 then
			
			local progress = sim.partProperty(i, "tmp") / 20
			local impurity = sim.partProperty(i, "tmp2") / 20
			
			local successChance = progress * (1 - impurity)
			
			local isRandomFail = successChance < 0.8 and math.random() > successChance
			
			
			-- local px, py = sim.partPosition(i)
			local c = brewTransitionTable[ctype]
			
			if isRandomFail then
				c = elem.DEFAULT_PT_DUST -- TODO: Residue
				-- Maybe only create residue from TMP2 impurity instead of an incomplete brew?
			end
			
			sim.partKill(i)
			local b = sim.partCreate(-1, x, y, c)
			if b == -1 then
				-- print("Failed to create a part at " + x + "," + y)
				-- sim.partProperty(i, "life", 1)
			end
		end
	end
end
)

elements.property(brew, "Graphics", function(i, r, g, b)
	
	local flash = sim.partProperty(i, "life") / 4
	
	local progress = sim.partProperty(i, "tmp") / 20
	local impurity = sim.partProperty(i, "tmp2") / 20
	
	local successChance = progress * (1 - impurity)
	
	local ctype = sim.partProperty(i, "ctype")
	-- print(brewColorTable[ctype])
	
	local colr = (brewColorTable[ctype][1][1] * (1 - progress) + brewColorTable[ctype][2][1] * (progress)) * (1 - impurity) + brewColorTable[ctype][3][1] * impurity + flash * 255;
	local colg = (brewColorTable[ctype][1][2] * (1 - progress) + brewColorTable[ctype][2][2] * (progress)) * (1 - impurity) + brewColorTable[ctype][3][2] * impurity + flash * 255;
	local colb = (brewColorTable[ctype][1][3] * (1 - progress) + brewColorTable[ctype][2][3] * (progress)) * (1 - impurity) + brewColorTable[ctype][3][3] * impurity + flash * 255;
	
	local firea = 0;

	local pixel_mode = ren.PMODE_FLAT + ren.PMODE_BLUR
	
	if (sim.partProperty(i, "life") > 2) then
		pixel_mode = pixel_mode + ren.PMODE_FLARE + ren.FIRE_ADD
	elseif successChance >= 0.85 and math.random() > 0.99 then
		pixel_mode = pixel_mode + ren.PMODE_FLARE + ren.PMODE_SPARK + ren.FIRE_ADD
		colr = 255
		colg = 255
		colb = 255
		firea = 255
	end
	
	local firer = colr;
	local fireg = colg;
	local fireb = colb;
	
	return 0,pixel_mode,255,colr,colg,colb,firea,firer,fireg,fireb;
end)


-- Special converted
elements.property(scnv, "Name", "SCNV")
elements.property(scnv, "Description", "Hidden element. Handles simple element-to-element transmutation.")
elements.property(scnv, "Colour", 0x000000)
elements.property(scnv, "MenuSection", elem.SC_NONE)
elements.property(scnv, "Properties", elem.PROP_LIFE_DEC)

elements.property(scnv, "Update", function(i, x, y, s, n)
	
	for r in sim.neighbors(x, y, 2, 2) do
		if transmutationTable[sim.partProperty(i, "ctype")](r) and sim.partProperty(i, "life") < 4 and math.random(5) == 1 then
			sim.partProperty(r, "type", scnv)
			sim.partProperty(r, "life", 4)
			sim.partProperty(r, "ctype", sim.partProperty(i, "ctype"))
			
		end
	end
	
	if sim.partProperty(i, "life") == 0 then
		-- local px, py = sim.partPosition(i)
		-- sim.partProperty(i, "type", sim.partProperty(i, "ctype"))
		-- sim.partProperty(i, "ctype", 0)
		local c = sim.partProperty(i, "ctype")
		sim.partKill(i)
		sim.partCreate(-1, x, y, c)
	end
end
)

elements.property(scnv, "Graphics", function(i, r, g, b)
	
	
	
	local flash = sim.partProperty(i, "life") / 4
	local colr = r + flash * 255;
	local colg = g + flash * 255;
	local colb = b + flash * 255;
	
	local firea = 30;

	local pixel_mode = ren.PMODE_FLAT
	
	if (sim.partProperty(i, "life") > 2) then
	
		pixel_mode = ren.PMODE_FLAT + ren.PMODE_FLARE + ren.FIRE_ADD
	end
	
	local firer = colr;
	local fireg = colg;
	local fireb = colb;
	
	return 0,pixel_mode,255,colr,colg,colb,firea,firer,fireg,fireb;
end)