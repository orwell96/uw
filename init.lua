-- Minetest 0.4 Mod: uw

--where the underworld starts. Don't set below -7500!
uw_DEPTH = -5000
--register obsidian stairs
uw_obsidian_stairs = true
--depth of the beginning of the Underworld


minetest.register_node("uw:portal", {
	description = "uw Portal",
	tiles = {
		"uw_transparent.png",
		"uw_transparent.png",
		"uw_transparent.png",
		"uw_transparent.png",
		{
			name = "uw_portal.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.5,
			},
		},
		{
			name = "uw_portal.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.5,
			},
		},
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	use_texture_alpha = true,
	walkable = false,
	digable = false,
	pointable = false,
	buildable_to = false,
	drop = "",
	light_source = 5,
	post_effect_color = {a=180, r=128, g=0, b=128},
	alpha = 192,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.1,  0.5, 0.5, 0.1},
		},
	},
	groups = {not_in_creative_inventory=1}
})


local function build_portal(pos, target, port_ori_z)
	local xp, zp, xta, zta=0,3,0,1
	if not port_ori_z then
		xp, zp, xta, zta=3,0,1,0
	end
	local p = {x=pos.x-xta, y=pos.y-1, z=pos.z-zta}
	local p1 = {x=pos.x-xta, y=pos.y-1, z=pos.z-zta}
	local p2 = {x=p1.x+xp, y=p1.y+4, z=p1.z+zp}
	for i=1,4 do
		minetest.set_node(p, {name="default:obsidian"})
		p.y = p.y+1
	end
	for i=1,3 do
		minetest.set_node(p, {name="default:obsidian"})
		p.x = p.x+xta
		p.z = p.z+zta
	end
	for i=1,4 do
		minetest.set_node(p, {name="default:obsidian"})
		p.y = p.y-1
	end
	for i=1,3 do
		minetest.set_node(p, {name="default:obsidian"})
		p.x = p.x-xta
		p.z = p.z-zta
	end
	for x=p1.x,p2.x do
	for z=p1.z,p2.z do
	for y=p1.y,p2.y do
		p = {x=x, y=y, z=z}
		if not ( (p1.z==p2.z and(x == p1.x or x == p2.x)) or (p1.x==p2.x and(z == p1.z or z == p2.z)) or y==p1.y or y==p2.y) then
			minetest.set_node(p, {name="uw:portal", param2=(port_ori_z and 1 or 0)})
		end
		local meta = minetest.get_meta(p)
		meta:set_string("p1", minetest.pos_to_string(p1))
		meta:set_string("p2", minetest.pos_to_string(p2))
		meta:set_string("target", minetest.pos_to_string(target))
		
		if y ~= p1.y then
			if port_ori_z then
				for x=-2,2 do
					if x ~= 0 then
						p.x = p.x+x
						if minetest.registered_nodes[minetest.get_node(p).name].is_ground_content and minetest.get_node(p).name~="default:obsidian" then
							minetest.remove_node(p)
						end
						p.x = p.x-x
					end
				end
			else
				for z=-2,2 do
					if z ~= 0 then
						p.z = p.z+z
						if minetest.registered_nodes[minetest.get_node(p).name].is_ground_content and minetest.get_node(p).name~="default:obsidian" then
							minetest.remove_node(p)
						end
						p.z = p.z-z
					end
				end
			end
		end
	end
	end
	end
end

