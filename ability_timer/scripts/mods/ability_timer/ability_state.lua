local mod = get_mod("ability_timer")

local TalentSettings = require("scripts/settings/talent/talent_settings")

local COMBAT_ABILITY = "combat_ability"
local MIN_TIME = 0.05

local ABILITY_GROUPS = {
	veteran = {
		volley_fire_stance = { setting_id = "veteran_ability_stance", buff_templates = { "veteran_combat_ability_stance_master", "veteran_combat_ability_stance_master_increased_duration" } },
		veteran_stealth = { setting_id = "veteran_ability_stealth", buff_templates = { "veteran_invisibility", "veteran_damage_bonus_leaving_invisibility", "veteran_toughness_bonus_leaving_invisibility" } },
		voice_of_command = { setting_id = "veteran_ability_shout", buff_templates = { "veteran_combat_ability_increase_toughness_to_coherency" } },
	},
	zealot = {
		zealot_dash = { setting_id = "zealot_ability_dash", buff_templates = { "zealot_dash_buff", "zealot_combat_ability_attack_speed_increase", "zealot_combat_ability_attack_speed_increased_duration" } },
		bolstering_prayer = { setting_id = "zealot_ability_relic", buff_templates = { "zealot_channel_toughness_bonus", "zealot_channel_damage", "zealot_channel_toughness_damage_reduction" } },
		zealot_invisibility = { setting_id = "zealot_ability_invisibility", buff_templates = { "zealot_invisibility", "zealot_invisibility_increased_duration", "zealot_leaving_stealth_restores_toughness", "zealot_stealth_improved_with_block", "zealot_decrease_threat_increase_backstab_damage" } },
	},
	psyker = {
		psyker_shout = { setting_id = "psyker_ability_shout", buff_templates = { "psyker_shout_warp_generation_reduction" } },
		psyker_shield = { setting_id = "psyker_ability_shield", buff_templates = nil },
		psyker_overcharge_stance = { setting_id = "psyker_ability_overcharge", buff_templates = { "psyker_overcharge_stance_damage", "psyker_overcharge_stance_finesse_damage", "psyker_overcharge_stance_infinite_casting", "psyker_overcharge_stance_cool_off" } },
	},
	ogryn = {
		ogryn_charge = { setting_id = "ogryn_ability_charge", buff_templates = { "ogryn_charge_speed_on_lunge" } },
		ogryn_gunlugger_stance = { setting_id = "ogryn_ability_ranged_stance", buff_templates = { "ogryn_ranged_stance" } },
		ogryn_taunt_shout = { setting_id = "ogryn_ability_taunt", buff_templates = { "ogryn_repeat_taunt" } },
	},
	adamant = {
		adamant_shout = { setting_id = "arbites_ability_shout", buff_templates = nil },
		adamant_charge = { setting_id = "arbites_ability_charge", buff_templates = { "adamant_post_charge_buff" } },
		adamant_stance = { setting_id = "arbites_ability_stance", buff_templates = { "adamant_hunt_stance" } },
		adamant_area_buff_drone = { setting_id = "arbites_ability_drone", buff_templates = nil },
	},
	broker = {
		broker_focus_stance = { setting_id = "broker_ability_focus", buff_templates = { "broker_focus_stance", "broker_focus_stance_improved" } },
		broker_punk_rage_stance = { setting_id = "broker_ability_punk_rage", buff_templates = { "broker_punk_rage_stance" } },
		broker_stimm_field = { setting_id = "broker_ability_stimm_field", buff_templates = nil },
	},
	cryptic = {
		cryptic_discharge = { setting_id = "cryptic_ability_discharge", buff_templates = { "cryptic_discharge_weapon_shock_effect", "cryptic_discharge_attack_speed_increase" } },
		cryptic_precision_stance = { setting_id = "cryptic_ability_precision_stance", buff_templates = { "cryptic_precision_stance_one_charge", "cryptic_precision_stance_two_charges", "cryptic_precision_stance_three_charges" } },
		cryptic_chordclaw = { setting_id = "cryptic_ability_chordclaw", buff_templates = nil },
	},
}

local CLASS_SETTINGS = {
	veteran = "show_veteran",
	zealot = "show_zealot",
	psyker = "show_psyker",
	ogryn = "show_ogryn",
	adamant = "show_arbites",
	broker = "show_broker",
	cryptic = "show_cryptic",
}

