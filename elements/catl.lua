do
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
end