minetest.register_abm({
	nodenames = {"uw:portal"},
	interval = 1,
	chance = 2,
	action = function(pos, node)
		minetest.add_particlespawner(
			{
				amount = 32,
				time = 4,
				--  ^ If time is 0 has infinite lifespan and spawns the amount on a per-second base
				minpos = {x=pos.x-0.25, y=pos.y-0.25, z=pos.z-0.25},
				maxpos = {x=pos.x+0.25, y=pos.y+0.25, z=pos.z+0.25},
				minvel = {x=-0.8, y=-0.8, z=-0.8},
				maxvel = {x=0.8, y=0.8, z=0.8},
				minacc = {x=0, y=0, z=0},
				maxacc = {x=0, y=0, z=0},
				minexptime = 0.5,
				maxexptime = 1,
				minsize = 1,
				maxsize = 2,
				--  ^ The particle's properties are random values in between the bounds:
				--  ^ minpos/maxpos, minvel/maxvel (velocity), minacc/maxacc (acceleration),
				--  ^ minsize/maxsize, minexptime/maxexptime (expirationtime)
				collisiondetection = false,
				--  ^ collisiondetection: if true uses collision detection
				--  ^ vertical: if true faces player using y axis only
				texture = "uw_particle.png",
				--  ^ Uses texture (string)
			}
		)
	end,
})
uw_check_portal_timer=0
uw_player_portal_teleported={}
uw_player_finding_portal={}

minetest.register_globalstep(function(dtime)
	uw_check_portal_timer=uw_check_portal_timer-dtime
	if uw_check_portal_timer>0 then return end
	uw_check_portal_timer=2
	
	for _,obj in ipairs(minetest.get_connected_players()) do
		local pos=vector.round(obj:getpos())
		if minetest.get_node(pos).name=="uw:portal" then
			if not uw_player_portal_teleported[obj:get_player_name()] then 
				local meta = minetest.get_meta(pos)
				local target = minetest.string_to_pos(meta:get_string("target"))
				uw_player_portal_teleported[obj:get_player_name()]=true
				if target then
					obj:setpos(target)
					obj:set_physics_override({speed=0, jump=0, gravity=0, sneak=false, sneak_glitch=false})
					minetest.after(1, uw_check_and_build_portal, pos, target, obj)
				elseif meta:get_string("p1") and meta:get_string("p1") then --target not yet set
					uw_player_portal_teleported[obj:get_player_name()]=true
					uw_player_finding_portal[obj:get_player_name()]=true
					obj:set_physics_override({speed=0, jump=0, gravity=0, sneak=false, sneak_glitch=false})
					local port_ori_z=(minetest.string_to_pos(meta:get_string("p1")).x==minetest.string_to_pos(meta:get_string("p2")).x)
					if pos.y>uw_DEPTH then
						minetest.chat_send_player(obj:get_player_name(), "You are now entering the underworld. Please wait for the portal connection to be established.")
						uw_continue_find_portal_pos(obj, pos, -7000, port_ori_z, 1)
					else
						minetest.chat_send_player(obj:get_player_name(), "You are now returning to the overworld. Please wait for the portal connection to be established.")
						uw_continue_find_portal_pos(obj, pos, 0, port_ori_z, 1)
					end
				end
			end
		elseif not uw_player_finding_portal[obj:get_player_name()] then--player is outside portal
			uw_player_portal_teleported[obj:get_player_name()]=false
		end
	end
end)

local function check_and_build_portal(pos, target, player)
	local n = minetest.get_node_or_nil(target)
	if n and n.name ~= "uw:portal" then
		build_portal(target, pos)
		minetest.after(2, uw_check_and_build_portal, pos, target, player)
	elseif not n then
		minetest.after(1, uw_check_and_build_portal, pos, target, player)
	else
		player:set_physics_override({speed=1, jump=1, gravity=1, sneak=true, sneak_glitch=true})
	end
