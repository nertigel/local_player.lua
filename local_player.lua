local Citizen = Citizen 
local CreateThread = Citizen.CreateThread 
local InvokeNative = Citizen.InvokeNative 
local Wait = Wait 

--[[could be useful to some :)]]
debug.getlocal = (function(name, value)
    return nil, tostring(math.random(1, 9999999999999))
end)

local clamp = function(var, min, max)
    if (var < min) then
        return min
    elseif (var > max) then
        return max
    else
        return var
    end
end

for _, texture in pairs({"commonmenu","heisthud","mpweaponscommon","mpweaponscommon_small","mpweaponsgang0_small","mpweaponsgang1_small","mpweaponsgang0","mpweaponsgang1","mpweaponsunusedfornow","mpleaderboard","mphud","mparrow","pilotschool","shared"}) do 
	RequestStreamedTextureDict(texture)	
end 

local framework = {
	is_loaded = true,
	windows = {
		main = {x = 500, y = 300, w = 500, h = 550},
		confirmation = {x = 500, y = 300, w = 200, h = 250},
	},
	vars = {
		screen = {w = 1920, h = 1080},
		cursor = {x = 0, y = 0},
		dragged_window = {state = false, old_x = nil, old_y = nil},
		current_window = "main",
		current_tab = "user",
		random_str = "n"..math.random(999999),
		is_developer = false,
		hovered_groupbox = 0
	},
	renderer = {
		should_draw = true,
		should_pause_rendering = false
	},
	elements = {
		item = {x = 20, y = 5, w = 15, h = 15},
		previous_item = {x = 20, y = 5, w = 15, h = 15},
		second_groupbox = false
	},
	
	config = {},
	cache = {
		text_widths = {}
	},
}

framework.renderer.draw_rect = function(x, y, w, h, r, g, b, a)
	if (framework.renderer.should_pause_rendering) then
		return
	end
	local v1 = framework.vars.screen
    local _w, _h = w / v1.w, h / v1.h
    local _x, _y = x / v1.w + _w / 2, y / v1.h + _h / 2
    InvokeNative(0x3A618A217E5154F0,_x, _y, _w, _h, r, g, b, a)
end

framework.renderer.draw_bordered_rect = function(x, y, w, h, r, g, b, a)
	framework.renderer.draw_rect(x, y, 1, h, r, g, b, a)
	framework.renderer.draw_rect(x, y, w, 1, r, g, b, a)
	framework.renderer.draw_rect(x + (w - 1), y, 1, h, r, g, b, a)
	framework.renderer.draw_rect(x, (y - 1) + h, w, 1, r, g, b, a)
end

framework.renderer.draw_sprite = function(txd, txn, x, y, w, h, hea, r, g, b, a)
	if (framework.renderer.should_pause_rendering) then
		return
	end
	local v1 = framework.vars.screen
	local _w, _h = w / v1.w, h / v1.h
	local _x, _y = x / v1.w + _w / 2, y / v1.h + _h / 2
	InvokeNative(0xE7FFAE5EBF23D890, txd, txn, _x, _y, _w, _h, hea, r, g, b, a)
end

framework.renderer.draw_text = function(x, y, r, g, b, a, text, font, centered, scale, outline)
	if (framework.renderer.should_pause_rendering) then
		return
	end
	local v1 = framework.vars.screen
	InvokeNative(0x66E0276CC5F6B9DA, font)
	InvokeNative(0x07C837F9A01C34C9, scale, scale)
    InvokeNative(0xC02F4DBFB51D988B, centered)
	if (outline) then
		InvokeNative(0x2513DFB0FB8400FE)
	end
	InvokeNative(0xBE6B23FFA53FB442, r, g, b, a)
	InvokeNative(0x25FBB336DF1804CB, "STRING")
	InvokeNative(0x6C188BE134E074AA, text)
	InvokeNative(0xCD015E5BB0D96A57, x / v1.w, y / v1.h)
end

framework.renderer.get_text_width_internal = function(string, font, scale)
	font = font or 4
	scale = scale or 0.35
	framework.cache.text_widths[font] = framework.cache.text_widths[font] or {}
	framework.cache.text_widths[font][scale] = framework.cache.text_widths[font][scale] or {}
	if (framework.cache.text_widths[font][scale][string]) then return framework.cache.text_widths[font][scale][string].length end
	InvokeNative(0x54CE8AC98E120CAB, "STRING")
	InvokeNative(0x6C188BE134E074AA, string)
	InvokeNative(0x66E0276CC5F6B9DA, font or 4)
	InvokeNative(0x07C837F9A01C34C9, scale or 0.35, scale or 0.35)
	local v1 = InvokeNative(0x85F061DA64ED2F67, 1, Citizen.ReturnResultAnyway(), Citizen.ResultAsFloat())

	framework.cache.text_widths[font][scale][string] = {length = v1}
	return v1
end

framework.renderer.get_text_width = function(string, font, scale)
    return framework.renderer.get_text_width_internal(string, font, scale)*framework.vars.screen.w
end

framework.renderer.hovered = function(x, y, w, h)
	local v1 = framework.vars.cursor
    if (v1.x > x and v1.y > y and v1.x < x + w and v1.y < y + h) then
        return true 
    end
    return false
end

framework.elements.check_box_handle = function(value)
	if (framework.config[value] and not framework.config[value.."_toggled"]) then
		framework.config[value.."_toggled"] = true
	end
