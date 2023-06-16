do
-- Crazy Crystal (solid)
-- life: Time until exploding
-- tmp: Growth potential
-- tmp2: Hue
elements.element(crcy, elements.element(elements.DEFAULT_PT_QRTZ))
elements.property(crcy, 'Name', 'CRCY')
elements.property(crcy, 'Description', 'Crazy crystal. Grows self-propagating clusters that crystallize everything and take no prisoners.')
elements.property(crcy, 'Color', 0xFF49FF)
elements.property(crcy, 'MenuSection', elem.SC_SOLIDS)
elements.property(crcy, "HotAir", -0.005)

elements.property(crcy, "Create", function(i, x, y, t, v)
	sim.partProperty(i, "life", 100)
	sim.partProperty(i, "tmp", 10)
	sim.partProperty(i, "tmp2", math.random(360) - 1)
end)

local crazyImmune = {
	[elem.DEFAULT_PT_DMND] = true,
	[crcy] = true,
}

elements.property(crcy, "Update", function(i, x, y, s, n)

	-- Heat stunts the crystal's growth
	if sim.partProperty(i, "tmp") > 0 and sim.partProperty(i, "temp") < 2000 then
		local rx, ry = x + math.random(3) - 2, y + math.random(3) - 2
		local randomNeighbor = sim.partID(rx, ry)

		if randomNeighbor then
			if not crazyImmune[sim.partProperty(randomNeighbor, "type")] and math.random(10) == 1 then
				sim.partKill(randomNeighbor)
				randomNeighbor = nil
			end
		end

		if not randomNeighbor then
			local np = sim.partCreate(-1, rx, ry, crcy)
			if np >= 0 then
				sim.partProperty(np, "temp", sim.partProperty(i, "temp") + 1)
				sim.partProperty(np, "tmp", sim.partProperty(i, "tmp") - 1)
				sim.partProperty(np, "tmp2", sim.partProperty(i, "tmp2"))
				sim.partProperty(i, "tmp", sim.partProperty(i, "tmp") - 1)
				sim.partProperty(np, tmp3, sim.partProperty(i, tmp3) + 1)

				if math.random(2) == 1 then
					sim.partProperty(i, "tmp", 0)
				end
			end
		else
		end
	end

	if sim.partProperty(i, "life") == 0 then
		simulation.pressure(x / 4, y / 4, 10)
		local temp = sim.partProperty(i, "temp") + 20
		local tmp2 = sim.partProperty(i, "tmp2")
		sim.partKill(i)
		local np = sim.partCreate(-1, x, y, crpd)
		sim.partProperty(np, "temp", temp)
		sim.partProperty(np, "tmp2", tmp2)
	end
end)
elements.property(crcy, "Graphics", function(i, r, g, b)

	local firea = 15
	local style = ren.FIRE_ADD + ren.PMODE_FLAT
	if sim.partProperty(i, "life") < 10 then 
		style = style + ren.PMODE_FLARE
		firea = firea + (10 - sim.partProperty(i, "life")) * 10
	end

	local colr, colg, colb = hsvToRgb(sim.partProperty(i, "tmp2"), sim.partProperty(i, tmp3) / 10, 1)
	
	return 0, style, 255, colr, colg, colb, firea, colr, colg, colb
end)

elements.element(crpd, elements.element(elements.DEFAULT_PT_DUST))
elements.property(crpd, 'Name', 'CRPD')
elements.property(crpd, 'Description', 'Crazy crystal powder.')
elements.property(crpd, 'Color', 0xFFFE5C)
elements.property(crpd, 'MenuSection', -1)
elements.property(crpd, "HotAir", 0.02)
elements.property(crpd, 'Flammable', 0)
elements.property(crpd, "Properties", elem.PROP_LIFE_DEC)

elements.property(crpd, "Create", function(i, x, y, t, v)
	sim.partProperty(i, "life", math.random(100) + 11)
	sim.partProperty(i, "tmp2", math.random(360) - 1)
end)

elements.property(crpd, "Update", function(i, x, y, s, n)
	if sim.partProperty(i, "life") == 0 then
		local canSettle = false
		for r in sim.neighbors(x, y, 1, 1) do
			local ptype = sim.partProperty(r, "type")

			if ptype ~= crpd and ptype ~= crcy then
				canSettle = true
				break
			end
		end

		if canSettle then
			-- Mutate color
			local mutateRate = 15
			local tmp2 = sim.partProperty(i, "tmp2") + math.random(mutateRate * 2 + 1) - (mutateRate + 1)
			if tmp2 >= 360 then tmp2 = tmp2 - 360 + 1 end
			if tmp2 < 0 then tmp2 = tmp2 + 360 end
	
			local temp = sim.partProperty(i, "temp")
			simulation.pressure(x / 4, y / 4, -10)
			sim.partKill(i)
			local np = sim.partCreate(-1, x, y, crcy)
			sim.partProperty(np, "temp", temp)
			sim.partProperty(np, "tmp2", tmp2)
		else
			if math.random(3) == 1 then
				sim.partProperty(i, "life", math.random(30) + 11)
			else
				sim.partKill(i)
			end
		end
	end
end)
elements.property(crpd, "Graphics", function(i, r, g, b)

	local firea = 150
	local style = ren.FIRE_ADD + ren.PMODE_FLAT + ren.PMODE_FLARE

	local colr, colg, colb = hsvToRgb(sim.partProperty(i, "tmp2"), 1, 1)
	
	return 0, style, 255, colr, colg, colb, firea, colr, colg, colb
end)
end