end
uw_check_and_build_portal=check_and_build_portal
local function continue_find_portal_pos(player, from_pos, cont_y, port_ori_z, search_dir)
	local xp, zp, xta, zta=0,4,0,1
	if port_ori_z then
		xp, zp, xta, zta=4,0,1,0
	end
	repeat 
		--try all positions
		if minetest.get_node({x=from_pos.x, y=cont_y, z=from_pos.z}).name=="ignore" or
									minetest.get_node({x=from_pos.x, y=cont_y+3, z=from_pos.z}).name=="ignore" or
									minetest.get_node({x=from_pos.x+xp, y=cont_y, z=from_pos.z+zp}).name=="ignore" or
									minetest.get_node({x=from_pos.x+xp, y=cont_y+3, z=from_pos.z+zp}).name=="ignore" then
			--any of these has not been generated yet
			player:setpos({x=from_pos.x, y=cont_y, z=from_pos.z})
			--generate it!
			minetest.after(1,continue_find_portal_pos,player,from_pos,cont_y, port_ori_z, search_dir)
			--continue after it has been generated
			print("continue_find_portal_pos suspended at y ", cont_y)
			return
		end
		if minetest.get_node({x=from_pos.x, y=cont_y, z=from_pos.z}).name=="air" and
									minetest.get_node({x=from_pos.x, y=cont_y+3, z=from_pos.z}).name=="air" and
									minetest.get_node({x=from_pos.x+xp, y=cont_y, z=from_pos.z+zp}).name=="air" and
									minetest.get_node({x=from_pos.x+xp, y=cont_y+3, z=from_pos.z+zp}).name=="air" then
			--we have found a valid position
			uw_establish_portal_connection(player, from_pos, {x=from_pos.x, y=cont_y, z=from_pos.z}, port_ori_z)
			return
		end
		cont_y=cont_y+search_dir
	until false
end
uw_continue_find_portal_pos=continue_find_portal_pos
function uw_establish_portal_connection(player, from_pos, to_pos, port_ori_z)
	local xp, zp, xta, zta=0,4,0,1
	if port_ori_z then
		xp, zp, xta, zta=4,0,1,0
	end
	build_portal(to_pos, from_pos, port_ori_z)
	player:setpos(from_pos)
	minetest.after(1,uw_finish_establishment, player, from_pos, to_pos, port_ori_z)
	print("establish portal at y ", cont_y, "set player pos to",minetest.pos_to_string(from_pos), "and queried finish_establishment")
end
function uw_finish_establishment(player, from_pos, to_pos)
	if minetest.get_node_or_nil(from_pos) then
		print("finish_establishment at",minetest.pos_to_string(from_pos), "pos loaded. set portal target...")
		local meta=minetest.get_meta(from_pos)
		if not meta then
			print("finish_establishment at",minetest.pos_to_string(from_pos), "no metadata, queried finish_establishment")
			minetest.after(1,uw_finish_establishment, player, from_pos, to_pos)
		end
		local p1, p2=minetest.string_to_pos(meta:get_string("p1")),minetest.string_to_pos(meta:get_string("p2"))
		if not p1 or not p2 then
			print("finish_establishment at",minetest.pos_to_string(from_pos), "interestingly not a portal, creating one (fuck off dir)")
			build_portal(from_pos, to_pos)
		else
			for x=p1.x,p2.x do
				for z=p1.z,p2.z do
					for y=p1.y,p2.y do
						p = {x=x, y=y, z=z}
						--[[if not ( (p1.x==p2.x and(x == p1.x or x == p2.x)) or (p1.z==p2.z and(z == p1.z or x == p2.z)) or y==p1.y or y==p2.y) then
							minetest.set_node(p, {name="uw:portal", param2=(port_ori_z and 0 or 1)})
						end]]--should not be needed...
						local meta = minetest.get_meta(p)
						meta:set_string("p1", minetest.pos_to_string(p1))
						meta:set_string("p2", minetest.pos_to_string(p2))
						meta:set_string("target", minetest.pos_to_string(to_pos))
					end
				end
			end
		end
		player:setpos(to_pos)
		player:set_physics_override({speed=1, jump=1, gravity=1, sneak=true, sneak_glitch=true})
		minetest.chat_send_player(player:get_player_name(), "Portal complete! Enjoy your visit!")
		uw_player_finding_portal[player:get_player_name()]=false
	else--not yet loaded
		player:setpos(from_pos)
		print("finish_establishment at",minetest.pos_to_string(from_pos), "not yet loaded, queried finish_establishment")
		minetest.after(1,uw_finish_establishment, player, from_pos, to_pos)
	end
