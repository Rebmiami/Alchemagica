do
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
end