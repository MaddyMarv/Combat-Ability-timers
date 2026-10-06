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

local bar_color = { 255, 255, 255, 255 }
local text_color = { 255, 255, 255, 255 }
local charges_color = { 255, 255, 255, 255 }
local bubble_color = { 255, 255, 255, 255 }

local state = {
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
	max_charges = 0,
	charges_color = charges_color,
	bubble_visible = false,
	bubble_percent = 0,
	bubble_color = bubble_color,
}

local last_resolve_time = nil
local cooldown_start_value = nil

local function _apply_progress_color(frac, color)
	local clamped = math.max(0, math.min(1, frac or 0))
	local c_high = mod:get("high_color") or { 255, 0, 255, 0 }
	local c_mid = mod:get("mid_color") or { 255, 255, 255, 0 }
	local c_low = mod:get("low_color") or { 255, 255, 0, 0 }

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
	local c_high = mod:get("peril_high_color") or { 255, 139, 0, 0 }

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

local function _get_active_deployable()
	local deployables = mod.tracked_deployables
	if not deployables then
		return nil, nil
	end

	local time_manager = Managers.time
	if not time_manager or not time_manager:has_timer("gameplay") then
		return nil, nil
	end

	local t = time_manager:time("gameplay")
	for unit, data in pairs(deployables) do
		local remaining = data.duration - (t - data.start_time)
		if remaining > 0 then
			return data, remaining
		end
		deployables[unit] = nil
	end

	return nil, nil
end

local function _resolve_bubble(deployable)
	if mod:get("show_bubble_health") == false then return end
	if not deployable or deployable.name ~= "psyker_shield" then return end
	if not deployable.max_health or deployable.max_health <= 0 then return end

	local percent = math.floor((deployable.current_health / deployable.max_health) * 100)
	state.bubble_visible = true
	state.bubble_percent = percent

	if mod:get("use_progress_color_text") ~= false then
		_apply_progress_color(percent / 100, bubble_color)
	else
		local custom = mod:get("text_color") or { 255, 255, 255, 255 }
		bubble_color[2], bubble_color[3], bubble_color[4] = custom[2], custom[3], custom[4]
	end
end

local function _resolve_charges(ability_extension)
	if mod:get("show_charges") == false then return end

	local max_charges = ability_extension:max_ability_charges(COMBAT_ABILITY)
	if not max_charges or max_charges <= 0 then return end

	local charges = math.floor((ability_extension:remaining_ability_charges(COMBAT_ABILITY) or 0) + 0.0001)
	if charges <= 1 and mod:get("always_show_charges") == false then return end

	state.charges_visible = true
	state.charges = charges
	state.max_charges = max_charges

	if mod:get("use_progress_color_text") ~= false then
		local frac = (max_charges > 0) and (charges / max_charges) or 0
		local c_high = mod:get("high_color") or { 255, 0, 255, 0 }
		local c_mid = mod:get("mid_color") or { 255, 255, 255, 0 }
		local c_low = mod:get("low_color") or { 255, 255, 0, 0 }
		local src = (frac == 1 and c_high) or (frac == 0 and c_low) or c_mid
		charges_color[2], charges_color[3], charges_color[4] = src[2], src[3], src[4]
	else
		local custom = mod:get("text_color") or { 255, 255, 255, 255 }
		charges_color[2], charges_color[3], charges_color[4] = custom[2], custom[3], custom[4]
	end
end