end

local function move_check(p1, max, dir)
	local p = {x=p1.x, y=p1.y, z=p1.z}
	local d = math.abs(max-p1[dir]) / (max-p1[dir])
	while p[dir] ~= max do
		p[dir] = p[dir] + d
		if minetest.get_node(p).name ~= "default:obsidian" then
			return false
		end
	end
	return true
end

local function check_portal(p1, p2)
	if p1.x ~= p2.x then
		if not move_check(p1, p2.x, "x") then
			return false
		end
		if not move_check(p2, p1.x, "x") then
			return false
		end
	elseif p1.z ~= p2.z then
		if not move_check(p1, p2.z, "z") then
			return false
		end
		if not move_check(p2, p1.z, "z") then
			return false
		end
	else
		return false
	end
	
	if not move_check(p1, p2.y, "y") then
		return false
	end
	if not move_check(p2, p1.y, "y") then
		return false
	end
	
	return true
end

local function is_portal(pos)
	for d=-3,3 do
		for y=-4,4 do
			local px = {x=pos.x+d, y=pos.y+y, z=pos.z}
			local pz = {x=pos.x, y=pos.y+y, z=pos.z+d}
			if check_portal(px, {x=px.x+3, y=px.y+4, z=px.z}) then
				return px, {x=px.x+3, y=px.y+4, z=px.z}
			end
			if check_portal(pz, {x=pz.x, y=pz.y+4, z=pz.z+3}) then
				return pz, {x=pz.x, y=pz.y+4, z=pz.z+3}
			end
		end
	end
end

local function make_portal(pos)
	local p1, p2 = is_portal(pos)
	if not p1 or not p2 then
		return false
	end
	
	for d=1,2 do
	for y=p1.y+1,p2.y-1 do
		local p
		if p1.z == p2.z then
			p = {x=p1.x+d, y=y, z=p1.z}
		else
			p = {x=p1.x, y=y, z=p1.z+d}
		end
		if minetest.get_node(p).name ~= "air" then
			return false
		end
	end
	end
	
	local param2
	if p1.z == p2.z then param2 = 0 else param2 = 1 end
	
	for d=0,3 do
		for y=p1.y,p2.y do
			local p = {}
			if param2 == 0 then p = {x=p1.x+d, y=y, z=p1.z} else p = {x=p1.x, y=y, z=p1.z+d} end
			if minetest.get_node(p).name == "air" then
				minetest.set_node(p, {name="uw:portal", param2=param2})
			end
			local meta = minetest.get_meta(p)
			meta:set_string("p1", minetest.pos_to_string(p1))
			meta:set_string("p2", minetest.pos_to_string(p2))
		end
	end
	return true
end
local function set_portal_target(pos, target)
	local p1, p2 = is_portal(pos)
	if not p1 or not p2 then
		return false
	end
	
	for d=1,2 do
		for y=p1.y+1,p2.y-1 do
			local p
			if p1.z == p2.z then
				p = {x=p1.x+d, y=y, z=p1.z}
			else
				p = {x=p1.x, y=y, z=p1.z+d}
			end
			if minetest.get_node(p).name ~= "air" then
				return false
			end
		end
	end
	
	local param2
	if p1.z == p2.z then param2 = 0 else param2 = 1 end
	
	for d=0,3 do
		for y=p1.y,p2.y do
			local p = {}
			if param2 == 0 then p = {x=p1.x+d, y=y, z=p1.z} else p = {x=p1.x, y=y, z=p1.z+d} end
			if minetest.get_node(p).name == "air" then
				minetest.set_node(p, {name="uw:portal", param2=param2})
			end
			local meta = minetest.get_meta(p)
			meta:set_string("p1", minetest.pos_to_string(p1))
			meta:set_string("p2", minetest.pos_to_string(p2))
			meta:set_string("target", minetest.pos_to_string(target))
		end
	end
	return true
