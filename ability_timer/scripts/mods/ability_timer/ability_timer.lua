local mod = get_mod("ability_timer")

mod.tracked_deployables = mod.tracked_deployables or {}

mod:io_dofile("ability_timer/scripts/mods/ability_timer/ability_state")

local packages_to_load = {
	"packages/ui/hud/player_buffs/player_buffs",
	"packages/ui/hud/player_ability/player_ability",
}

mod.on_enabled = function()
	for _, package_path in ipairs(packages_to_load) do
		Managers.package:load(package_path, mod:get_name(), nil, true)
	end

	mod:register_hud_element({
		class_name = "HudElementAbilityTimerText",
		filename = "ability_timer/scripts/mods/ability_timer/hud/HudElementAbilityTimerText",
		visibility_groups = { "alive" },
		use_hud_scale = false,
	})

	mod:register_hud_element({
		class_name = "HudElementAbilityTimerBar",
		filename = "ability_timer/scripts/mods/ability_timer/hud/HudElementAbilityTimerBar",
		visibility_groups = { "alive" },
		use_hud_scale = false,
	})

	mod:register_hud_element({
		class_name = "HudElementAbilityTimerHealth",
		filename = "ability_timer/scripts/mods/ability_timer/hud/HudElementAbilityTimerHealth",
		visibility_groups = { "alive" },
		use_hud_scale = false,
	})

	mod:register_hud_element({
		class_name = "HudElementAbilityTimerCharges",
		filename = "ability_timer/scripts/mods/ability_timer/hud/HudElementAbilityTimerCharges",
		visibility_groups = { "alive" },
		use_hud_scale = false,
	})
end

mod.on_setting_changed = function(setting_id)
	local ui_manager = Managers.ui
	if not ui_manager then return end
	local hud = ui_manager._hud
	if not hud or not hud._elements then return end

	local text = hud._elements["HudElementAbilityTimerText"]
	local bar = hud._elements["HudElementAbilityTimerBar"]
	local health = hud._elements["HudElementAbilityTimerHealth"]
	local charges = hud._elements["HudElementAbilityTimerCharges"]

	if setting_id == "show_native_hud" and not mod:get("show_native_hud") then
		if text then text:_set_visible(false) end
		if bar then bar:_set_visible(false) end
		if health then health:_set_visible(false) end
		if charges then charges:_set_visible(false) end
		return
	end

	if text then
		text:set_scenegraph_position("root", 600 + (mod:get("timer_position_x") or 0), 620 + (mod:get("timer_position_y") or 0), 100)
	end
	
	if bar then
		bar:set_scenegraph_position("root", 600 + (mod:get("bar_position_x") or 0), 653.6 + (mod:get("bar_position_y") or 0), 100)
	end
	
	if health then
		health:set_scenegraph_position("root", 600 + (mod:get("health_position_x") or 0), 674 + (mod:get("health_position_y") or 0), 100)
	end
	
	if charges then
		charges:set_scenegraph_position("root", 695 + (mod:get("charges_position_x") or 0), 620 + (mod:get("charges_position_y") or 0), 100)
	end
end

local COMBAT_ABILITY = "combat_ability"

local function _add_deployable(unit, name, duration, icon, game_session, game_object_id, max_health)
    if not unit then return end

    local player = Managers.player and Managers.player:local_player(1)
    local player_unit = player and player.player_unit
    local ability_extension = player_unit and ScriptUnit.has_extension(player_unit, "ability_system")
    local remaining_charges = ability_extension and ability_extension:remaining_ability_charges(COMBAT_ABILITY)
    local raw_max = ability_extension and ability_extension:max_ability_charges(COMBAT_ABILITY)
    local max_charges = (raw_max and raw_max > 0) and raw_max or 1

    local used_slots = {}
    for _, d in pairs(mod.tracked_deployables) do
        if d.slot then
            used_slots[d.slot] = true
        end
    end

    local assigned_slot
    if remaining_charges and max_charges > 1 then
        assigned_slot = math.clamp(math.floor(remaining_charges + 0.0001) + 1, 1, max_charges)
    else
        assigned_slot = max_charges
    end

    if used_slots[assigned_slot] then
        assigned_slot = max_charges
        while assigned_slot > 1 and used_slots[assigned_slot] do
            assigned_slot = assigned_slot - 1
        end
        if used_slots[assigned_slot] then
            assigned_slot = 1
            while used_slots[assigned_slot] do
                assigned_slot = assigned_slot + 1
            end
        end
    end

    mod.tracked_deployables[unit] = {
        name = name,
        start_time = Managers.time:time("gameplay"),
        duration = duration,
        icon = icon,
        game_session = game_session,
        game_object_id = game_object_id,
        max_health = max_health,
        current_health = max_health,
        damage_taken = 0,
        last_poll_time = -math.huge,
        slot = assigned_slot,
    }
