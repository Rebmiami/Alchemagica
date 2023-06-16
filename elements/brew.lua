do
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
end