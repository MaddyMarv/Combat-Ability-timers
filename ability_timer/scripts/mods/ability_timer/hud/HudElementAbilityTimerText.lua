local mod = get_mod("ability_timer")

require("scripts/ui/hud/elements/hud_element_base")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local HudElementAbilityTimerText = class("HudElementAbilityTimerText", "HudElementBase")

local COMBAT_ABILITY_TYPE = "combat_ability"

local ABILITY_GROUPS = {
	veteran = {
		volley_fire_stance = { setting_id = "veteran_ability_stance", buff_templates = { "veteran_combat_ability_stance_master", "veteran_combat_ability_stance_master_increased_duration" } },
		veteran_stealth = { setting_id = "veteran_ability_stealth", buff_templates = { "veteran_invisibility", "veteran_damage_bonus_leaving_invisibility", "veteran_toughness_bonus_leaving_invisibility" } },
		voice_of_command = { setting_id = "veteran_ability_shout", buff_templates = { "veteran_combat_ability_increase_toughness_to_coherency" } },
	},
	zealot = {
		zealot_dash = {
			setting_id = "zealot_ability_dash",
			buff_templates = {
				"zealot_dash_buff",
				"zealot_combat_ability_attack_speed_increase",
				"zealot_combat_ability_attack_speed_increased_duration",
			},
		},
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

local function _is_class_enabled(archetype_name)
	if archetype_name == "veteran" then
		return mod:get("show_veteran") ~= false
	elseif archetype_name == "zealot" then
		return mod:get("show_zealot") ~= false
	elseif archetype_name == "psyker" then
		return mod:get("show_psyker") ~= false
	elseif archetype_name == "ogryn" then
		return mod:get("show_ogryn") ~= false
	elseif archetype_name == "adamant" then
		return mod:get("show_arbites") ~= false
	elseif archetype_name == "broker" then
		return mod:get("show_broker") ~= false
	elseif archetype_name == "cryptic" then
		return mod:get("show_cryptic") ~= false
	end

	return false
end

local function _create_scenegraph()
	local font_size = 28
	local text_w = 110
	local text_h = font_size * 1.2

	return {
		screen = {
			scale = "fit",
			size = { 1920, 1080 },
			position = { 0, 0, 0 },
		},
		root = {
			parent = "screen",
			horizontal_alignment = "left",
			vertical_alignment = "top",
			size = { text_w, text_h },
			position = { 600, 620, 100 },
		},
		timer_text = {
			parent = "root",
			horizontal_alignment = "center",
			vertical_alignment = "top",
			size = { text_w, text_h },
			position = { 0, 0, 0 },
		},
	}
end

local function _create_widgets()
	local text_style = table.clone(UIFontSettings.hud_body)
	text_style.font_type = "machine_medium"
	text_style.font_size = 28
	text_style.drop_shadow = true
	text_style.text_horizontal_alignment = "center"
	text_style.text_vertical_alignment = "center"
	text_style.text_color = table.clone(UIHudSettings.color_tint_main_1)
	text_style.offset = { 0, 0, 1 }

	return {
		timer_text = UIWidget.create_definition({
			{
				visible = false,
				pass_type = "text",
				style_id = "text",
				value = "",
				value_id = "text",
				style = text_style,
			},
		}, "timer_text"),
	}
end

local function _get_equipped_combat_ability(ability_extension)
	local equipped = ability_extension and ability_extension:equipped_abilities()
	return equipped and equipped[COMBAT_ABILITY_TYPE]
end

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

local function _get_buff_remaining_time(buff_extension, buff_template_names)
	if not buff_extension or not buff_template_names then
		return nil, nil
	end

	local buffs_by_index = buff_extension._buffs_by_index
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
						local duration = buff:duration() or (template and template.duration) or (template and template.active_duration) or 0
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

HudElementAbilityTimerText.init = function(self, parent, draw_layer, start_scale)
	local definitions = {
		scenegraph_definition = _create_scenegraph(),
		widget_definitions = _create_widgets(),
	}

	HudElementAbilityTimerText.super.init(self, parent, draw_layer, start_scale, definitions)

	local widgets = self._widgets_by_name
	self._default_text_color = table.clone(widgets.timer_text.style.text.text_color)
	self._cooldown_start_value = nil

	self:set_scenegraph_position("root", 600 + (mod:get("timer_position_x") or 0), 620 + (mod:get("timer_position_y") or 0), 100)
end

HudElementAbilityTimerText.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementAbilityTimerText.super.update(self, dt, t, ui_renderer, render_settings, input_service)

	local game_mode_manager = Managers.state.game_mode
	local game_mode_name = game_mode_manager and game_mode_manager:game_mode_name()
	local is_in_hub = not game_mode_name or game_mode_name == "hub" or game_mode_name == "prologue_hub"

	if is_in_hub then
		self:_set_visible(false)
		return
	end

	local player = Managers.player:local_player(1)
	if not player then
		self:_set_visible(false)
		return
	end

	local player_unit = player.player_unit
	if not player_unit or not ALIVE[player_unit] then
		self:_set_visible(false)
		return
	end

	local archetype_name = player:archetype_name()
	if not _is_class_enabled(archetype_name) then
		self:_set_visible(false)
		return
	end

	local ability_extension = ScriptUnit.has_extension(player_unit, "ability_system")
	local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")
	if not ability_extension or not buff_extension then
		self:_set_visible(false)
		return
	end

	local combat_ability = _get_equipped_combat_ability(ability_extension)
	local ability_group = combat_ability and combat_ability.ability_group
	local per_class = ABILITY_GROUPS[archetype_name]
	local tracked = per_class and ability_group and per_class[ability_group]

	if not tracked then
		self:_set_visible(false)
		return
	end

	if mod:get(tracked.setting_id) == false then
		local override_scriers = archetype_name == "psyker" and ability_group == "psyker_overcharge_stance" and mod:get("use_scriers_gaze_bar") ~= false and buff_extension:has_buff_using_buff_template("psyker_overcharge_stance")
		if not override_scriers then
			self:_set_visible(false)
			return
		end
	end

	local remaining, duration = _get_buff_remaining_time(buff_extension, tracked.buff_templates)
	local is_tracking_cooldown = false
	local is_tracking_peril = false

	if archetype_name == "cryptic" and ability_group == "cryptic_precision_stance" then
		local has_stance_buff = false
		for i = 1, #tracked.buff_templates do
			if buff_extension:has_keyword("cryptic_precision_stance") or buff_extension:has_unique_buff_id(tracked.buff_templates[i]) then
				has_stance_buff = true
				break
			end
		end

		if has_stance_buff then
			local max_cooldown = ability_extension:max_ability_cooldown("combat_ability")
			local max_charges = ability_extension:max_ability_charges("combat_ability")
			local remaining_charges = ability_extension:remaining_ability_charges("combat_ability")
			local remaining_cooldown = ability_extension:remaining_ability_cooldown("combat_ability")

			local total_cooldown = remaining_charges * max_cooldown + (remaining_cooldown > 0 and max_cooldown - remaining_cooldown or 0)

			local drain_rate = 0.1
			local talent_settings = require("scripts/settings/talent/talent_settings")
			local precision_settings = talent_settings.cryptic and talent_settings.cryptic.precision_stance
			if precision_settings and precision_settings.cooldown_percent_lost_per_second then
				drain_rate = precision_settings.cooldown_percent_lost_per_second
			end

			remaining = total_cooldown / (drain_rate * max_cooldown)
			duration = max_charges / drain_rate
		end
	elseif archetype_name == "psyker" and ability_group == "psyker_overcharge_stance" and mod:get("use_scriers_gaze_bar") ~= false then
		if buff_extension:has_buff_using_buff_template("psyker_overcharge_stance") then
			local unit_data_extension = ScriptUnit.has_extension(player_unit, "unit_data_system")
			local warp_charge_component = unit_data_extension and unit_data_extension:read_component("warp_charge")
			if warp_charge_component then
				remaining = (warp_charge_component.current_percentage or 0) * 100
				duration = 100
				is_tracking_peril = true
			end
		end
	end

	local current_deployable = nil

	if not remaining and mod.tracked_deployables then
		local t_time = Managers.time:time("gameplay")
		for unit, data in pairs(mod.tracked_deployables) do
			local elapsed = t_time - data.start_time
			local d_rem = data.duration - elapsed

			if d_rem > 0 then
				remaining = d_rem
				duration = data.duration
				current_deployable = data
				break
			else
				mod.tracked_deployables[unit] = nil
			end
		end
	end

	if remaining and remaining >= 0.05 then
		self._cooldown_start_value = nil
	end

	if not remaining or remaining < 0.05 then
		if mod:get("track_cooldown") ~= false then
			local cooldown_remaining = ability_extension:remaining_ability_cooldown("combat_ability")

			if cooldown_remaining and cooldown_remaining > 0.05 then
				local cooldown_mode = mod:get("cooldown_display_mode") or "smooth"

				if cooldown_mode == "full" then
					local max_cooldown = ability_extension:max_ability_cooldown("combat_ability")
					if max_cooldown and max_cooldown > 0 then
						remaining = cooldown_remaining
						duration = max_cooldown
						is_tracking_cooldown = true
					end
				else
					if not self._cooldown_start_value or cooldown_remaining > self._cooldown_start_value then
						self._cooldown_start_value = cooldown_remaining
					end

					remaining = cooldown_remaining
					duration = self._cooldown_start_value
					is_tracking_cooldown = true
				end
			else
				self._cooldown_start_value = nil
			end
		end
	end

	if not remaining or remaining < 0.05 or not duration or duration <= 0 then
		self:_set_visible(false)
		return
	end

	self:_set_visible(true)

	local display_mode = mod:get("display_mode") or "both"
	local show_number = display_mode == "both" or display_mode == "timer_only"
	local use_color = mod:get("use_progress_color_text") ~= false

	local text_widget = self._widgets_by_name.timer_text
	local alpha = mod:get("gauge_alpha") or 1.0

	text_widget.style.text.text_color[1] = 255 * alpha

	local frac = math.max(0, math.min(1, remaining / duration))
	if is_tracking_cooldown then
		frac = 1 - frac
	end

	if show_number then
		text_widget.content.visible = true
		text_widget.style.text.text_horizontal_alignment = mod:get("timer_text_alignment") or "center"
		text_widget.style.text.font_size = mod:get("timer_text_size") or 28
		
		if mod:get("show_decimals") ~= false then
			text_widget.content.text = string.format("%.1f", remaining)
		else
			text_widget.content.text = string.format("%d", remaining)
		end
		
		local text_color = text_widget.style.text.text_color
		if is_tracking_cooldown then
			local cd_color = mod:get("cooldown_color") or { 255, 120, 70, 220 }
			text_color[1] = cd_color[1] * alpha
			text_color[2] = cd_color[2]
			text_color[3] = cd_color[3]
			text_color[4] = cd_color[4]
		elseif is_tracking_peril then
			if mod:get("scriers_use_progress_color") ~= false then
				_apply_peril_color(frac, text_color)
			else
				local custom_color = mod:get("scriers_static_color") or { 255, 255, 70, 150 }
				text_color[1] = custom_color[1] * alpha
				text_color[2] = custom_color[2]
				text_color[3] = custom_color[3]
				text_color[4] = custom_color[4]
			end
		elseif use_color then
			_apply_progress_color(frac, text_color)
		else
			local custom_color = mod:get("text_color") or self._default_text_color
			text_color[1] = custom_color[1] * alpha
			text_color[2] = custom_color[2]
			text_color[3] = custom_color[3]
			text_color[4] = custom_color[4]
		end
		text_widget.dirty = true
	else
		text_widget.content.visible = false
	end
end

HudElementAbilityTimerText._set_visible = function(self, visible)
	local widgets = self._widgets_by_name
	if not visible then
		widgets.timer_text.content.visible = false
	end
end

HudElementAbilityTimerText.draw = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementAbilityTimerText.super.draw(self, dt, t, ui_renderer, render_settings, input_service)
end

HudElementAbilityTimerText.destroy = function(self, ui_renderer)
	HudElementAbilityTimerText.super.destroy(self, ui_renderer)
end

return HudElementAbilityTimerText