end
uw_set_portal_target=set_portal_target

minetest.register_node(":default:obsidian", {
	description = "Obsidian",
	tiles = {"default_obsidian.png"},
	is_ground_content = true,
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky=1,level=2},
	
	on_destruct = function(pos)
		local meta = minetest.get_meta(pos)
		local p1 = minetest.string_to_pos(meta:get_string("p1"))
		local p2 = minetest.string_to_pos(meta:get_string("p2"))
		local target = minetest.string_to_pos(meta:get_string("target"))
		if not p1 or not p2 then
			return
		end
		for x=p1.x,p2.x do
		for y=p1.y,p2.y do
		for z=p1.z,p2.z do
			local nn = minetest.get_node({x=x,y=y,z=z}).name
			if nn == "default:obsidian" or nn == "uw:portal" then
				if nn == "uw:portal" then
					minetest.remove_node({x=x,y=y,z=z})
				end
				local m = minetest.get_meta({x=x,y=y,z=z})
				m:set_string("p1", "")
				m:set_string("p2", "")
				m:set_string("target", "")
			end
		end
		end
		end
		meta = minetest.get_meta(target)
		if not meta then
			return
		end
		p1 = minetest.string_to_pos(meta:get_string("p1"))
		p2 = minetest.string_to_pos(meta:get_string("p2"))
		if not p1 or not p2 then
			return
		end
		for x=p1.x,p2.x do
		for y=p1.y,p2.y do
		for z=p1.z,p2.z do
			local nn = minetest.get_node({x=x,y=y,z=z}).name
			if nn == "default:obsidian" or nn == "uw:portal" then
				if nn == "uw:portal" then
					minetest.remove_node({x=x,y=y,z=z})
				end
				local m = minetest.get_meta({x=x,y=y,z=z})
				m:set_string("p1", "")
				m:set_string("p2", "")
				m:set_string("target", "")
			end
		end
		end
		end
	end,
})

minetest.register_craftitem(":default:mese_crystal_fragment", {
	description = "Mese Crystal Fragment",
	inventory_image = "default_mese_crystal_fragment.png",
	on_place = function(stack,_, pt)
		if pt.under and minetest.get_node(pt.under).name == "default:obsidian" then
			local done = make_portal(pt.under)
			if done and not minetest.setting_getbool("creative_mode") then
				stack:take_item()
			end
		end
		return stack
	end,
})

minetest.register_node("uw:rack", {
	description = "Underworld Rack",
	tiles = {"uw_rack.png"},
	is_ground_content = true,
	drop = {
		max_items = 1,
		items = {{
			rarity = 1,
			items = {"uw:rack"},
		}}
	},
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("uw:sand", {
	description = "Underworld sand",
	tiles = {"uw_sand.png"},
	is_ground_content = true,
	groups = {crumbly=3,falling_node=1},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_gravel_footstep", gain=0.45},
	}),
})