end

local function _remove_deployable(unit)
    if not unit then return end
    mod.tracked_deployables[unit] = nil
end

mod:hook_safe("PsykerForceFieldUnitExtension", "init", function(self, context, unit, extension_init_data, game_session, game_object_id)
    local owner_unit = self.owner_unit or extension_init_data.owner_unit
    local local_player = Managers.player:local_player(1)

    if local_player and owner_unit == local_player.player_unit then
        local icon = "content/ui/textures/icons/abilities/hud/psyker/psyker_ability_force_field"
        local talent_settings = require("scripts/settings/talent/talent_settings")
        local shield_settings = talent_settings.psyker_3.combat_ability
        local is_bubble = self:is_sphere_shield()
        local max_health = is_bubble and shield_settings.sphere_health or shield_settings.health

        _add_deployable(unit, "psyker_shield", self._max_duration or 20, icon, game_session, game_object_id, max_health)
    end
end)

mod:hook_safe("PsykerForceFieldUnitExtension", "on_death", function(self)
    _remove_deployable(self._unit)
end)

mod:hook_safe("PsykerForceFieldUnitExtension", "destroy", function(self)
    _remove_deployable(self._unit)
end)

mod:hook_safe("PsykerForceFieldUnitExtension", "game_object_initialized", function(self, session, object_id)
    local deployable = mod.tracked_deployables[self._unit]
    if deployable and deployable.name == "psyker_shield" then
        deployable.game_session = session
        deployable.game_object_id = object_id
    end
end)

mod:hook_safe("UnitSpawnerManager", "spawn_husk_unit", function(self, game_object_id, owner_id)
    local session = self._game_session
    local unit = self._network_units[game_object_id]
    if not unit then return end

    local local_player = Managers.player:local_player(1)
    if not local_player then return end

    local unit_template_id = GameSession.game_object_field(session, game_object_id, "unit_template")
    local unit_template_name = self._unit_template_network_lookup[unit_template_id]

    if unit_template_name == "broker_stimm_field_crate_deployable" then
        local owner_unit_id = GameSession.game_object_field(session, game_object_id, "owner_unit_id")
        if owner_unit_id ~= NetworkConstants.invalid_game_object_id then
            local owner_unit = Managers.state.unit_spawner:unit(owner_unit_id)
            if owner_unit and owner_unit == local_player.player_unit then
                local talent_settings = require("scripts/settings/talent/talent_settings")
                local ability_settings = talent_settings.broker.combat_ability.stimm_field
                local lifetime = ability_settings.life_time

                local owner_talent_extension = ScriptUnit.has_extension(owner_unit, "talent_system")
                if owner_talent_extension and owner_talent_extension:has_special_rule("broker_stimm_field_linger") then
                    lifetime = ability_settings.sub_1_life_time
                end

                _add_deployable(unit, "broker_stimm_field", lifetime, "content/ui/textures/icons/buffs/hud/broker/broker_stimm_field")
            end
        end

    elseif unit_template_name == "item_deployable_projectile" then
        local owner_unit_id = GameSession.game_object_field(session, game_object_id, "owner_unit_id")
        if owner_unit_id ~= NetworkConstants.invalid_game_object_id then
            local owner_unit = Managers.state.unit_spawner:unit(owner_unit_id)
            if owner_unit and owner_unit == local_player.player_unit then
                local item_id = GameSession.game_object_field(session, game_object_id, "item_id")
                local item_name = NetworkLookup.player_item_names[item_id]

                if item_name == "content/items/weapons/player/drone_area_buff" then
                    _add_deployable(unit, "adamant_drone", 20, "content/ui/textures/icons/abilities/hud/adamant/adamant_ability_area_buff_drone")
                end
            end
        end
    end
end)

mod:hook_safe("UnitSpawnerManager", "_remove_network_unit", function(self, unit)
    _remove_deployable(unit)
end)

mod:hook_safe("ProximityBrokerStimmField", "init", function(self, context, init_data, owner_unit)
    local local_player = Managers.player and Managers.player:local_player(1)
    if local_player and owner_unit == local_player.player_unit then
        _add_deployable(self._unit, "broker_stimm_field", self._life_time, "content/ui/textures/icons/buffs/hud/broker/broker_stimm_field")
    end
end)

