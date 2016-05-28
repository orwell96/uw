-- „Parameter“/„Settings“

-- Wahrscheinlichkeit für jeden Chunk, solche Gänge mit Schienen zu bekommen
-- Probability for every newly generated chunk to get corridors
local probability_railcaves_in_chunk = 1/5

-- Innerhalb welcher Parameter soll sich die Pfadlänge bewegen?
-- Minimal and maximal value of path length
local way_min = 4;
local way_max = 7;


-- Wahrsch. für jeden Teil eines Korridors, nach oben oder nach unten zu gehen
-- Probability for every part of a corridor to go up or down
local probability_up_or_down = 0.2

-- Wahrscheinlichkeit für jeden Teil eines Korridors, sich zu verzweigen – vorsicht, wenn fast jeder Gang sich verzweigt, kann der Algorithmus unlösbar werden und MT hängt sich auf
-- Probability for every part of a corridor to fork – caution, too high values may cause MT to hang on.
local propability_fork = 0.5


-- Spielerische Generation, braucht aber mehr Rechenleistung
-- Fancy mode; deactivate if world generation too laggy
local fancy = true

-- Parameter Ende

local node_maincave = {name="uw:rack"}
local node_air = {name="air"}
local node_woodplanks = {name="uw:brick"}
local node_fence = {name="uw:fence"}

function nextrandom(min, max)
	return pr:next() / 32767 * (max - min) + min
end

function VMSetNode(pos, node)
	vm:set_node_at(pos, node)
end

function Between(a,b)
	return a+(b-a)/2
end

function vec3_add(a,b)
	return {x=a.x+b.x, y=a.y+b.y, z=a.z+b.z}
end

function vec3_sub(a,b)
	return {x=a.x-b.x, y=a.y-b.y, z=a.z-b.z}
end

function vec3_mul(v,s)
	return {x=s*v.x, y=s*v.y, z=s*v.z}
end

function MinMax(a,b)
	if a < b then
		return {min=a, max=b}
	else
		return {min=b, max=a}
	end
end

function isPointProper(p)
	return (minetest.get_node(p).name == "air") and p.y<-5000
end

function FillNodes(minp, maxp, node)
	for yi = minp.y, maxp.y do
		for zi = minp.z, maxp.z do
			for xi = minp.x, maxp.x do
				VMSetNode({x=xi, y=yi, z=zi}, node)
			end
		end
	end
end

function FillNodesProbable(minp, maxp, p, node)
	local y = MinMax(minp.y, maxp.y)
	local z = MinMax(minp.z, maxp.z)
	local x = MinMax(minp.x, maxp.x)
	for yi = y.min, y.max do
		for zi = z.min,z.max do
			for xi = x.min, x.max do
				if nextrandom(0,1) < p then
					VMSetNode({x=xi, y=yi, z=zi}, node)
				end
			end
		end
	end
end

function sqDistance(a,b,c)
	return a*a + b*b + c*c
end

function FillNodesCircled(centrum, radius, node)
	local sqradius = radius * radius
	for yi = centrum.y-radius-1,centrum.y+radius+1 do
		for zi = centrum.z-radius-1,centrum.z+radius+1 do
			for xi = centrum.x-radius-1,centrum.x+radius+1 do
				if sqDistance(centrum.x-xi, centrum.y-yi, centrum.z-zi) < sqradius then
					VMSetNode({x=xi, y=yi, z=zi}, node)
				end
			end
		end
	end
end

function placeStaff(coord)
	VMSetNode({x=coord.x, y=coord.y-2, z=coord.z}, node_fence)
end
function placeStaffWithTorch(coord)
	VMSetNode({x=coord.x, y=coord.y-1, z=coord.z}, {name="default:torch", param2=1})
	VMSetNode({x=coord.x, y=coord.y-2, z=coord.z}, node_fence)
end

function placeMaybePlanks(pt)
	if minetest.get_node(pt).name == "air" then
		if nextrandom(0,1) < 0.9 then
			VMSetNode(pt, node_woodplanks)
		end
	end
end

