do
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
end