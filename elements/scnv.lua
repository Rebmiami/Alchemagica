do
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
end