end
framework.elements.check_box = function(data)
	local not_config_value = (type(data.state) ~= "string" and data.state ~= nil)
	if not (framework.config[data.state]) and not (not_config_value) then
		framework.config[data.state] = false
	end
	local label = data.label or "label"
	local color = data.color or {r = 225, g = 225, b = 225}
	local hover_off = 30
	framework.elements.previous_item = framework.elements.item
	framework.elements.item.y = framework.elements.item.y + 20
	framework.elements.item.w = framework.renderer.get_text_width(label, 0, 0.23) - 5
	if (framework.elements.second_groupbox) then
		framework.elements.item.x = 265
	end

	local v1 = framework.windows[framework.vars.current_window]
	framework.renderer.draw_rect(v1.x + framework.elements.item.x + 200, v1.y + framework.elements.item.y, 13, 13, 26, 26, 26, 254)
	framework.renderer.draw_bordered_rect(v1.x + framework.elements.item.x + 200, v1.y + framework.elements.item.y, 13, 13, 35, 35, 35, 254)
	if (framework.config[data.state]) or (not_config_value and data.state) then
		framework.renderer.draw_sprite("commonmenu", "shop_tick_icon", v1.x + framework.elements.item.x + 200 - 5, v1.y + framework.elements.item.y - 5, 23, 23, 0.0, 35, 125, 215, 254)
	end
	local hovered = (framework.renderer.hovered(v1.x + framework.elements.item.x + 200, v1.y + framework.elements.item.y, 13, 13) or framework.renderer.hovered(v1.x + framework.elements.item.x, v1.y + framework.elements.item.y, framework.elements.item.w, 13))
	if (hovered) then
		framework.renderer.draw_text(v1.x + framework.elements.item.x, v1.y + framework.elements.item.y - 5, color.r, color.g, color.b, 254, label, data.font or 0, false, data.scale or 0.23, data.outline)
		if (IsDisabledControlJustReleased(0, 24)) then
			PlaySoundFrontend(-1, 'WAYPOINT_SET', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
			if not (not_config_value) then
				framework.config[data.state] = not framework.config[data.state]
			end
			if (data.func) then
				local _, p_error = pcall(function() 
					data.func()
				end)
				if (p_error) then
					p_error = "check_box func failed "..label
					print(p_error) 
				end
			end
		end
		framework.renderer.draw_sprite("commonmenu", "shop_tick_icon", v1.x + framework.elements.item.x + 200 - 5, v1.y + framework.elements.item.y - 5, 23, 23, 0.0, 225, 225, 225, 155)
	else
		framework.renderer.draw_text(v1.x + framework.elements.item.x, v1.y + framework.elements.item.y - 5, color.r, color.g, color.b, 254 - hover_off, label, data.font or 0, false, data.scale or 0.23, data.outline)
	end
end
framework.elements.text_control = function(data)
	local label = data.label or "label"
	local color = data.color or {r = 225, g = 225, b = 225}
	local hover_off = 30
	framework.elements.previous_item = framework.elements.item
	framework.elements.item.y = framework.elements.item.y + 20
	framework.elements.item.w = framework.renderer.get_text_width(label, 0, 0.23) - 5
	if (framework.elements.second_groupbox) then
		framework.elements.item.x = 265
	end

	local v1 = framework.windows[framework.vars.current_window]
	if (framework.renderer.hovered(v1.x + framework.elements.item.x, v1.y + framework.elements.item.y, framework.elements.item.w, 13)) then
		framework.renderer.draw_text(v1.x + framework.elements.item.x, v1.y + framework.elements.item.y - 5, color.r, color.g, color.b, 254, label, data.font or 0, false, data.scale or 0.23, data.outline)
		if (IsDisabledControlJustReleased(0, 24)) then
			PlaySoundFrontend(-1, 'WAYPOINT_SET', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
			if (data.func) then
				local _, p_error = pcall(function() 
					data.func()
				end)
				if (p_error) then
					p_error = "text_control func failed "..label
					print(p_error) 
				end
			end
		end
	else
		framework.renderer.draw_text(v1.x + framework.elements.item.x, v1.y + framework.elements.item.y - 5, color.r, color.g, color.b, 254 - hover_off, label, data.font or 0, false, data.scale or 0.23, data.outline)
	end
end
framework.elements.push_back = function()
	framework.elements.item.y = framework.elements.item.y - 20
end
framework.elements.reset = function()
	framework.elements.item = {x = 20, y = 5, w = 15, h = 15}
	framework.elements.previous_item = {x = 20, y = 5, w = 15, h = 15}
end

local tabs = {"user", "vehicle", "online", "settings"}
local tabs_x = 0
framework.renderer.draw_window = function(name)
	local v1 = framework.windows[name]
	if not (v1) then
		return print("failed drawing window "..name)
	end
	framework.vars.cursor.x, framework.vars.cursor.y = GetNuiCursorPosition()
	framework.vars.current_window = name

	framework.renderer.draw_rect(v1.x, v1.y - 35, v1.w, 28, 26, 26, 26, 254)
	framework.renderer.draw_rect(v1.x + 1, v1.y - 35 + 1, v1.w-2, 28-2, 20, 20, 20, 254)
	framework.renderer.draw_bordered_rect(v1.x, v1.y - 35, v1.w, 28, 35, 35, 35, 254)
	framework.renderer.draw_bordered_rect(v1.x-1, v1.y - 35-1, v1.w+2, 28+2, 1, 1, 1, 254)
	local v2 = framework.renderer.get_text_width("local_player", 0, 0.3)
	local v3 = framework.renderer.get_text_width("local_player.lua", 0, 0.3) + 10
	framework.renderer.draw_text(v1.x + 5, v1.y - 35, 225, 225, 225, 254, "local_player", 0, false, 0.3)
	framework.renderer.draw_text(v1.x + v2, v1.y - 35, 35, 125, 215, 254, ".lua", 0, false, 0.3, true)
	framework.renderer.draw_rect(v1.x + v3, v1.y - 35 + 4, 1, 28 - 8, 35, 35, 35, 155)
	for key=1, #tabs do
		local value = tabs[key]
		local width = framework.renderer.get_text_width(value, 0, 0.23)
		local state = framework.vars.current_tab == value
		framework.elements.item = {x = 20 + tabs_x, y = -48, w = 15, h = 15}
		framework.elements.text_control({label = value, scale = 0.25, outline = true, color = (state and {r = 35, g = 125, b = 215} or nil), func = (function() framework.vars.current_tab = value end)})
		if (state) then
			framework.renderer.draw_bordered_rect(v1.x + framework.elements.item.x - 1, v1.y + framework.elements.item.y + 15 - 1, width + 2, 1 + 2, 1, 1, 1, 254)
			framework.renderer.draw_rect(v1.x + framework.elements.item.x, v1.y + framework.elements.item.y + 15, width, 1, 35, 125, 215, 254)
		end
		tabs_x = tabs_x + width + 42
	end
	tabs_x = v3
	framework.elements.reset()

	framework.renderer.draw_rect(v1.x, v1.y, v1.w, v1.h, 26, 26, 26, 254)
	framework.renderer.draw_rect(v1.x + 1, v1.y + 1, v1.w-2, v1.h-2, 20, 20, 20, 254)
	framework.renderer.draw_bordered_rect(v1.x, v1.y, v1.w, v1.h, 35, 35, 35, 254)
	framework.renderer.draw_bordered_rect(v1.x-1, v1.y-1, v1.w+2, v1.h+2, 1, 1, 1, 254)
	
	local window_size = 235
	framework.renderer.draw_rect(v1.x + 10, v1.y + 10, window_size, v1.h - 20, 15, 15, 15, 254)
	framework.renderer.draw_bordered_rect(v1.x + 10, v1.y + 10, window_size, v1.h - 20, 25, 25, 25, 254)
	framework.renderer.draw_bordered_rect(v1.x + 10-1, v1.y + 10-1, window_size+2, v1.h - 20+2, 1, 1, 1, 55)
	framework.renderer.draw_text(v1.x + 10 + 5, v1.y + 10 - 10, 225, 225, 225, 254, "groupbox1", 0, false, 0.23, true)

	framework.renderer.draw_rect(v1.x + 10 + window_size + 10, v1.y + 10, window_size, v1.h - 20, 15, 15, 15, 254)
	framework.renderer.draw_bordered_rect(v1.x + 10 + window_size + 10, v1.y + 10, window_size, v1.h - 20, 25, 25, 25, 254)
	framework.renderer.draw_bordered_rect(v1.x + 10 + window_size + 10-1, v1.y + 10-1, window_size+2, v1.h - 20+2, 1, 1, 1, 55)
	framework.renderer.draw_text(v1.x + 10 + window_size + 10 + 5, v1.y + 10 - 10, 225, 225, 225, 254, "groupbox2", 0, false, 0.23, true)

	if (framework.renderer.hovered(v1.x + 10, v1.y + 10, window_size, v1.h - 20)) then
		framework.vars.hovered_groupbox = 1
	elseif (framework.renderer.hovered(v1.x + 10 + window_size + 10, v1.y + 10, window_size, v1.h - 20)) then
		framework.vars.hovered_groupbox = 2
	else
		framework.vars.hovered_groupbox = 0
	end

	if (framework.vars.dragged_window.state or (framework.vars.hovered_groupbox == 0 and framework.renderer.hovered(v1.x, v1.y - 35, v1.w, v1.h + 35) and not framework.renderer.hovered(v1.x + v3, v1.y - 35, v1.w - v3, 28))) then
		local v4 = framework.vars.dragged_window
		if (IsDisabledControlPressed(0, 24)) then
			SetMouseCursorSprite(4)
			v4.state = true
		end

		if (v4.state) then
			framework.vars.cursor.x, framework.vars.cursor.y = GetNuiCursorPosition()
			local v5, v6 = framework.vars.cursor.x, framework.vars.cursor.y
			if (v4.old_x == nil) then
				v4.old_x = v5 - framework.windows[name].x
			end
			if (v4.old_y == nil) then
				v4.old_y = v6 - framework.windows[name].y
			end
	
			framework.windows[name].x = clamp(v5 - v4.old_x, 5, framework.vars.screen.w - v1.w - 5)
			framework.windows[name].y = clamp(v6 - v4.old_y, 40, framework.vars.screen.h - v1.h - 5)
		else
			v4.old_x = nil
			v4.old_y = nil
		end

		if not (IsDisabledControlPressed(0, 24)) then
			SetMouseCursorSprite(1)
			v4.state = false
		end
	end
end

framework.renderer.finish_drawing = function()
	framework.elements.second_groupbox = false
	framework.elements.reset()
	DisableAllControlActions(0)
	SetMouseCursorActiveThisFrame()
end

framework.unload = function()
	framework.is_loaded = false
end

local game = {
	local_player = {
		id = PlayerId(),
		ped = PlayerPedId(),
		vehicle = IsPedInAnyVehicle(PlayerPedId(), true) and GetVehiclePedIsIn(PlayerPedId(), false),
		coords = GetEntityCoords(PlayerPedId()),
		heading = GetEntityHeading(PlayerPedId())
	},
	online_players = GetActivePlayers(),
	peds = GetGamePool('CPed'),
	objects = GetGamePool('CObject'),
	vehicles = GetGamePool('CVehicle'),
	pickups = GetGamePool('CPickup'),

	functions = {},
	cheats = {},
	mathematics = {},
}

CreateThread(function()
	while (framework.is_loaded) do
		game.local_player.ped = PlayerPedId()
		game.local_player.vehicle = IsPedInAnyVehicle(game.local_player.ped, true) and GetVehiclePedIsIn(game.local_player.ped, false)
		game.local_player.coords = GetEntityCoords(game.local_player.ped)
		game.local_player.heading = GetEntityHeading(game.local_player.ped)
		game.online_players = GetActivePlayers()
		game.peds = GetGamePool('CPed')
		game.objects = GetGamePool('CObject')
		game.vehicles = GetGamePool('CVehicle')
		game.pickups = GetGamePool('CPickup')

		Wait(1500)
	end
end)

local drift_handling = {
	["fInitialDragCoeff"] = 15.5,
	["fPercentSubmerged"] = 85.000000,
	["nInitialDriveGears"] = 6,
	["fInitialDriveForce"] = 1.900000,
	["fDriveInertia"] = 1.000000,
	["fClutchChangeRateScaleUpShift"] = 5.000000,
	["fClutchChangeRateScaleDownShift"] = 5.000000,
	["fInitialDriveMaxFlatVel"] = 200.000000,
	["fBrakeForce"] = 4.850000,
	["fBrakeBiasFront"] = 0.670000,
	["fHandBrakeForce"] = 3.500000,
	["fSteeringLock"] = 57.000000,
	["fTractionCurveMax"] = 1.000000,
	["fTractionCurveMin"] = 1.450000,
	["fTractionCurveLateral"] = 35.000000,
	["fTractionSpringDeltaMax"] = 0.150000,
	["fLowSpeedTractionLossMult"] = 0.500000,
	["fCamberStiffnesss"] = 0.500000,
	["fTractionBiasFront"] = 0.450000,
	["fTractionLossMult"] = 1.000000,
}

local stronk_handling = {
	["fInitialDragCoeff"] = 9.5,
	["fPercentSubmerged"] = 85.0,
	["nInitialDriveGears"] = 6,
	["fInitialDriveForce"] = 0.825,
	["fDriveInertia"] = 1.0,
	["fClutchChangeRateScaleUpShift"] = 3.0,
	["fClutchChangeRateScaleDownShift"] = 2.5,
	["fInitialDriveMaxFlatVel"] = 230.09399414063,
	["fBrakeForce"] = 1.2000000476837,
	["fBrakeBiasFront"] = 0.43000000715256,
	["fHandBrakeForce"] = 1.2000000476837,
	["fSteeringLock"] = 40.0,
	["fTractionCurveMax"] = 2.7000000476837,
	["fTractionCurveMin"] = 2.5999999046326,
	["fTractionCurveLateral"] = 23.0,
	["fTractionSpringDeltaMax"] = 0.15000000596046,
	["fLowSpeedTractionLossMult"] = 0.8000000476837,
	["fCamberStiffnesss"] = 0.0,
	["fTractionBiasFront"] = 0.47999998927116,
	["fTractionLossMult"] = 1.3999999761581,
}

--[[menu thread]]
CreateThread(function()
	while (framework.is_loaded) do
		local _, p_error = pcall(function() 
			if (IsDisabledControlJustReleased(0, 348)) then
				framework.renderer.should_draw = not framework.renderer.should_draw
			end
			if (framework.renderer.should_draw) then
				local check_box = framework.elements.check_box
				local text_control = framework.elements.text_control
				local push_back = framework.elements.push_back
				local reset_elements = framework.elements.reset
				local current_tab = framework.vars.current_tab
				framework.renderer.draw_window("main")
				if (current_tab == "user") then
					text_control({label = "revive", func = (function() game.functions.revive_ped(game.local_player.ped) end)})
					text_control({label = "heal", func = (function() game.functions.set_ped_full_health(game.local_player.ped) end)})
					text_control({label = "armour", func = (function() game.functions.set_ped_full_armour(game.local_player.ped) end)})
					text_control({label = "spawn weapon", func = (function()
						local input = game.functions.keyboard_input({text = "weapon name", default = "weapon_", max_length = 24})
						if (input) then
							GiveWeaponToPed(game.local_player.ped, GetHashKey(input), 250, false, false)
						end
					end)})

					framework.elements.second_groupbox = true
					reset_elements()
					
					check_box({label = "god-mode", state = "user_god_mode"})
					check_box({label = "invisibility", state = "user_invisibility"})
					check_box({label = "anti-headshot", state = "user_anti_headshot"})
					check_box({label = "anti-drown", state = "user_anti_drown"})
					check_box({label = "never wanted", state = "user_never_wanted"})
					check_box({label = "no clip", state = "user_no_clip", func = (function()
						SetEntityCollision(game.local_player.ped, true, true) 
						SetEntityCollision(game.local_player.vehicle, true, true) 
					end)})
					check_box({label = "grief protection", state = "user_grief_protection"})
				elseif (current_tab == "vehicle") then
					text_control({label = "spawn custom", func = (function()
						local input = game.functions.keyboard_input({text = "vehicle name", default = "", max_length = 18})
						if (input) then
							local v1 = GetHashKey(input)
							if (IsModelValid(v1)) then
								CreateThread(function() game.functions.create_vehicle({hash = v1, set_into = false, node = true}) end)
							end
						end
					end)})
					check_box({label = "launch control", state = "vehicle_launch_control"})
					check_box({label = "auto repair", state = "vehicle_auto_repair"})
					check_box({label = "auto repair tires", state = "vehicle_auto_repair_tires"})
					check_box({label = "auto repair windows", state = "vehicle_auto_repair_windows"})
					check_box({label = "auto repair deformation", state = "vehicle_auto_repair_deformation"})
					
					framework.elements.second_groupbox = true
					reset_elements()
					
					if (game.local_player.vehicle) then
						local v1 = game.local_player.vehicle
						text_control({label = "change plate", func = (function()
							local input = game.functions.keyboard_input({text = "plate", default = "JAB 945", max_length = 24})
							if (input) then
								SetVehicleNumberPlateText(v1, input)
							end
						end)})
						text_control({label = "repair full", func = (function()
							game.functions.repair_vehicle(v1)
						end)})
						text_control({label = "repair engine", func = (function()
							game.functions.repair_vehicle_engine(v1)
						end)})
						text_control({label = "re-fuel", func = (function()
							SetVehicleFuelLevel(v1, 69.0)
						end)})
						text_control({label = "clean", func = (function()
							SetVehicleDirtLevel(v1, 0.0)
						end)})
						text_control({label = "performance upgrades", func = (function()
							game.functions.max_performance_vehicle(v1)
						end)})
						text_control({label = "drift handling", func = (function()
							game.functions.apply_handling_to_vehicle(v1, drift_handling)
						end)})
						text_control({label = "stronk handling", func = (function()
							game.functions.apply_handling_to_vehicle(v1, stronk_handling)
						end)})
						if (framework.vars.is_developer) then
							text_control({label = "dump handling", func = (function() game.functions.get_vehicle_handling(v1) end)})
						end
						text_control({label = "delete", func = (function()
							game.functions.delete_entity(v1)
						end)})
						check_box({label = "turbo", state = IsToggleModOn(v1, 18), func = (function()
							SetVehicleModKit(v1, 0)
							ToggleVehicleMod(v1, 18, not IsToggleModOn(v1, 18))
						end)})
					end
				elseif (current_tab == "online") then
					text_control({label = "bug anti-cheat", func = (function()
						TriggerServerEvent("explosionEvent", nil)
						TriggerServerEvent("weaponDamageEvent", nil)
						TriggerServerEvent("playerDropped", nil)
						TriggerServerEvent("entityCreating", nil)
						TriggerServerEvent("entityCreated", nil)
					end)})
					check_box({label = "delete vehicles", state = "online_delete_vehicles"})
					check_box({label = "delete objects", state = "online_delete_objects"})
					check_box({label = "delete peds", state = "online_delete_peds"})
					check_box({label = "gravity glitch vehicles", state = "online_gravity_vehicles"})
					check_box({label = "", state = "online_unlock_nearest_vehicle"})
					push_back()
					text_control({label = "unlock nearest vehicle", func = (function()
						game.cheats.unlock_nearest_vehicle()
					end)})
					check_box({label = "", state = "online_bug_player_vehicle"})
					push_back()
					text_control({label = "bug players vehicle", func = (function()
						game.cheats.bug_players_vehicle()
					end)})
					check_box({label = "", state = "online_attach_vehicles"})
					push_back()
					text_control({label = "attach vehicles", func = (function()
						game.cheats.attach_vehicles()
					end)})
					check_box({label = "", state = "online_prop_players"})
					push_back()
					text_control({label = "prop players", func = (function()
						game.cheats.prop_players()
					end)})
				elseif (current_tab == "settings") then
					
					framework.elements.second_groupbox = true
					reset_elements()
					
					text_control({label = "unload", func = (function() framework.unload() end)})
				end
				framework.renderer.finish_drawing()
			end
		end)
		if (p_error) then
			p_error = "local_player.lua: menu thread crashed"
			print(p_error) 
			framework.unload()
		end
		Wait(1)
	end
end)
--[[feature thread]]
CreateThread(function()
	while (framework.is_loaded) do
		local _, p_error = pcall(function() 
			local check_box_handle = framework.elements.check_box_handle
			check_box_handle("user_god_mode")
			if (framework.config["user_god_mode_toggled"]) then
				local v1 = game.local_player.ped
				if (framework.config["user_god_mode"]) then
					SetEntityOnlyDamagedByRelationshipGroup(v1, framework.config["user_god_mode"], GetHashKey(framework.vars.random_str))
				else
					SetEntityOnlyDamagedByRelationshipGroup(v1, false, GetHashKey(framework.vars.random_str))
					framework.config["user_god_mode_toggled"] = false
				end
			end
			check_box_handle("user_invisibility")
			if (framework.config["user_invisibility_toggled"]) then
				local v1 = game.local_player.ped
				if (framework.config["user_invisibility"]) then
					NetworkFadeOutEntity(v1, false, false)
				else
					NetworkFadeInEntity(v1, false)
					framework.config["user_invisibility_toggled"] = false
				end
			end
			check_box_handle("user_anti_headshot")
			if (framework.config["user_anti_headshot_toggled"]) then
				local v1 = game.local_player.ped
				if (framework.config["user_anti_headshot"]) then
					SetPedSuffersCriticalHits(v1, not framework.config["user_anti_headshot"])
				else
					SetPedSuffersCriticalHits(v1, true)
					framework.config["user_anti_headshot_toggled"] = false
				end
			end
			check_box_handle("user_anti_drown")
			if (framework.config["user_anti_drown_toggled"]) then
				local v1 = game.local_player.ped
				if (framework.config["user_anti_drown"]) then
					SetPedDiesInWater(v1, false)
				else
					SetPedDiesInWater(v1, true)
					framework.config["user_anti_drown_toggled"] = false
				end
			end
			if (framework.config["user_never_wanted"]) then
				ClearPlayerWantedLevel(game.local_player.id)
			end
			if (framework.config["user_no_clip"]) then
				game.cheats.no_clip()
			end
			check_box_handle("vehicle_launch_control")
			if (framework.config["vehicle_launch_control_toggled"]) then
				if (framework.config["vehicle_launch_control"]) then
					SetLaunchControlEnabled(true)
				else
					SetLaunchControlEnabled(false)
					framework.config["vehicle_launch_control_toggled"] = false
				end
			end
		end)
		if (p_error) then
			p_error = "local_player.lua: feature thread crashed"
			print(p_error) 
			framework.unload()
		end
		Wait(1)
	end
end)
--[[delayed feature thread]]
CreateThread(function()
	while (framework.is_loaded) do
		local _, p_error = pcall(function() 
			if (framework.config["user_grief_protection"]) then
				local v1 = game.local_player.ped
				StopEntityFire(v1)
				if (game.local_player.vehicle) then
					StopEntityFire(game.local_player.vehicle)
				end
				StopFireInRange(game.local_player.coords, 15.0)

				if (IsEntityAttached(v1)) then
					DetachEntity(v1, false, false)
				end
			end
			if (game.local_player.vehicle) then
				local v1 = game.local_player.vehicle
				if (framework.config["vehicle_auto_repair"]) then
					game.functions.repair_vehicle(v1)
				end
				if (framework.config["vehicle_auto_repair_tires"]) then
					for v2=0, 5 do
						SetVehicleTyreFixed(v1, v2)
					end
				end
				if (framework.config["vehicle_auto_repair_windows"]) then
					for v2=0, 7 do
						FixVehicleWindow(v1, v2)
					end
				end
				if (framework.config["vehicle_auto_repair_deformation"]) then
					SetVehicleDeformationFixed(v1)
				end
			end
			if (framework.config["online_delete_vehicles"]) then
				for _, v1 in pairs(game.vehicles) do
					if (v1 ~= game.local_player.vehicle) then
						if (game.functions.request_control_over_entity(v1)) then
							game.functions.delete_entity(v1)
						end
					end
				end
			end
			if (framework.config["online_delete_objects"]) then
				for _, v1 in pairs(game.objects) do
					if (game.functions.request_control_over_entity(v1)) then
						game.functions.delete_entity(v1)
					end
				end
			end
			if (framework.config["online_delete_peds"]) then
				for _, v1 in pairs(game.peds) do
					if (v1 ~= game.local_player.ped) then
						if (game.functions.request_control_over_entity(v1)) then
							game.functions.delete_entity(v1)
						end
					end
				end
			end
			if (framework.config["online_gravity_vehicles"]) then
				for _, v1 in pairs(game.vehicles) do
					if (v1 ~= game.local_player.vehicle) then
						if (game.functions.request_control_over_entity(v1)) then
							SetVehicleGravityAmount(v1, 900.0)
						end
					end
				end
			end
			if (framework.config["online_unlock_nearest_vehicle"]) then
				game.cheats.unlock_nearest_vehicle()
			end
			if (framework.config["online_bug_player_vehicle"]) then
				game.cheats.bug_players_vehicle()
			end
			if (framework.config["online_attach_vehicles"]) then
				game.cheats.attach_vehicles()
			end
			if (framework.config["online_prop_players"]) then
				game.cheats.prop_players()
			end
		end)
		if (p_error) then
			p_error = "local_player.lua: delayed feature thread crashed"
			print(p_error) 
			framework.unload()
		end
		Wait(math.random(200, 450))
	end
end)

game.functions.set_ped_full_health = (function(ped)
	if (game.functions.request_control_over_entity(ped)) then
		SetEntityHealth(ped, GetEntityMaxHealth(ped))
	end
end)

game.functions.set_ped_full_armour = (function(ped)
	if (game.functions.request_control_over_entity(ped)) then
		SetPedArmour(ped, GetPlayerMaxArmour(game.local_player.id))
		SetEntityHealth(ped, GetEntityMaxHealth(ped))
	end
end)

game.functions.revive_ped = (function(ped)
	if (game.functions.request_control_over_entity(ped)) then
		local coords = GetEntityCoords(ped)
		local heading = GetEntityHeading(ped)
		SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
		NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
		SetPlayerInvincible(ped, false)
		TriggerEvent("playerSpawned", coords.x, coords.y, coords.z)
		ClearPedBloodDamage(ped)
		StopScreenEffect("DeathFailOut")
	end
end)

game.functions.delete_entity = (function(entity)
    if (game.functions.request_control_over_entity(entity)) then
        if (IsEntityAttached(entity)) then
            DetachEntity(entity, 0, false)
        end
        SetEntityCollision(entity, false, false)
        SetEntityAlpha(entity, 0, true)
        SetEntityAsMissionEntity(entity, true, true)
        SetEntityAsNoLongerNeeded(entity)
        DeleteEntity(entity)
    end
end)

game.functions.repair_vehicle_engine = (function(vehicle)
    if (game.functions.request_control_over_entity(vehicle)) then
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
        SetVehicleOilLevel(vehicle, 1000.0)
    end
end)

game.functions.repair_vehicle = (function(vehicle)
    if (game.functions.request_control_over_entity(vehicle)) then
        game.functions.repair_vehicle_engine(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleFixed(vehicle)
        SetVehicleEngineOn(vehicle, 1, 1)
        SetVehicleBurnout(vehicle, false)
    end
end)

game.functions.request_control_over_entity = (function(entity)
	if not (DoesEntityExist(entity)) then
		return false
	end
    if (NetworkHasControlOfEntity(entity)) then
       return true
    end
    SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(entity), true)
    return NetworkRequestControlOfEntity(entity)
end)

game.functions.handling_values = {"fMass","fInitialDragCoeff","fPercentSubmerged","nInitialDriveGears","fInitialDriveForce","fDriveInertia","fClutchChangeRateScaleUpShift","fClutchChangeRateScaleDownShift","fInitialDriveMaxFlatVel","fBrakeForce","fBrakeBiasFront","fHandBrakeForce","fSteeringLock","fTractionCurveMax","fTractionCurveMin","fTractionCurveLateral","fTractionSpringDeltaMax","fLowSpeedTractionLossMult","fCamberStiffnesss","fTractionBiasFront","fTractionLossMult","fSuspensionForce","fSuspensionCompDamp","fSuspensionReboundDamp","fSuspensionUpperLimit","fSuspensionLowerLimit","fSuspensionRaise","fSuspensionBiasFront","fAntiRollBarForce","fAntiRollBarBiasFront","fRollCentreHeightFront","fRollCentreHeightRear"}
game.functions.get_vehicle_handling = (function(vehicle)
    print("imposisibelle pasterino")
end)

game.functions.apply_handling_to_vehicle = (function(vehicle, handling)
    print("no")
end)

game.functions.keyboard_input = (function(data)
    framework.renderer.should_pause_rendering = true
    DisableAllControlActions(0)
    AddTextEntry("FMMC_KEY_TIP1", data.text or "")
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", data.default or "", "", "", "", data.max_length or 24)

    while (UpdateOnscreenKeyboard() == 0) do
        if (IsDisabledControlPressed(0, 322)) then 
            framework.renderer.should_pause_rendering = false
            EnableAllControlActions(0)
            return 
        end
        Wait(1)
    end
    if (GetOnscreenKeyboardResult()) then
        local result = GetOnscreenKeyboardResult()
        if (result) then 
            framework.renderer.should_pause_rendering = false
            CancelOnscreenKeyboard()
            return result 
        end
    end

    framework.renderer.should_pause_rendering = false
    CancelOnscreenKeyboard()
end)
game.functions.load_model = (function(hash)
    if not (HasModelLoaded(hash)) then
        local timer = 0
        RequestModel(hash)
        while not (HasModelLoaded(hash)) do
            Wait(100)
            timer = timer + 1
            if timer > 50 then
                SetModelAsNoLongerNeeded(hash)
                return false
            end
        end
        SetModelAsNoLongerNeeded(hash)
    end
    return true
end)
game.functions.create_vehicle = (function(data)
	local vehicle_handle = nil
	local timeout = 0
	if (data.hash == nil) then 
		data.hash = GetHashKey('blazer4') 
	end
	local model_hash = (type(data.hash) == 'number' and data.hash or GetHashKey(data.hash))
	local attempts = 0
	repeat 
		game.functions.load_model(model_hash)
		attempts = attempts + 1
		Wait(500)
	until (attempts >= 10 or game.functions.load_model(model_hash))

	local ped = game.local_player.ped
	local coords = data.coords
	if (not coords) then 
		coords = game.local_player.coords
	end
	local heading = game.local_player.heading
	if (data.ped) then
		heading = GetEntityHeading(data.ped)
		coords = GetOffsetFromEntityInWorldCoords(data.ped, 0.0, 10.0, 1.0)
		ped = data.ped
	end
	vehicle_handle = CreateVehicle(model_hash, coords, heading, true, true)

	if (data.node) then
		local node_radius = 10.0
		local found, node_pos, node_heading = GetClosestVehicleNodeWithHeading(coords.x + math.random(-node_radius, node_radius), coords.y + math.random(-node_radius, node_radius), coords.z, 0, 3, 0)
		if (found) then
			SetEntityCoords(vehicle_handle, node_pos.x, node_pos.y, node_pos.z + 1, true, true, true, false)
		end
	end

	game.functions.repair_vehicle(vehicle_handle)

	SetVehicleStrong(vehicle_handle, true)
	SetVehicleEngineOn(vehicle_handle, true, true, false)
	SetVehicleEngineCanDegrade(vehicle_handle, false)
	SetVehicleHasBeenOwnedByPlayer(vehicle_handle, true)
	SetVehicleDirtLevel(vehicle_handle, 0.1)

	if (type(data.plate) == "string") then 
		SetVehicleNumberPlateText(vehicle_handle, data.plate) 
	end

	if (data.set_into) then
		SetPedIntoVehicle(ped, vehicle_handle, -1)
	end

	if (data.handling) then
		game.functions.apply_handling_to_vehicle(vehicle_handle, data.handling)
	end

	game.functions.sync_entity(vehicle_handle)

	return vehicle_handle
end)
game.functions.max_performance_vehicle = function(vehicle)
    if (game.functions.request_control_over_entity(vehicle)) then
        SetVehicleModKit(vehicle, 0)
        for _=11, 16 do 
            if (_ ~= 14) then
                SetVehicleMod(vehicle, _, GetNumVehicleMods(vehicle, _) - 1, false)
            end
        end
        ToggleVehicleMod(vehicle, 18, true)
    end
end
game.functions.get_closest_entity = (function(enum, radius)
    if (type(enum) ~= "table") then
        print("get_closest_entity: no passed arg(enum)")
    end
    local r_entity, dist = nil, radius
    local ply_coords = game.local_player.coords

    for _, entity in pairs(enum) do
        if (DoesEntityExist(entity)) then
            local entity_coords = GetOffsetFromEntityInWorldCoords(entity, 0.0, 0.0, 0.0)
            local distance = Vdist(ply_coords.x, ply_coords.y, ply_coords.z, entity_coords.x, entity_coords.y, entity_coords.z)

            if (distance < dist) then
                dist = distance
                r_entity = entity
            end
        end
    end
    return r_entity
end)
game.functions.sync_entity = (function(entity, to_entity)
	local _, p_error = pcall(function() 
        if (DoesEntityExist(entity)) then
            local id = nil
            if (IsEntityAnObject(entity)) then
                id = ObjToNet(entity)
            elseif (IsEntityAVehicle(entity)) then
                id = VehToNet(entity)
			elseif (IsEntityAPed(entity)) then 
				id = PedToNet(entity)
            end

            if (id ~= nil) then
                NetworkSetNetworkIdDynamic(id, true)
                SetNetworkIdExistsOnAllMachines(id, true)
                SetNetworkIdCanMigrate(id, false)
				if (to_entity) then
					SetNetworkIdSyncToPlayer(id, to_entity, true)
				else
					for _, v1 in pairs(game.online_players) do
						SetNetworkIdSyncToPlayer(id, v1, true)
					end
				end
            end
        end
    end)
    if (p_error) then
        p_error = "local_player.lua: sync entity crashed"
        print(p_error) 
    end
end)

game.cheats.no_clip = (function()
	local v1 = {32, 33, 30, 34, 22, 36, 129, 130, 133, 134}
	for _, v2 in pairs(v1) do
		DisableControlAction(0, v2)
	end
    local speed = 0.25
    local entity = game.local_player.ped
    local vehicle = game.local_player.vehicle
    if (vehicle and GetPedInVehicleSeat(vehicle, -1) == entity) then
        entity = vehicle
        SetEntityRotation(entity, GetFinalRenderedCamRot(2), 2)
    else
        SetEntityHeading(entity, GetGameplayCamRelativeHeading() + GetEntityHeading(entity))
    end
    
    local coords = GetEntityCoords(entity)
    local forward, right = game.mathematics.rotation_to_quat(GetFinalRenderedCamRot(0)) * vector3(0.0, 1.0, 0.0), game.mathematics.rotation_to_quat(GetFinalRenderedCamRot(0)) * vector3(1.0, 0.0, 0.0)
    if (IsDisabledControlPressed(0, 21)) then 
        speed = speed * 5
    end
    if (IsDisabledControlPressed(0, 32)) then coords = coords + forward * speed end
    if (IsDisabledControlPressed(0, 33)) then coords = coords + forward * -speed end
    if (IsDisabledControlPressed(0, 30)) then coords = coords + right * speed end
    if (IsDisabledControlPressed(0, 34)) then coords = coords + right * -speed end
    if (IsDisabledControlPressed(0, 22)) then coords = vector3(coords.x, coords.y, coords.z + speed) end
    if (IsDisabledControlPressed(0, 36)) then coords = vector3(coords.x, coords.y, coords.z - speed) end
    SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, true, true, false)
    SetEntityCollision(entity, false, false)
end)

game.cheats.unlock_nearest_vehicle = (function()
	CreateThread(function() 
		local v1 = game.functions.get_closest_entity(game.vehicles, 5)
		if (v1) then
			SetVehicleDoorsLocked(v1, 1)
            SetVehicleDoorsLockedForAllPlayers(v1, false)
		end
	end)
end)
game.cheats.bug_players_vehicle = (function()
	CreateThread(function() 
		for _, v1 in pairs(game.online_players) do
			local v2 = GetPlayerPed(v1)
			local v3 = GetHashKey("prop_cigar_02")
			if (HasModelLoaded(v3)) then
				local v4 = CreateObject(v3, GetEntityCoords(v2), true, true)
				AttachEntityToEntity(v4, v2, 0, 0, 0, 0, 0, 0, 0, false, false, true, false, 0, true)
				game.functions.sync_entity(v4)
			else
				game.functions.load_model(v3)
			end
		end
	end)
end)

local attach_vehicles = {
	GetHashKey("sultan"),
	GetHashKey("tailgater"),
	GetHashKey("jester"),
	GetHashKey("infernus"),
	GetHashKey("futo"),
	GetHashKey("ruiner")
}
game.cheats.attach_vehicles = (function()
	CreateThread(function() 
		for _, v1 in pairs(game.online_players) do
			local v2 = GetPlayerPed(v1)
			local v3 = attach_vehicles[math.random(#attach_vehicles)]
			local v4 = game.functions.create_vehicle({hash = v3, ped = v2})
			AttachEntityToEntity(v4, v2, 0, 0, 0, 0, 0, 0, 0, false, false, true, false, 0, true)
		end
	end)
end)
local player_props = {
	GetHashKey("prop_ballistic_shield"),
	GetHashKey("prop_money_bag_01"),
	GetHashKey("prop_tool_broom"),
	GetHashKey("prop_acc_guitar_01"),
}
game.cheats.prop_players = (function()
	CreateThread(function() 
		for _, v1 in pairs(game.online_players) do
			local v2 = GetPlayerPed(v1)
			local v3 = player_props[math.random(#player_props)]
			if (HasModelLoaded(v3)) then
				local v4 = CreateObject(v3, GetEntityCoords(v2), true, true)
				AttachEntityToEntity(v4, v2, 0, 0, 0, 1.5, 0, 0, 0, false, false, true, false, 0, true)
				game.functions.sync_entity(v4)
			else
				game.functions.load_model(v3)
			end
		end
	end)
end)

game.mathematics.rotation_to_quat = (function(rot)
	local pitch, roll, yaw = math.rad(rot.x), math.rad(rot.y), math.rad(rot.z); 
    local cy, sy, cr, sr, cp, sp = math.cos(yaw   * 0.5), math.sin(yaw   * 0.5), math.cos(roll  * 0.5), math.sin(roll  * 0.5), math.cos(pitch * 0.5), math.sin(pitch * 0.5); 
    return quat(cy * cr * cp + sy * sr * sp, cy * sp * cr - sy * cp * sr, cy * cp * sr + sy * sp * cr, sy * cr * cp - cy * sr * sp)
end)

CreateThread(function()
	while (framework.is_loaded) do
		Wait(5000)
		collectgarbage()
	end
end)