mod:hook_safe("ProximityAreaBuffDrone", "init", function(self, context, init_data, owner_unit)
    local local_player = Managers.player and Managers.player:local_player(1)
    if local_player and owner_unit == local_player.player_unit then
        _add_deployable(self._unit, "adamant_drone", self._life_time, "content/ui/textures/icons/abilities/hud/adamant/adamant_ability_area_buff_drone")
    end
end)

local POLL_INTERVAL = 0.05

local function _update_bubble_health(unit, health_extension, game_session, game_object_id, is_server)
    local deployable = mod.tracked_deployables[unit]
    if not deployable or deployable.name ~= "psyker_shield" then return end

    if not is_server then
        if game_session and game_object_id then
            deployable.current_health = GameSession.game_object_field(game_session, game_object_id, "health") or deployable.max_health
        end
    else
        if health_extension then
            deployable.current_health = health_extension:current_health() or deployable.max_health
        end
    end

    deployable.damage_taken = math.max(0, deployable.max_health - deployable.current_health)
end

mod:hook_safe("PsykerForceFieldUnitHealthExtension", "_add_damage", function(self, damage)
    local unit = self._unit
    local deployable = mod.tracked_deployables[unit]
    if deployable and deployable.name == "psyker_shield" then
        _update_bubble_health(unit, self, self._game_session, self._game_object_id, true)
    end
end)

mod:hook_safe("PsykerForceFieldUnitExtension", "fixed_update", function(self, unit, dt, t)
    local deployable = mod.tracked_deployables[unit]
    if not deployable or deployable.name ~= "psyker_shield" then return end
    if (t - deployable.last_poll_time) <= POLL_INTERVAL then return end

    _update_bubble_health(unit, self._health_extension, self._game_session, self._game_object_id, self._is_server)
    deployable.last_poll_time = t
end)

