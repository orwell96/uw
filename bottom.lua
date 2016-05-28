--[[
Generate underworld bottom
generation chunk -7936 - -8000 will be redirected here.
Layers:
63-16: air and pfeiler in corners
16: fences of pathway
15-1 Lava_source
15: bricks for pathways
0: turtlerock
]]

local air = minetest.get_content_id("air")
local stone_with_coal = minetest.get_content_id("default:stone_with_coal")
local stone_with_iron = minetest.get_content_id("default:stone_with_iron")
local stone_with_mese = minetest.get_content_id("default:stone_with_mese")
local stone_with_diamond = minetest.get_content_id("default:stone_with_diamond")
local stone_with_gold = minetest.get_content_id("default:stone_with_gold")
local stone_with_copper = minetest.get_content_id("default:stone_with_copper")
local gravel = minetest.get_content_id("default:gravel")
local dirt = minetest.get_content_id("default:dirt")
local sand = minetest.get_content_id("default:sand")
local cobble = minetest.get_content_id("default:cobble")
local mossycobble = minetest.get_content_id("default:mossycobble")
local stair_cobble = minetest.get_content_id("stairs:stair_cobble")
local lava_source = minetest.get_content_id("default:lava_source")
local lava_flowing = minetest.get_content_id("default:lava_flowing")
local glowstone = minetest.get_content_id("uw:glowstone")
local uwsand = minetest.get_content_id("uw:sand")
local uwbrick = minetest.get_content_id("uw:brick")
local uwrack = minetest.get_content_id("uw:rack")
local turtlerock = minetest.get_content_id("uw:turtlerock")
local uwfence = minetest.get_content_id("uw:fence")

uw_generate_bottom=function(vm, emin, emax, data, minp, maxp, seed)
	
	local t2 = os.clock()

	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	for x=minp.x,maxp.x do
		for z=minp.z,maxp.z do
			for y=minp.y,maxp.y do
				local i=area:indexp({x=x, y=y, z=z})
				if y < minp.y+16 then
					data[i]=turtlerock
				elseif x>=(minp.x+38) and x<(minp.x+42) and
						z>=(minp.z+38) and z<(minp.z+42) then -- pfeiler
					if y % 8 == 4 then
						data[i]=glowstone
					else
						data[i]=uwbrick
					end
				else
					if y <= minp.y+31 then
						if y == minp.y+31 then 
							if x>=(minp.x+34) and x<(minp.x+46) and z>=(minp.z+34) and z<(minp.z+46) then --in range of pfeiler?
								data[i]=uwbrick
							elseif (x>=(minp.x+38) and x<(minp.x+42) ) or ( z>=(minp.z+38) and z<(minp.z+42) ) then --regular pathway
								data[i]=uwbrick
							else
								data[i]=lava_source
							end
						else
							data[i]=lava_source
						end
					else
						if y == minp.y+32 then
							if x>=(minp.x+34) and x<(minp.x+46) and z>=(minp.z+34) and z<(minp.z+46) then --in range of pfeiler?
								if ( x==(minp.x+34) or x==(minp.x+45) or z==(minp.z+34) or z==(minp.z+45) ) --is any border coord?
								and x~=(minp.x+40) and z~=(minp.z+40) and x~=(minp.x+39) and z~=(minp.z+39) then -- and not a center
									data[i]=uwfence
								else
									data[i]=air
								end
							elseif x==(minp.x+38) or x==(minp.x+41) or z==(minp.z+38) or z==(minp.z+41) then --regular pathway
								data[i]=uwfence
							else
								data[i]=air
							end
						else
							data[i]=air
						end
					end
				end
				
			end
		end
	end
	chugent = math.ceil((os.clock() - t2) * 1000)
	print ("[uw] generate unterworld bottom " .. chugent .. " ms")

	
end
--all further mapchunks will remain empty (air).
--maybe there will be put something below that layer.
uw_generate_below_bottom=function(vm, emin, emax, data, minp, maxp, seed)

	local t2 = os.clock()

	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	for i in area:iterp(minp, maxp) do
		data[i]=air
	end
	chugent = math.ceil((os.clock() - t2) * 1000)
	print ("[uw] generate below unterworld bottom " .. chugent .. " ms")
	
end