function mainCave(coord)
	local xdif = 4
	--air
	FillNodes({x=coord.x-3, y=coord.y-2, z=coord.z-3}, {x=coord.x+3, y=coord.y+2, z=coord.z+3}, node_air)
	-- roof
	FillNodes({x=coord.x-3, z=coord.z-3, y=coord.y-3}, {x=coord.x+3, z=coord.z+3, y=coord.y-3}, node_maincave)
	FillNodes({x=coord.x-3, z=coord.z-3, y=coord.y+3}, {x=coord.x+3, z=coord.z+3, y=coord.y+3}, node_maincave)
	-- walls
	FillNodes({x=coord.x-4, z=coord.z-3, y=coord.y-2}, {x=coord.x-4, z=coord.z+3, y=coord.y+2}, node_maincave)
	FillNodes({x=coord.x+4, z=coord.z-3, y=coord.y-2}, {x=coord.x+4, z=coord.z+3, y=coord.y+2}, node_maincave)

	FillNodes({x=coord.x-3, z=coord.z-4, y=coord.y-2}, {x=coord.x+3, z=coord.z-4, y=coord.y+2}, node_maincave)
	FillNodes({x=coord.x-3, z=coord.z+4, y=coord.y-2}, {x=coord.x+3, z=coord.z+4, y=coord.y+2}, node_maincave)
	-- round inner edges
	FillNodes({x=coord.x-3, z=coord.z-3, y=coord.y-2}, {x=coord.x+3, z=coord.z-3, y=coord.y-2}, node_maincave)
	FillNodes({x=coord.x-3, z=coord.z+3, y=coord.y-2}, {x=coord.x+3, z=coord.z+3, y=coord.y-2}, node_maincave)
	FillNodes({x=coord.x-3, z=coord.z-3, y=coord.y-2}, {x=coord.x-3, z=coord.z+3, y=coord.y-2}, node_maincave)
	FillNodes({x=coord.x+3, z=coord.z-3, y=coord.y-2}, {x=coord.x+3, z=coord.z+3, y=coord.y-2}, node_maincave)

	FillNodes({x=coord.x-3, z=coord.z-3, y=coord.y+2}, {x=coord.x+3, z=coord.z-3, y=coord.y+2}, node_maincave)
	FillNodes({x=coord.x-3, z=coord.z+3, y=coord.y+2}, {x=coord.x+3, z=coord.z+3, y=coord.y+2}, node_maincave)
	FillNodes({x=coord.x-3, z=coord.z-3, y=coord.y+2}, {x=coord.x-3, z=coord.z+3, y=coord.y+2}, node_maincave)
	FillNodes({x=coord.x+3, z=coord.z-3, y=coord.y+2}, {x=coord.x+3, z=coord.z+3, y=coord.y+2}, node_maincave)
end

-- horizontal even corridor part
function corridor_part(point, direction, length, i_offset)
	
	placeMaybePlanks({x=point.x-direction.z, y=point.y-2, z=point.z+direction.x})
	placeMaybePlanks({x=point.x, y=point.y-2, z=point.z})
	placeMaybePlanks({x=point.x+direction.z, y=point.y-2, z=point.z-direction.x})
	
	local vector = vec3_add(point, direction);
	
	for i = 1+i_offset,length+i_offset+2 do
		VMSetNode(vector, node_air)
		VMSetNode({x=vector.x, y=vector.y-1, z=vector.z}, node_air)
		
		VMSetNode({x=vector.x-direction.z, y=vector.y, z=vector.z+direction.x}, node_air)
		VMSetNode({x=vector.x-direction.z, y=vector.y-1, z=vector.z+direction.x}, node_air)
		VMSetNode({x=vector.x+direction.z, y=vector.y, z=vector.z-direction.x}, node_air)
		VMSetNode({x=vector.x+direction.z, y=vector.y-1, z=vector.z-direction.x}, node_air)

		-- Decke
		FillNodesProbable({x=vector.x-direction.z, y=vector.y+1, z=vector.z-direction.x}, {x=vector.x+direction.z, y=vector.y+1, z=vector.z+direction.x}, 0.9, node_air)
		if direction.y == 0 then
			-- when there is no floor: maybe wood will make it!
			placeMaybePlanks({x=vector.x-direction.z, y=vector.y-2, z=vector.z+direction.x})
			placeMaybePlanks({x=vector.x, y=vector.y-2, z=vector.z})
			placeMaybePlanks({x=vector.x+direction.z, y=vector.y-2, z=vector.z-direction.x})
			vector.y = vector.y+1
			if i % 5 == 0 then
				-- Wooden staff structures
				placeStaffWithTorch({x=vector.x+direction.z, y=vector.y, z=vector.z-direction.x})
				placeStaffWithTorch({x=vector.x-direction.z, y=vector.y, z=vector.z+direction.x})
			else
				placeStaff({x=vector.x+direction.z, y=vector.y, z=vector.z-direction.x})
				placeStaff({x=vector.x-direction.z, y=vector.y, z=vector.z+direction.x})
			end
			vector.y = vector.y-1
		end
		
		vector = vec3_add(vector, direction);
	end
	return vec3_sub(vector, vec3_mul(direction, 2))