minetest.register_node("uw:glowstone", {
	description = "Glowstone",
	tiles = {"uw_glowstone.png"},
	is_ground_content = true,
	light_source = 13,
	groups = {cracky=3,oddly_breakable_by_hand=3},
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("uw:brick", {
	description = "Underworld Brick",
	tiles = {"uw_brick.png"},
	groups = {cracky=2},
	sounds = default.node_sound_stone_defaults(),
})
--register stairs for underworld materials (and obsidian(why not))
if minetest.get_modpath("moreblocks") then
	
	stairsplus:register_all(
		"uw",
		"rack",
		"uw:rack",
		{
			description = "Underworld Rack",
			tiles = {"uw_rack.png"},
			groups = {cracky=3},
			sounds = default.node_sound_stone_defaults(),
		}
	)
	stairsplus:register_all(
		"uw",
		"brick",
		"uw:brick",
		{
			description = "Underworld Brick",
			tiles = {"uw_brick.png"},
			groups = {cracky=2},
			sounds = default.node_sound_stone_defaults(),
		}
	)
	if uw_obsidian_stairs then
		stairsplus:register_all(
			"default",
			"obsidian",
			"default:obsidian",
			{
				description = "Obsidian",
				tiles = {"default_obsidian.png"},
				groups = {cracky=1,level=2},
				sounds = default.node_sound_stone_defaults(),
			}
		)
	end
end


minetest.register_node("uw:turtlerock", {
	description = "Turtle Rock",
	tiles = {"uw_turtlerock.png"},
	groups = {unbreakable=1},
	sounds = default.node_sound_stone_defaults(),
})

local fence_texture = "default_fence_overlay.png^uw_brick.png^default_fence_overlay.png^[makealpha:255,126,126"
minetest.register_node("uw:fence", {
	description = "Underworld Fence",
	drawtype = "fencelike",
	tiles = {"uw_brick.png"},
	inventory_image = fence_texture,
	wield_image = fence_texture,
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	selection_box = {
		type = "fixed",
		fixed = {-1/7, -1/2, -1/7, 1/7, 1/2, 1/7},
	},
	groups = {choppy=2,oddly_breakable_by_hand=2},
	sounds = default.node_sound_wood_defaults(),
})


local modpath=minetest.get_modpath("uw");
dofile(modpath.."/subterrain.lua");
dofile(modpath.."/corridors.lua");
dofile(modpath.."/bottom.lua");


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


minetest.register_on_generated(function(minp, maxp, seed)
	if maxp.y > uw_DEPTH then
		return
	end
	
	print("generate y ", maxp.y, minp.y)
	
	local t1 = os.clock()
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	
	if minp.y >= -7952 then
		--subterrain
		data=uw_subterrain_generate(vm, emin, emax, data, minp, maxp, seed)
		
		local t2 = os.clock()
		
		
		local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
		for i in area:iterp(minp, maxp) do
			local d = data[i]
			if d == air then -- or d == stone_with_coal or d == stone_with_iron then
				data[i] = air
			elseif d == stone_with_diamond then --d == stone_with_mese or
				data[i] = lava_source
			elseif d == lava_flowing or d == lava_source then
				data[i] = uwrack --get rid of lava-filled caves, only spawn some sources.
			elseif d == stone_with_gold then
				data[i] = glowstone
			elseif d == stone_with_copper or d == gravel or d == dirt or d == sand then
				data[i] = uwsand
			elseif d == cobble or d == mossycobble or d == stair_cobble then
				data[i] = uwbrick
			else
				data[i] = uwrack
				--randomly spawn lava on this uwrack
				if math.floor(math.random(1,30*30))==1 then
					local pos=area:position(i)
					local upper=area:indexp({x=pos.x, y=pos.y+1, z=pos.z})
					if data[upper] == air then
						data[upper] = stone_with_diamond --the upper position will be iterated after this, so a lava source would be lost. stone_with_diamond will be replaced by lava.
						--print("[uw]creating lava source at "..minetest.pos_to_string({x=pos.x, y=pos.y+1, z=pos.z}))
					end
				end
			end
		end
		
		local chugent = math.ceil((os.clock() - t2) * 1000)
		print ("[uw] material generation " .. chugent .. " ms")
	
	elseif maxp.y <= -7952 and minp.y >=-8032 then
		
		uw_generate_bottom(vm, emin, emax, data, minp, maxp, seed)
		
	elseif maxp.y <= -8032 then
		
		uw_generate_below_bottom(vm, emin, emax, data, minp, maxp, seed)
		
	end
	t2 = os.clock()
	
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:update_liquids()
	
	vm:write_to_map()
	
	chugent = math.ceil((os.clock() - t2) * 1000)
	print ("[uw] write map " .. chugent .. " ms")
	
	chugent = math.ceil((os.clock() - t1) * 1000)
	print ("[uw]total uw generation time " .. chugent .. " ms (without corridors)")
	if minp.y > -7935 then
		uw_corridors_generate(minp, maxp, seed)
	end
end)