local function _resolve_timer(player_unit, archetype_name, ability_group, tracked, ability_enabled, ability_extension, buff_extension, deployable, deployable_remaining)
	local use_scriers = archetype_name == "psyker"
		and ability_group == "psyker_overcharge_stance"
		and mod:get("use_scriers_gaze_bar") ~= false
		and buff_extension:has_buff_using_buff_template("psyker_overcharge_stance")

	if not ability_enabled and not use_scriers then return end

	local remaining, duration = _get_buff_remaining_time(buff_extension, tracked.buff_templates)
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
				remaining = total_cooldown / (drain_rate * max_cooldown)
				duration = max_charges / drain_rate
			end
		end
	elseif use_scriers then
		local unit_data_extension = ScriptUnit.has_extension(player_unit, "unit_data_system")
		local warp_charge_component = unit_data_extension and unit_data_extension:read_component("warp_charge")
		if warp_charge_component then
			remaining = (warp_charge_component.current_percentage or 0) * 100
			duration = 100
			mode = "peril"
		end
	end

	if not remaining and deployable then
		remaining = deployable_remaining
		duration = deployable.duration
	end

	if remaining and remaining >= MIN_TIME then
		cooldown_start_value = nil
	elseif mod:get("track_cooldown") ~= false then
		local cooldown_remaining = _get_remaining_ability_cooldown(ability_extension)

		if cooldown_remaining and cooldown_remaining > MIN_TIME then
			if mod:get("cooldown_display_mode") == "full" then
				local max_cooldown = _get_max_ability_cooldown(ability_extension)
				if max_cooldown and max_cooldown > 0 then
					remaining, duration, mode = cooldown_remaining, max_cooldown, "cooldown"
				end
			else
				if not cooldown_start_value or cooldown_remaining > cooldown_start_value then
					cooldown_start_value = cooldown_remaining
				end
				remaining, duration, mode = cooldown_remaining, cooldown_start_value, "cooldown"
			end
		else
			cooldown_start_value = nil
		end
	end

	if not remaining or remaining < MIN_TIME or not duration or duration <= 0 then return end

	local fraction = math.max(0, math.min(1, remaining / duration))
	if mode == "cooldown" then
		fraction = 1 - fraction
	end

	state.timer_visible = true
	state.remaining = remaining
	state.duration = duration
	state.fraction = fraction
	state.mode = mode
	state.timer_text = string.format(mod:get("show_decimals") ~= false and "%.1f" or "%d", remaining)

	if mode == "cooldown" then
		local cd_color = mod:get("cooldown_color") or { 255, 120, 70, 220 }
		bar_color[2], bar_color[3], bar_color[4] = cd_color[2], cd_color[3], cd_color[4]
		text_color[2], text_color[3], text_color[4] = cd_color[2], cd_color[3], cd_color[4]
	elseif mode == "peril" then
		if mod:get("scriers_use_progress_color") ~= false then
			_apply_peril_color(fraction, bar_color)
			_apply_peril_color(fraction, text_color)
		else
			local p_color = mod:get("scriers_static_color") or { 255, 255, 70, 150 }
			bar_color[2], bar_color[3], bar_color[4] = p_color[2], p_color[3], p_color[4]
			text_color[2], text_color[3], text_color[4] = p_color[2], p_color[3], p_color[4]
		end
	else
		if mod:get("use_progress_color") ~= false then
			_apply_progress_color(fraction, bar_color)
		else
			local c = mod:get("bar_color") or { 255, 255, 255, 255 }
			bar_color[2], bar_color[3], bar_color[4] = c[2], c[3], c[4]
		end

		if mod:get("use_progress_color_text") ~= false then
			_apply_progress_color(fraction, text_color)
		else
			local c = mod:get("text_color") or { 255, 255, 255, 255 }
			text_color[2], text_color[3], text_color[4] = c[2], c[3], c[4]
		end
	end
end

local function _resolve()
	state.timer_visible = false
	state.remaining = 0
	state.duration = 0
	state.fraction = 0
	state.timer_text = ""
	state.mode = nil
	state.charges_visible = false
	state.charges = 0
	state.max_charges = 0
	state.bubble_visible = false
	state.bubble_percent = 0

	if not mod:is_enabled() then return end

	local game_mode_manager = Managers.state.game_mode
	local game_mode_name = game_mode_manager and game_mode_manager:game_mode_name()
	if not game_mode_name or game_mode_name == "hub" or game_mode_name == "prologue_hub" then return end

	local player = Managers.player:local_player(1)
	local player_unit = player and player.player_unit
	if not player_unit or not ALIVE[player_unit] then return end

	local ability_extension = ScriptUnit.has_extension(player_unit, "ability_system")
	if not ability_extension then return end

	local archetype_name = player:archetype_name()
	local equipped = ability_extension:equipped_abilities()
	local combat_ability = equipped and equipped[COMBAT_ABILITY]
	local ability_group = combat_ability and combat_ability.ability_group
	local per_class = ABILITY_GROUPS[archetype_name]
	local tracked = per_class and ability_group and per_class[ability_group]
	if not tracked then return end

	if mod:get(CLASS_SETTINGS[archetype_name]) == false then return end

	local ability_enabled = mod:get(tracked.setting_id) ~= false
	local deployable, deployable_remaining = _get_active_deployable()

	if ability_enabled then
		_resolve_bubble(deployable)
		_resolve_charges(ability_extension)
	end

	local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")
	if buff_extension then
		_resolve_timer(player_unit, archetype_name, ability_group, tracked, ability_enabled, ability_extension, buff_extension, deployable, deployable_remaining)
	end
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