end

-- up or down going corridor part
function coridor_part_with_y(point, direction)
	local air_disc = function(p, facedir)
		FillNodesProbable({x=p.x-facedir.z, y=p.y+1, z=p.z-facedir.x},
			{x=p.x+facedir.z, y=p.y-1, z=p.z+facedir.x}, 0.99, node_air)
		placeMaybePlanks({x=p.x+facedir.z, y=p.y-2, z=p.z+facedir.x})--floor for y'ers
		placeMaybePlanks({x=p.x, y=p.y-2, z=p.z})
		placeMaybePlanks({x=p.x-facedir.z, y=p.y-2, z=p.z-facedir.x})
		--FillNodesProbable({x=p.x-direction.z, y=p.y-1, z=p.z-direction.x}, {x=p.x+direction.z, y=p.y-1, z=p.z+direction.x}, 0.95, node_air)
		--FillNodesProbable({x=p.x-direction.z, y=p.y, z=p.z-direction.x}, {x=p.x+direction.z, y=p.y, z=p.z+direction.x}, 0.95, node_air)
		--FillNodesProbable({x=p.x-direction.z, y=p.y+1, z=p.z-direction.x}, {x=p.x+direction.z, y=p.y+1, z=p.z+direction.x}, 0.95, node_air)
		--VMSetNode(p, node_air)
		--print("air_disc at "..p.x..", "..p.y..", "..p.z)
	end
	if direction.y < 0 then
		direction.y = -1
	else
		direction.y = 1
	end
	local vector = vec3_add(point, {x=direction.x, z=direction.z, y=0})
	air_disc(vector, direction)
	vector = vec3_add(vector, direction)
	air_disc(vector, direction)
	vector = vec3_add(vector, {x=direction.x, z=direction.z, y=0})
	air_disc(vector, direction)
	vector = vec3_add(vector, direction)
	air_disc(vector, direction)
	vector = vec3_add(vector, direction)
	air_disc(vector, direction)
	vector = vec3_add(vector, {x=direction.x, z=direction.z, y=0})
	air_disc(vector, direction)
	vector = vec3_add(vector, direction)
	air_disc(vector, direction)
	return vector
end

function BulkOfWood(pt, height)
	-- Luftkreuz
	FillNodes({x=pt.x-2, z=pt.z-1, y=pt.y-1}, {x=pt.x+2, z=pt.z+1, y=pt.y+height-1}, node_air)
	FillNodes({x=pt.x-1, z=pt.z-2, y=pt.y-1}, {x=pt.x+1, z=pt.z+2, y=pt.y+height-1}, node_air)
	for yi = -1,height-1 do
		-- Holz
		VMSetNode({x=pt.x+1, z=pt.z+1, y=pt.y+yi-1}, node_woodplanks)
		VMSetNode({x=pt.x+1, z=pt.z-1, y=pt.y+yi-1}, node_woodplanks)
		VMSetNode({x=pt.x-1, z=pt.z+1, y=pt.y+yi-1}, node_woodplanks)
		VMSetNode({x=pt.x-1, z=pt.z-1, y=pt.y+yi-1}, node_woodplanks)
	end
