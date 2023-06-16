do
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
		
		sim.partCreate(-1, x + math.random(3) - 2, y + math.random(3) - 2, eflm)
		
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
end