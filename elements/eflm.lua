do
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
end