local bar_color = { 255, 17, 90, 239 }
local text_color = { 255, 17, 90, 239 }
local charges_color = { 255, 17, 90, 239 }
local bubble_color = { 255, 17, 90, 239 }

local state = {
	bar_visible = false,
	timer_visible = false,
	remaining = 0,
	duration = 0,
	fraction = 0,
	timer_text = "",
	mode = nil,
	bar_color = bar_color,
	text_color = text_color,
	charges_visible = false,
	charges = 0,
	max_charges = 1,
	segments = 1,
	segment_gap = 3,
	bar_notches = 0,
	charge_progress = 0,
	charges_color = charges_color,
	bubble_visible = false,
	bubble_percent = 0,
	bubble_text = "",
	bubble_color = bubble_color,
}

local last_resolve_time = nil
local cooldown_start_value = nil
local charge_cooldown_start = nil
local slot_last_active_time = {}
local slot_cooldown_start = {}

local function _apply_progress_color(frac, color)
	local clamped = math.max(0, math.min(1, frac or 0))
	local c_high = mod:get("high_color") or { 255, 80, 145, 255 }
	local c_mid = mod:get("mid_color") or { 255, 255, 115, 80 }
	local c_low = mod:get("low_color") or { 255, 249, 69, 69 }

	if clamped < 0.5 then
		local t = clamped / 0.5
		color[2] = math.floor(c_low[2] + (c_mid[2] - c_low[2]) * t + 0.5)
		color[3] = math.floor(c_low[3] + (c_mid[3] - c_low[3]) * t + 0.5)
		color[4] = math.floor(c_low[4] + (c_mid[4] - c_low[4]) * t + 0.5)
	else
		local t = (clamped - 0.5) / 0.5
		color[2] = math.floor(c_mid[2] + (c_high[2] - c_mid[2]) * t + 0.5)
		color[3] = math.floor(c_mid[3] + (c_high[3] - c_mid[3]) * t + 0.5)
		color[4] = math.floor(c_mid[4] + (c_high[4] - c_mid[4]) * t + 0.5)
	end
end

local function _apply_peril_color(frac, color)
	local clamped = math.max(0, math.min(1, frac or 0))
	local c_low = mod:get("peril_low_color") or { 255, 255, 105, 180 }
	local c_high = mod:get("peril_high_color") or { 255, 249, 69, 69 }

	color[2] = math.floor(c_low[2] + (c_high[2] - c_low[2]) * clamped + 0.5)
	color[3] = math.floor(c_low[3] + (c_high[3] - c_low[3]) * clamped + 0.5)
	color[4] = math.floor(c_low[4] + (c_high[4] - c_low[4]) * clamped + 0.5)
end

local function _apply_cooldown_color(frac, color)
	local clamped = math.max(0, math.min(1, frac or 0))
	local c_low = mod:get("cooldown_low_color") or { 255, 80, 70, 254 }
	local c_high = mod:get("cooldown_high_color") or { 255, 120, 70, 255 }

	color[2] = math.floor(c_low[2] + (c_high[2] - c_low[2]) * clamped + 0.5)
	color[3] = math.floor(c_low[3] + (c_high[3] - c_low[3]) * clamped + 0.5)
	color[4] = math.floor(c_low[4] + (c_high[4] - c_low[4]) * clamped + 0.5)
end

local function _get_remaining_ability_cooldown(ability_extension)
	if ability_extension:is_ability_resource_regen_paused(COMBAT_ABILITY) then
		return 0
	end

	return ability_extension:missing_ability_resource_until_next_charge(COMBAT_ABILITY) or 0
end

local function _get_max_ability_cooldown(ability_extension)
	if ability_extension:uses_ability_charges(COMBAT_ABILITY) then
		local max_time = ability_extension:max_regen_time_for_ability_charge(COMBAT_ABILITY)
		if max_time and max_time > 0 then
			return max_time
		end
		return ability_extension:get_ability_resource_cost_per_charge(COMBAT_ABILITY)
	end

	return ability_extension:max_ability_resource(COMBAT_ABILITY)
end