mod.on_all_mods_loaded = function()
	local hud_studio = get_mod("hud_studio")
	if not hud_studio then return end

	hud_studio.register_blocks(mod, {
		author = "IndicaBunny",
		blocks = {
			"scripts/mods/ability_timer/blocks/at_timer",
			"scripts/mods/ability_timer/blocks/at_bar",
			"scripts/mods/ability_timer/blocks/at_bracket",
			"scripts/mods/ability_timer/blocks/at_charges",
			"scripts/mods/ability_timer/blocks/at_bubble_health",
		},
	})

	local Straight = hud_studio.hud_studio_progress_bar_straight
	local DrawCalls = hud_studio.draw_calls
	if Straight and DrawCalls then
		mod:hook(Straight, "draw", function(func, ctx, ...)
			local at_state = mod.get_ability_state()
			local seg_colors = ctx.fill_color and ctx.fill_color._at_segment_colors
			local seg_fractions = ctx.fill_color and ctx.fill_color._at_segment_fractions
			local notches_per_seg = at_state and at_state.notches_per_seg or 0

			if (not seg_colors or #seg_colors <= 1) and notches_per_seg <= 0 then
				return func(ctx, ...)
			end

			local d = DrawCalls.bind(ctx.ui_renderer)
			local orig_rect = d.rect
			local orig_tex = d.texture

			local vertical = ctx.orientation == "top_bottom" or ctx.orientation == "bottom_top" or ctx.orientation == "center_vertical"
			local axis_len = vertical and ctx.h or ctx.w
			local num_segs = ctx.segments or 1
			local is_center = ctx.orientation == "center" or ctx.orientation == "center_vertical"
			local draw_segs = is_center and (num_segs * 2) or num_segs

			local gap_px = (draw_segs > 1 and axis_len > 0) and (ctx.segment_gap * ctx.scale) or 0
			local cell_len = (axis_len - (draw_segs - 1) * gap_px) / draw_segs
			local cell_stride = cell_len + gap_px
			if cell_stride <= 0 then
				cell_stride = 1
			end

			local rot = tonumber(ctx.rotation) or 0
			local has_rot = rot ~= 0
			local ca, sa, px, py
			if has_rot then
				local rad = math.rad(rot)
				ca, sa = math.cos(rad), math.sin(rad)
				px, py = ctx.x + ctx.w * 0.5, ctx.y + ctx.h * 0.5
			end

			local u0 = vertical and ((ctx.orientation == "bottom_top") and (ctx.y + ctx.h) or ctx.y)
				or ((ctx.orientation == "right_left") and (ctx.x + ctx.w) or ctx.x)
			local u1 = vertical and ((ctx.orientation == "bottom_top") and ctx.y or (ctx.y + ctx.h))
				or ((ctx.orientation == "right_left") and ctx.x or (ctx.x + ctx.w))

			local function _get_seg_color(rx, ry, rw, rh)
				local mx = rx + rw * 0.5
				local my = ry + rh * 0.5
				if has_rot then
					local dx, dy = mx - px, my - py
					mx = px + dx * ca + dy * sa
					my = py + dy * ca - dx * sa
				end
				local mid = vertical and my or mx
				local dist = (u1 < u0) and (u0 - mid) or (mid - u0)
				local idx = math.clamp(math.floor(dist / cell_stride) + 1, 1, draw_segs)
				if is_center then
					idx = math.clamp(math.floor(math.abs(idx - (num_segs + 0.5))) + 1, 1, num_segs)
				end
				local c = seg_colors and seg_colors[idx]
				return c and { ctx.fill_color[1] or 255, c[2], c[3], c[4] }
			end

			local has_multi_frac = seg_fractions and #seg_fractions > 1
			local saved_frac = ctx.fraction

			if has_multi_frac then
				ctx.fraction = 0
			elseif seg_colors and #seg_colors > 1 then
				d.rect = function(self, rx, ry, rz, rw, rh, color, r)
					return orig_rect(self, rx, ry, rz, rw, rh, (color == ctx.fill_color and _get_seg_color(rx, ry, rw, rh)) or color, r)
				end
				d.texture = function(self, mat, rx, ry, rz, rw, rh, color, uv, r, hold)
					return orig_tex(self, mat, rx, ry, rz, rw, rh, (color == ctx.fill_color and _get_seg_color(rx, ry, rw, rh)) or color, uv, r, hold)
				end
			end

			local res = func(ctx, ...)
			ctx.fraction = saved_frac

			d.rect = orig_rect
			d.texture = orig_tex

			if has_multi_frac then
				for j = 0, draw_segs - 1 do
					local seg_idx = is_center and (math.clamp(math.floor(math.abs(j - (num_segs - 0.5))) + 1, 1, num_segs)) or (j + 1)
					local s_frac = math.clamp(seg_fractions[seg_idx] or 0, 0, 1)
					if s_frac > 0 then
						local s_color = seg_colors and seg_colors[seg_idx] or ctx.fill_color
						local c = { ctx.fill_color[1] or 255, s_color[2], s_color[3], s_color[4] }
						local fill_len = cell_len * s_frac
						local seg_pos = (vertical and ctx.y or ctx.x) + j * cell_stride

						local fill_start = seg_pos
						if vertical then
							if ctx.orientation == "bottom_top" then
								fill_start = seg_pos + (cell_len - fill_len)
							elseif ctx.orientation == "center_vertical" then
								fill_start = seg_pos + math.floor((cell_len - fill_len) * 0.5)
							end
						else
							if ctx.orientation == "right_left" then
								fill_start = seg_pos + (cell_len - fill_len)
							elseif ctx.orientation == "center" then
								fill_start = seg_pos + math.floor((cell_len - fill_len) * 0.5)
							end
						end

						local rx = vertical and ctx.x or fill_start
						local ry = vertical and fill_start or ctx.y
						local rw = vertical and ctx.w or fill_len
						local rh = vertical and fill_len or ctx.h

						if has_rot then
							local ox = rx + rw * 0.5 - px
							local oy = ry + rh * 0.5 - py
							rx = px + (ox * ca + oy * sa) - rw * 0.5
							ry = py + (oy * ca - ox * sa) - rh * 0.5
						end

						orig_rect(d, rx, ry, ctx.z + 1, rw, rh, c, rot)
					end
				end
			end

			if notches_per_seg > 0 then
				local notch_c = at_state.notch_color or { 255, 88, 99, 80 }
				local notch_alpha = (ctx.fill_color and ctx.fill_color[1] or 255) / 255
				local notch_color = { (notch_c[1] or 255) * notch_alpha, notch_c[2], notch_c[3], notch_c[4] }

				local ui_scale = (RESOLUTION_LOOKUP and RESOLUTION_LOOKUP.scale) or 1
				local desired_notch_px = math.max(1, math.round((at_state.notch_width or 2) * (ctx.scale or 1)))
				local notch_thick = desired_notch_px / ui_scale
				local notch_len = math.max(2, math.floor((vertical and ctx.w or ctx.h) * (at_state.notch_len_pct or 0.5)))
				local rw = vertical and notch_len or notch_thick
				local rh = vertical and notch_thick or notch_len

				for j = 0, draw_segs - 1 do
					local seg_pos = (vertical and ctx.y or ctx.x) + j * cell_stride
					for k = 1, notches_per_seg do
						local raw_pos = seg_pos + math.floor((k / (notches_per_seg + 1)) * cell_len)
						local screen_axis = math.floor(raw_pos * ui_scale + 0.5) - math.floor(desired_notch_px * 0.5)
						local snapped_pos = screen_axis / ui_scale

						local rx = vertical and ctx.x or snapped_pos
						local ry = vertical and snapped_pos or ctx.y

						if has_rot then
							local ox = rx + rw * 0.5 - px
							local oy = ry + rh * 0.5 - py
							rx = px + (ox * ca + oy * sa) - rw * 0.5
							ry = py + (oy * ca - ox * sa) - rh * 0.5
						end

						d:rect(rx, ry, ctx.z + 5, rw, rh, notch_color, rot)
					end
				end
			end

			return res
		end)
	end

	local Ring = hud_studio.hud_studio_progress_bar_ring
	if Ring and DrawCalls then
		mod:hook(Ring, "draw", function(func, ctx, ...)
			local seg_colors = ctx.fill_color and ctx.fill_color._at_segment_colors
			local seg_fractions = ctx.fill_color and ctx.fill_color._at_segment_fractions
			if not seg_colors or #seg_colors <= 1 then
				return func(ctx, ...)
			end

			local d = DrawCalls.bind(ctx.ui_renderer)
			local orig_tex = d.texture
			local fill_call = 0

			d.texture = function(self, mat, rx, ry, rz, rw, rh, color, uv, rot, hold)
				if rz == ctx.z + 1 and color == ctx.fill_color then
					fill_call = fill_call + 1
					local c = seg_colors[fill_call]
					if c then
						color = { ctx.fill_color[1] or 255, c[2], c[3], c[4] }
					end
					if seg_fractions and seg_fractions[fill_call] then
						local f = seg_fractions[fill_call]
						if f <= 0 then
							return
						elseif f < 1 and rh then
							local old_h = rh
							rh = old_h * f
							ry = ry + (old_h - rh) * 0.5
						end
					end
				end
				return orig_tex(self, mat, rx, ry, rz, rw, rh, color, uv, rot, hold)
			end

			local saved_frac = ctx.fraction
			if seg_fractions and #seg_fractions > 1 then
				ctx.fraction = 1.0
			end

			local res = func(ctx, ...)
			ctx.fraction = saved_frac
			d.texture = orig_tex
			return res
		end)
	end

	local Curved = hud_studio.hud_studio_progress_bar_curved
	local CompositeMaterial = hud_studio.hud_studio_composite_material
	if Curved and CompositeMaterial then
		mod:hook(Curved, "draw", function(func, ctx, ...)
			local seg_colors = ctx.fill_color and ctx.fill_color._at_segment_colors
			local seg_fractions = ctx.fill_color and ctx.fill_color._at_segment_fractions
			if not seg_colors or #seg_colors <= 1 then
				return func(ctx, ...)
			end

			local orig_resolve = CompositeMaterial.resolve
			local fill_count = 0
			local num_segs = ctx.segments or 1
			local active_seg = math.clamp(math.floor((ctx.fraction or 0) * num_segs) + 1, 1, num_segs)

			CompositeMaterial.resolve = function(ui_renderer, descriptor)
				if descriptor and type(descriptor.values) == "table" and descriptor.values.fillcolor then
					local target_idx = nil
					if not descriptor.outline_silenced then
						fill_count = fill_count + 1
						target_idx = fill_count
					elseif fill_count >= num_segs then
						target_idx = active_seg
					end

					if target_idx then
						if seg_fractions and seg_fractions[target_idx] then
							descriptor.values.amount = seg_fractions[target_idx]
						end
						local c = seg_colors[target_idx]
						if c then
							local slot = descriptor.values.fillcolor
							slot[1] = math.clamp((c[2] or 255) / 255, 0.1, 1)
							slot[2] = math.clamp((c[3] or 255) / 255, 0.1, 1)
							slot[3] = math.clamp((c[4] or 255) / 255, 0.1, 1)
							slot[4] = 1

							local render_settings = ui_renderer.render_settings
							local fade = (render_settings and render_settings.alpha_multiplier) or 1
							local alpha = (ctx.fill_color[1] or 255) / 255
							descriptor.values.fill_outline_opacity[1] = 1.3 * alpha * fade
						end
					end
				end

				return orig_resolve(ui_renderer, descriptor)
			end

			local res = func(ctx, ...)
			CompositeMaterial.resolve = orig_resolve
			return res
		end)
	end

end