end

function cross(point, lastdir, new_way_probability)
	--print("cross at "..point.x..", "..point.y..", "..point.z)
	local wood = nextrandom(0,5) < 1
	local second_floor = wood and nextrandom(1,3) < 2
	if wood then
		if second_floor then
			BulkOfWood(point, 7)
		else
			BulkOfWood(point, 3)
		end
	end
	local startpoint
	-- Code reduction by defining function
	local newway_func = function(midpoint, direction)
		if nextrandom(0,1) < new_way_probability then
			if wood then
		 		startpoint = vec3_add(midpoint, vec3_mul(direction, 2))
			else
				startpoint = midpoint
			end
			VMSetNode(vec3_add(vec3_add(midpoint, direction), {x=0, y=-1, z=0}), node_air)
			start_corridors(startpoint, direction)
		end
	end
	if not wood and nextrandom(0,1) < probability_up_or_down then
		lastdir.y = nextrandom(-0.5, 0.5)
	end
	newway_func(point, lastdir)
	newway_func(point, {x=-lastdir.z, y=0, z=lastdir.x})
	newway_func(point, {x=lastdir.z, y=0, z=-lastdir.x})
	if second_floor then
		newway_func({x=point.x, y=point.y+4, z=point.z}, lastdir)
		newway_func({x=point.x, y=point.y+4, z=point.z}, {x=-lastdir.z, y=0, z=lastdir.x})
		newway_func({x=point.x, y=point.y+4, z=point.z}, {x=lastdir.z, y=0, z=-lastdir.x})
		newway_func({x=point.x, y=point.y+4, z=point.z}, {x=-lastdir.x, y=0, z=-lastdir.z})
	end
end

function start_corridors(startpoint, direction)
	local length = nextrandom(1,6)*4
	local waypoint = vec3_add(startpoint, vec3_mul(direction, length))
	local gofurther = isPointProper(waypoint)
	
	if direction.y ~= 0 then
		waypoint = coridor_part_with_y(startpoint, direction)
	else
		waypoint = corridor_part(startpoint, direction, length, 3)
	end
	if not gofurther then
		return
	end
	local fork = nextrandom(0,1) < propability_fork
	if fork then
		cross(waypoint, direction, 0.5)
	end
end

function railcaves(main_cave_coord)
	vm=minetest.get_voxel_manip()
	
	vm:read_from_map(vec3_add(main_cave_coord, {x=-40, y=-5, z=-50}), vec3_add(main_cave_coord, {x=60, y=20, z=50}))
	
	mainCave(main_cave_coord)
	local dir = {x=1,y=0,z=0}
	local waypoint = corridor_part(vec3_add(main_cave_coord, vec3_mul(dir, 3)), dir, nextrandom(4,5)*3, 2)
	cross(waypoint, dir, 1)
	
	vm:calc_lighting()
	vm:write_to_map()
end

uw_corridors_generate=function(minp, maxp, seed)
	local t1 = os.clock()
	if not pr then
		pr = PseudoRandom(seed)
	end
	if nextrandom(0,1) < probability_railcaves_in_chunk and maxp.y < 10 then
		local mp
		for i = 1,3 do
			mp = {x=nextrandom(minp.x,maxp.x), y=nextrandom(minp.y,maxp.y), z=nextrandom(minp.z,maxp.z)}
			if isPointProper(mp) then
				break
			end
		end
		if isPointProper(mp) then
			railcaves(mp)
		end
	end
	chugent = math.ceil((os.clock() - t1) * 1000)
	print ("[uw_corridors] " .. chugent .. " ms")
end
--[[minetest.register_chatcommand("generate_uwshaft", {
	privs={server=true},
	func=function(name, param)
		local t1 = os.clock()
		local pos=minetest.get_player_by_name(name):getpos()
		railcaves({x=math.floor(pos.x),y=math.floor(pos.y),z=math.floor(pos.z),})
		chugent = math.ceil((os.clock() - t1) * 1000)
		print ("[uw_corridors] " .. chugent .. " ms")
	end
})]]