local function _get_buff_remaining_time(buff_extension, buff_template_names)
	local buffs_by_index = buff_template_names and buff_extension._buffs_by_index
	if not buffs_by_index then
		return nil, nil
	end

	local best_remaining, best_duration
	for _, buff in pairs(buffs_by_index) do
		local template = buff:template()
		local template_name = template and template.name
		if template_name then
			for i = 1, #buff_template_names do
				if template_name == buff_template_names[i] then
					if not buff._in_invisibility then
						local progress = buff:duration_progress() or 1
						local duration = buff:duration() or template.duration or template.active_duration or 0
						local remaining = duration * progress
						if not best_remaining or remaining > best_remaining then
							best_remaining = remaining
							best_duration = duration
						end
					end
					break
				end
			end
		end
	end

	return best_remaining, best_duration
end

local function _get_active_deployables()
	local deployables = mod.tracked_deployables
	if not deployables then
		return {}
	end

	local time_manager = Managers.time
	if not time_manager or not time_manager:has_timer("gameplay") then
		return {}
	end

	local t = time_manager:time("gameplay")
	local active = {}
	for unit, data in pairs(deployables) do
		local remaining = data.duration - (t - data.start_time)
		if remaining > 0 then
			active[#active + 1] = {
				unit = unit,
				data = data,
				remaining = remaining,
				duration = data.duration,
				fraction = math.clamp(remaining / data.duration, 0, 1),
				start_time = data.start_time,
			}
		else
			deployables[unit] = nil
		end
	end

	table.sort(active, function(a, b)
		return a.start_time < b.start_time
	end)

	local num_segs = state.segments or 2
	for i = 1, #active do
		local d = active[i]
		local s = math.min(i, num_segs)
		d.data.slot = s
		d.slot = s
	end

	return active
end

local function _resolve_bubble(active_deployables)
	if mod:get("show_bubble_health") == false then return end
	if not active_deployables or #active_deployables == 0 then return end

	local bubble_list = {}
	local lowest_pct = 101
	local any_bubble = false

	for i = 1, #active_deployables do
		local d = active_deployables[i]
		local data = d.data
		if data and data.name == "psyker_shield" and data.max_health and data.max_health > 0 then
			any_bubble = true
			local pct = math.clamp(math.floor((data.current_health / data.max_health) * 100), 0, 100)
			table.insert(bubble_list, {
				slot = d.slot or data.slot or i,
				pct = pct,
				start_time = d.start_time or (data and data.start_time) or 0,
			})
			if pct < lowest_pct then
				lowest_pct = pct
			end
		end
	end

	if not any_bubble then return end

	state.bubble_visible = true
	state.bubble_percent = lowest_pct

	table.sort(bubble_list, function(a, b)
		return a.start_time < b.start_time
	end)

	local mode = mod:get("bubble_health_mode") or "both"
	if mode == "newest" and #bubble_list > 1 then
		bubble_list = { bubble_list[#bubble_list] }
	elseif mode == "lowest" and #bubble_list > 1 then
		local lowest_bubble = bubble_list[1]
		for i = 2, #bubble_list do
			if bubble_list[i].pct < lowest_bubble.pct then
				lowest_bubble = bubble_list[i]
			end
		end
		bubble_list = { lowest_bubble }
	elseif mode == "oldest" and #bubble_list > 1 then
		bubble_list = { bubble_list[1] }
	end

	local use_color = mod:get("use_progress_color_text") ~= false

	local function _get_bubble_c(pct)
		local c = { 255, 17, 90, 239 }
		if use_color then
			_apply_progress_color(pct / 100, c)
		else
			local custom = mod:get("text_color") or { 255, 17, 90, 239 }
			c[2], c[3], c[4] = custom[2], custom[3], custom[4]
		end
		return c
	end

	local parts = {}
	for i = 1, #bubble_list do
		local b = bubble_list[i]
		if use_color then
			local c = _get_bubble_c(b.pct)
			table.insert(parts, string.format("{#color(%d,%d,%d)}%d%%{#reset()}", c[2], c[3], c[4], b.pct))
		else
			table.insert(parts, string.format("%d%%", b.pct))
		end
	end
	state.bubble_text = table.concat(parts, " | ")

	if use_color and #bubble_list == 1 then
		local single_c = _get_bubble_c(bubble_list[1].pct)
		bubble_color[2], bubble_color[3], bubble_color[4] = single_c[2], single_c[3], single_c[4]
	else
		local custom = mod:get("text_color") or { 255, 17, 90, 239 }
		bubble_color[2], bubble_color[3], bubble_color[4] = custom[2], custom[3], custom[4]
	end
end

local function _resolve_charges(ability_extension)
	local max_charges = state.max_charges
	local charges = state.charges

	if mod:get("show_charges") == false then return end
	if max_charges <= 1 and mod:get("always_show_charges") == false then return end

	state.charges_visible = true

	if mod:get("use_progress_color_text") ~= false then
		local frac = (max_charges > 0) and (charges / max_charges) or 0
		local c_high = mod:get("high_color") or { 255, 80, 145, 255 }
		local c_mid = mod:get("mid_color") or { 255, 255, 115, 80 }
		local c_low = mod:get("low_color") or { 255, 249, 69, 69 }
		local src = (frac == 1 and c_high) or (frac == 0 and c_low) or c_mid
		charges_color[2], charges_color[3], charges_color[4] = src[2], src[3], src[4]
	else
		local custom = mod:get("text_color") or { 255, 17, 90, 239 }
		charges_color[2], charges_color[3], charges_color[4] = custom[2], custom[3], custom[4]
	end
end

local function _get_active_color(frac)
	local c = { 255, 17, 90, 239 }
	if mod:get("use_progress_color") ~= false then
		_apply_progress_color(frac, c)
	else
		local custom = mod:get("bar_color") or { 255, 17, 90, 239 }
		c[2], c[3], c[4] = custom[2], custom[3], custom[4]
	end
	return c
end

local function _get_peril_color(frac)
	local c = { 255, 255, 255, 255 }
	if mod:get("scriers_use_progress_color") ~= false then
		_apply_peril_color(frac, c)
	else
		local custom = mod:get("scriers_static_color") or { 255, 255, 105, 180 }
		c[2], c[3], c[4] = custom[2], custom[3], custom[4]
	end
	return c
end

local function _get_cooldown_color(frac)
	local c = { 255, 255, 255, 255 }
	if mod:get("cooldown_use_progress_color") ~= false then
		_apply_cooldown_color(frac, c)
	else
		local custom = mod:get("cooldown_color") or { 255, 120, 70, 255 }
		c[2], c[3], c[4] = custom[2], custom[3], custom[4]
	end
	return c
end

local function _resolve_timer(player_unit, archetype_name, ability_group, tracked, ability_enabled, ability_extension, buff_extension, active_deployables)
	local use_scriers = archetype_name == "psyker"
		and ability_group == "psyker_overcharge_stance"
		and mod:get("use_scriers_gaze_bar") ~= false
		and buff_extension:has_buff_using_buff_template("psyker_overcharge_stance")

	if not ability_enabled and not use_scriers then return end

	local buff_remaining, buff_duration = _get_buff_remaining_time(buff_extension, tracked.buff_templates)
	local mode = "active"

	if archetype_name == "cryptic" and ability_group == "cryptic_precision_stance" then
		local has_stance_buff = false
		for i = 1, #tracked.buff_templates do
			if buff_extension:has_keyword("cryptic_precision_stance") or buff_extension:has_unique_buff_id(tracked.buff_templates[i]) then
				has_stance_buff = true
				break
			end
		end

		if has_stance_buff then
			local max_charges = ability_extension:max_ability_charges(COMBAT_ABILITY)
			local max_cooldown = _get_max_ability_cooldown(ability_extension)
			local total_cooldown = ability_extension:remaining_ability_resource(COMBAT_ABILITY)

			local precision_settings = TalentSettings.cryptic and TalentSettings.cryptic.precision_stance
			local drain_rate = precision_settings and precision_settings.cooldown_percent_lost_per_second or 0.1

			if max_cooldown and max_cooldown > 0 then
				buff_remaining = total_cooldown / (drain_rate * max_cooldown)
				buff_duration = max_charges / drain_rate
			end
		end
	elseif use_scriers then
		local unit_data_extension = ScriptUnit.has_extension(player_unit, "unit_data_system")
		local warp_charge_component = unit_data_extension and unit_data_extension:read_component("warp_charge")
		if warp_charge_component then
			buff_remaining = (warp_charge_component.current_percentage or 0) * 100
			buff_duration = 100
			mode = "peril"
		end
	end

	local uses_charges = ability_extension:uses_ability_charges(COMBAT_ABILITY)
	local missing_charge = _get_remaining_ability_cooldown(ability_extension)
	local missing_total = ability_extension:missing_ability_resource(COMBAT_ABILITY) or 0
	local max_charge_cd = _get_max_ability_cooldown(ability_extension)
	local charge_progress = ability_extension:get_ability_resource_regen_progress(COMBAT_ABILITY) or 0
	if ability_extension:is_ability_resource_regen_paused(COMBAT_ABILITY) then
		charge_progress = 0
	end

	local is_smooth = mod:get("cooldown_display_mode") ~= "full"
	if is_smooth then
		if not charge_cooldown_start or missing_charge > charge_cooldown_start then
			charge_cooldown_start = missing_charge
		end
	else
		charge_cooldown_start = nil
	end

	local current_charge_prog
	if is_smooth and charge_cooldown_start and charge_cooldown_start > 0 then
		current_charge_prog = math.clamp(1 - (missing_charge / charge_cooldown_start), 0, 1)
	else
		current_charge_prog = math.clamp(charge_progress, 0, 1)
	end
	state.charge_progress = current_charge_prog

	local has_cd = (mod:get("track_cooldown") ~= false) and missing_charge and (missing_charge > MIN_TIME)
	local num_active = active_deployables and #active_deployables or 0
	local has_buff = use_scriers or (buff_remaining and buff_remaining >= MIN_TIME)

	local max_charges = state.max_charges or 1
	local charges = state.charges or 0
	local num_segs = state.segments or 1

	if num_active >= 2 and num_segs < num_active then
		num_segs = num_active
		state.segments = num_segs
	end

	local ready_color = mod:get("ready_charge_color") or { 255, 17, 90, 239 }
	local cd_color = mod:get("cooldown_color") or { 255, 120, 70, 255 }

	local seg_fractions = {}
	local seg_colors = {}
	local display_remaining = nil
	local display_duration = nil

	local independent = mod:get("independent_charge_tracking") ~= false

	if independent and num_segs > 1 then
		local active_by_slot = {}
		for _, d in ipairs(active_deployables) do
			if d.slot then
				active_by_slot[d.slot] = d
			end
		end

		if has_buff then
			local b_slot = (num_segs > 1 and charges >= 1) and num_segs or 1
			if not active_by_slot[b_slot] then
				active_by_slot[b_slot] = {
					remaining = buff_remaining,
					duration = buff_duration,
					fraction = math.clamp(buff_remaining / buff_duration, 0, 1),
				}
			end
		end

		local t = (Managers.time and Managers.time:has_timer("gameplay")) and Managers.time:time("gameplay") or 0
		local any_active = false
		for s, d in pairs(active_by_slot) do
			slot_last_active_time[s] = t
			slot_cooldown_start[s] = nil
		end

		for i = 1, num_segs do
			if active_by_slot[i] then
				any_active = true
				local f = active_by_slot[i].fraction
				seg_fractions[i] = f
				seg_colors[i] = (use_scriers and _get_peril_color(f)) or _get_active_color(f)
				if not display_remaining or active_by_slot[i].remaining < display_remaining then
					display_remaining = active_by_slot[i].remaining
					display_duration = active_by_slot[i].duration
				end
			end
		end

		if any_active then
			mode = (use_scriers and "peril") or "active"
			state.timer_visible = true
			cooldown_start_value = nil
			charge_cooldown_start = nil
		end

		local free_slots = {}
		for i = 1, num_segs do
			if not active_by_slot[i] then
				free_slots[#free_slots + 1] = i
			end
		end

		if #free_slots > 0 then
			local ready_to_give = math.clamp(charges, 0, #free_slots)
			local ready_slot_map = {}

			for k = 1, ready_to_give do
				ready_slot_map[free_slots[k]] = true
			end

			local cd_given = false
			local cd_slot_used = nil
			for _, slot_idx in ipairs(free_slots) do
				if ready_slot_map[slot_idx] then
					slot_cooldown_start[slot_idx] = nil
					seg_fractions[slot_idx] = 1.0
					seg_colors[slot_idx] = { ready_color[1], ready_color[2], ready_color[3], ready_color[4] }
				elseif has_cd and not cd_given then
					cd_given = true
					cd_slot_used = slot_idx
					local s_prog
					if is_smooth then
						if not slot_cooldown_start[slot_idx] or missing_charge > slot_cooldown_start[slot_idx] then
							slot_cooldown_start[slot_idx] = missing_charge
						end
						s_prog = (slot_cooldown_start[slot_idx] > 0) and math.clamp(1 - (missing_charge / slot_cooldown_start[slot_idx]), 0, 1) or 0
					else
						slot_cooldown_start[slot_idx] = nil
						s_prog = (max_charge_cd > 0) and math.clamp(1 - (missing_charge / max_charge_cd), 0, 1) or math.clamp(charge_progress, 0, 1)
					end
					seg_fractions[slot_idx] = s_prog
					seg_colors[slot_idx] = _get_cooldown_color(s_prog)
				else
					slot_cooldown_start[slot_idx] = nil
					seg_fractions[slot_idx] = 0.0
					seg_colors[slot_idx] = _get_cooldown_color(0.0)
				end
			end

			if not any_active then
				if charges == max_charges then
					slot_last_active_time = {}
					slot_cooldown_start = {}
					cooldown_start_value = nil
					charge_cooldown_start = nil
				end

				if has_cd then
					mode = "cooldown"
					local target_timer = mod:get("cooldown_target_timer") or "next_charge"
					if target_timer == "until_full" and uses_charges and max_charges > 1 then
						display_remaining = missing_total
						if is_smooth then
							if not cooldown_start_value or missing_total > cooldown_start_value then
								cooldown_start_value = missing_total
							end
							display_duration = cooldown_start_value
						else
							cooldown_start_value = nil
							display_duration = max_charge_cd * max_charges
						end
					else
						display_remaining = missing_charge
						local cd_ref = (cd_slot_used and slot_cooldown_start[cd_slot_used]) or missing_charge
						if is_smooth then
							display_duration = cd_ref
						else
							display_duration = max_charge_cd
						end
					end
					state.timer_visible = true
				elseif charges == max_charges and mod:get("always_show_bar") then
					mode = "ready"
				else
					cooldown_start_value = nil
					charge_cooldown_start = nil
					slot_cooldown_start = {}
				end
			end
		end

	elseif (num_active > 0 or has_buff) then
		cooldown_start_value = nil
		charge_cooldown_start = nil
		mode = (use_scriers and "peril") or "active"
		local act_rem = (num_active > 0) and active_deployables[1].remaining or buff_remaining
		local act_dur = (num_active > 0) and active_deployables[1].duration or buff_duration
		local act_frac = math.clamp(act_rem / act_dur, 0, 1)
		display_remaining = act_rem
		display_duration = act_dur

		local target_bar = mod:get("cooldown_target_bar") or "until_full"
		local bar_frac = act_frac
		if target_bar == "until_full" and max_charges > 1 and mode ~= "peril" then
			bar_frac = math.clamp((charges + act_frac) / max_charges, 0, 1)
		end

		for i = 1, num_segs do
			if num_segs == 1 then
				seg_fractions[i] = bar_frac
			else
				local seg_lo = (i - 1) / num_segs
				local seg_hi = i / num_segs
				if bar_frac >= seg_hi then
					seg_fractions[i] = 1.0
				elseif bar_frac <= seg_lo then
					seg_fractions[i] = 0.0
				else
					seg_fractions[i] = (bar_frac - seg_lo) * num_segs
				end
			end
			local is_ready_block = (num_segs > 1 and i <= charges and mode ~= "peril")
			if is_ready_block then
				seg_colors[i] = { ready_color[1], ready_color[2], ready_color[3], ready_color[4] }
			else
				seg_colors[i] = (mode == "peril" and _get_peril_color(act_frac)) or _get_active_color(act_frac)
			end
		end
		state.timer_visible = true

	elseif has_cd then
		mode = "cooldown"
		local target_timer = mod:get("cooldown_target_timer") or "next_charge"
		if target_timer == "until_full" and uses_charges and max_charges > 1 then
			display_remaining = missing_total
			if is_smooth then
				if not cooldown_start_value or missing_total > cooldown_start_value then
					cooldown_start_value = missing_total
				end
				display_duration = cooldown_start_value
			else
				cooldown_start_value = nil
				display_duration = max_charge_cd * max_charges
			end
		else
			display_remaining = missing_charge
			if is_smooth then
				if not cooldown_start_value or missing_charge > cooldown_start_value then
					cooldown_start_value = missing_charge
				end
				display_duration = cooldown_start_value
			else
				cooldown_start_value = nil
				display_duration = max_charge_cd
			end
		end

		local bar_prog
		if is_smooth and cooldown_start_value and cooldown_start_value > 0 then
			bar_prog = math.clamp(1 - (display_remaining / cooldown_start_value), 0, 1)
		else
			bar_prog = (max_charge_cd > 0) and math.clamp(1 - (missing_charge / max_charge_cd), 0, 1) or math.clamp(charge_progress, 0, 1)
		end

		local target_bar = mod:get("cooldown_target_bar") or "until_full"
		local bar_frac = bar_prog
		if target_bar == "until_full" and max_charges > 1 then
			bar_frac = math.clamp((charges + bar_prog) / max_charges, 0, 1)
		end

		for i = 1, num_segs do
			if num_segs == 1 then
				seg_fractions[i] = bar_frac
			else
				local seg_lo = (i - 1) / num_segs
				local seg_hi = i / num_segs
				if bar_frac >= seg_hi then
					seg_fractions[i] = 1.0
				elseif bar_frac <= seg_lo then
					seg_fractions[i] = 0.0
				else
					seg_fractions[i] = (bar_frac - seg_lo) * num_segs
				end
			end
			local is_ready_block = (target_bar == "until_full" and num_segs > 1 and i <= charges)
			seg_colors[i] = is_ready_block and { ready_color[1], ready_color[2], ready_color[3], ready_color[4] } or _get_cooldown_color(bar_prog)
		end
		state.timer_visible = true

	else
		cooldown_start_value = nil
		charge_cooldown_start = nil
		if charges == max_charges and mod:get("always_show_bar") then
			mode = "ready"
			for i = 1, num_segs do
				seg_fractions[i] = 1.0
				seg_colors[i] = { ready_color[1], ready_color[2], ready_color[3], ready_color[4] }
			end
		end
	end

	if state.timer_visible then
		state.bar_visible = true
		state.remaining = display_remaining or 0
		state.duration = display_duration or 0
		state.mode = mode
		state.timer_text = string.format(mod:get("show_decimals") ~= false and "%.1f" or "%d", state.remaining)
	end

	local total_frac = 0
	for i = 1, num_segs do
		total_frac = total_frac + (seg_fractions[i] or 0)
	end
	state.fraction = math.clamp(total_frac / num_segs, 0, 1)
	state.segment_fractions = seg_fractions
	state.segment_colors = seg_colors
	bar_color._at_segment_fractions = seg_fractions
	bar_color._at_segment_colors = seg_colors

	if seg_colors[1] then
		bar_color[2], bar_color[3], bar_color[4] = seg_colors[1][2], seg_colors[1][3], seg_colors[1][4]
	end

	if mode == "cooldown" then
		local cd_prog = (state.duration and state.duration > 0) and math.clamp(1 - (state.remaining / state.duration), 0, 1) or state.fraction
		local cd_c = _get_cooldown_color(cd_prog)
		text_color[2], text_color[3], text_color[4] = cd_c[2], cd_c[3], cd_c[4]
	elseif mode == "ready" then
		text_color[2], text_color[3], text_color[4] = ready_color[2], ready_color[3], ready_color[4]
	elseif mode == "peril" then
		if mod:get("scriers_use_progress_color") ~= false then
			_apply_peril_color(state.fraction, text_color)
		else
			local p_color = mod:get("scriers_static_color") or { 255, 255, 105, 180 }
			text_color[2], text_color[3], text_color[4] = p_color[2], p_color[3], p_color[4]
		end
	else
		if mod:get("use_progress_color_text") ~= false then
			local dur_frac = (state.duration and state.duration > 0) and math.clamp(state.remaining / state.duration, 0, 1) or 0
			_apply_progress_color(dur_frac, text_color)
		else
			local c = mod:get("text_color") or { 255, 17, 90, 239 }
			text_color[2], text_color[3], text_color[4] = c[2], c[3], c[4]
		end
	end
end

local function _resolve()
	state.bar_visible = false
	state.timer_visible = false
	state.remaining = 0
	state.duration = 0
	state.fraction = 0
	state.timer_text = ""
	state.mode = nil
	state.charges_visible = false
	state.charges = 0
	state.max_charges = 1
	state.segments = 1
	state.segment_gap = mod:get("segment_gap") or 3
	state.bar_notches = 0
	state.notches_per_seg = 0
	state.notch_len_pct = 0.5
	state.notch_width = 2
	state.notch_color = nil
	state.segment_colors = nil
	state.segment_fractions = nil
	state.charge_progress = 0
	state.bubble_visible = false
	state.bubble_percent = 0
	state.bubble_text = ""

	if not mod:is_enabled() then
		cooldown_start_value = nil
		charge_cooldown_start = nil
		return
	end

	local game_mode_manager = Managers.state.game_mode
	local game_mode_name = game_mode_manager and game_mode_manager:game_mode_name()
	if not game_mode_name or game_mode_name == "hub" or game_mode_name == "prologue_hub" then
		cooldown_start_value = nil
		charge_cooldown_start = nil
		return
	end

	local player = Managers.player:local_player(1)
	local player_unit = player and player.player_unit
	if not player_unit or not ALIVE[player_unit] then return end

	local ability_extension = ScriptUnit.has_extension(player_unit, "ability_system")
	if not ability_extension then return end

	local raw_max = ability_extension:max_ability_charges(COMBAT_ABILITY)
	local max_charges = (raw_max and raw_max > 0) and raw_max or 1
	local charges = math.floor((ability_extension:remaining_ability_charges(COMBAT_ABILITY) or 0) + 0.0001)

	state.charges = charges
	state.max_charges = max_charges

	local target_bar = mod:get("cooldown_target_bar") or "until_full"
	if target_bar == "until_full" and max_charges > 1 and mod:get("segment_bar") ~= false then
		state.segments = max_charges
	else
		state.segments = 1
	end
	state.bar_notches = tonumber(mod:get("bar_notches")) or 0

	local archetype_name = player:archetype_name()
	local equipped = ability_extension:equipped_abilities()
	local combat_ability = equipped and equipped[COMBAT_ABILITY]
	local ability_group = combat_ability and combat_ability.ability_group
	local per_class = ABILITY_GROUPS[archetype_name]
	local tracked = per_class and ability_group and per_class[ability_group]
	if not tracked then return end

	if mod:get(CLASS_SETTINGS[archetype_name]) == false then return end

	local ability_enabled = mod:get(tracked.setting_id) ~= false
	local active_deployables = _get_active_deployables()

	if ability_enabled then
		_resolve_bubble(active_deployables)
		_resolve_charges(ability_extension)
	end

	local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")
	if buff_extension then
		_resolve_timer(player_unit, archetype_name, ability_group, tracked, ability_enabled, ability_extension, buff_extension, active_deployables)
	end

	if state.timer_visible then
		state.bar_visible = true
	elseif ability_enabled and mod:get("always_show_bar") then
		state.bar_visible = true
		state.fraction = 1.0
		state.mode = "ready"
		local ready_c = mod:get("ready_charge_color") or { 255, 17, 90, 239 }
		bar_color[2], bar_color[3], bar_color[4] = ready_c[2], ready_c[3], ready_c[4]
		local num_s = state.segments or 1
		local s_fracs = {}
		local s_cols = {}
		for i = 1, num_s do
			s_fracs[i] = 1.0
			s_cols[i] = { ready_c[1], ready_c[2], ready_c[3], ready_c[4] }
		end
		state.segment_fractions = s_fracs
		state.segment_colors = s_cols
		bar_color._at_segment_fractions = s_fracs
		bar_color._at_segment_colors = s_cols
	end

	local total_notches = tonumber(mod:get("bar_notches")) or 0
	local num_segs = state.segments or 1
	state.bar_notches = total_notches
	state.notches_per_seg = (num_segs > 0) and math.floor(total_notches / num_segs) or 0
	state.notch_len_pct = (mod:get("notch_length") or 50) / 100
	state.notch_width = math.max(1, tonumber(mod:get("notch_width")) or 2)
	state.notch_color = mod:get("notch_color") or { 255, 88, 99, 80 }
end


mod.get_ability_state = function()
	local time_manager = Managers.time
	local now = time_manager and time_manager:has_timer("main") and time_manager:time("main")
	if not now or now ~= last_resolve_time then
		last_resolve_time = now
		_resolve()
	end
	return state
end
