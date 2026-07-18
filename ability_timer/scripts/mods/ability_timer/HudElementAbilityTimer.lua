local mod = get_mod("ability_timer")

require("scripts/ui/hud/elements/hud_element_base")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local HudElementAbilityTimer = class("HudElementAbilityTimer", "HudElementBase")

local COMBAT_ABILITY_TYPE = "combat_ability"

local ABILITY_GROUPS = {
	veteran = {
		volley_fire_stance = { setting_id = "veteran_ability_stance", buff_templates = { "veteran_combat_ability_stance_master", "veteran_combat_ability_stance_master_increased_duration" } },
		veteran_stealth = { setting_id = "veteran_ability_stealth", buff_templates = { "veteran_invisibility" } },
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
		bolstering_prayer = { setting_id = "zealot_ability_relic", buff_templates = { "zealot_channel_toughness_bonus" } },
		zealot_invisibility = { setting_id = "zealot_ability_invisibility", buff_templates = { "zealot_invisibility", "zealot_invisibility_increased_duration" } },
	},
	psyker = {
		psyker_shout = { setting_id = "psyker_ability_shout", buff_templates = { "psyker_shout_warp_generation_reduction" } },
		psyker_shield = { setting_id = "psyker_ability_shield", buff_templates = nil },
		psyker_overcharge_stance = { setting_id = "psyker_ability_overcharge", buff_templates = { "psyker_overcharge_stance_damage", "psyker_overcharge_stance_finesse_damage" } },
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
		cryptic_discharge = { setting_id = "cryptic_ability_discharge", buff_templates = nil },
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
	local bar_w = 210
	local bar_h = 15
	local gap = 6

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
			size = { bar_w + gap + text_w, math.max(text_h * 2, bar_h) },
			position = { 780, 670, 100 },
		},
		bar = {
			parent = "root",
			horizontal_alignment = "left",
			vertical_alignment = "top",
			size = { bar_w, bar_h },
			position = { 0, 0, 0 },
		},
		timer_text = {
			parent = "root",
			horizontal_alignment = "left",
			vertical_alignment = "top",
			size = { text_w, text_h },
			position = { 0, 0, 0 },
		},
		health_text = {
			parent = "timer_text",
			horizontal_alignment = "left",
			vertical_alignment = "top",
			size = { text_w, text_h },
			position = { 0, text_h * 0.8, 0 },
		},
	}
end

local function _create_widgets()
	local text_style = table.clone(UIFontSettings.hud_body)
	text_style.font_type = "machine_medium"
	text_style.font_size = 28
	text_style.drop_shadow = true
	text_style.text_horizontal_alignment = "left"
	text_style.text_vertical_alignment = "center"
	text_style.text_color = table.clone(UIHudSettings.color_tint_main_1)
	text_style.offset = { 0, 0, 1 }

	local health_text_style = table.clone(text_style)
	health_text_style.font_size = 24

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
		health_text = UIWidget.create_definition({
			{
				visible = false,
				pass_type = "text",
				style_id = "text",
				value = "",
				value_id = "text",
				style = health_text_style,
			},
		}, "health_text"),
		bar_bg = UIWidget.create_definition({
			{
				visible = false,
				pass_type = "rect",
				style_id = "rect",
				style = {
					color = { 160, 0, 0, 0 },
					offset = { 0, 0, 0 },
				},
			},
		}, "bar"),
		bar_fill = UIWidget.create_definition({
			{
				visible = false,
				pass_type = "rect",
				style_id = "rect",
				style = {
					size = { 160, 14 },
					color = { 220, 255, 255, 255 },
					offset = { 0, 0, 1 },
				},
			},
		}, "bar"),
		bracket = UIWidget.create_definition({
			{
				visible = false,
				pass_type = "rotated_texture",
				style_id = "bracket",
				value = "content/ui/materials/hud/stamina_gauge",
				style = {
					vertical_alignment = "center",
					horizontal_alignment = "center",
					offset = { 0, 0, 10 },
					size = { 160, 14 },
					pivot = { 80, 7 },
					color = UIHudSettings.color_tint_main_2,
				},
			},
		}, "bar"),
	}
end

local function _get_equipped_combat_ability(ability_extension)
	local equipped = ability_extension and ability_extension:equipped_abilities()
	return equipped and equipped[COMBAT_ABILITY_TYPE]
end

local function _apply_progress_color(frac, color)
	local clamped = math.max(0, math.min(1, frac or 0))
	local r, g
	if clamped < 0.5 then
		r = 255
		g = math.floor(255 * (clamped / 0.5) + 0.5)
	else
		r = math.floor(255 * (1 - (clamped - 0.5) / 0.5) + 0.5)
		g = 255
	end
	color[2] = r
	color[3] = g
	color[4] = 0
end

local function _apply_health_color(health_percent, color)
	local clamped = math.max(0, math.min(100, health_percent or 100)) / 100
	local r, g
	if clamped < 0.5 then
		r = 255
		g = math.floor(255 * (clamped / 0.5) + 0.5)
	else
		r = math.floor(255 * (1 - (clamped - 0.5) / 0.5) + 0.5)
		g = 255
	end
	color[2] = r
	color[3] = g
	color[4] = 0
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
					local progress = buff:duration_progress() or 1
					local duration = buff:duration() or (template and template.active_duration) or 0
					local remaining = duration * progress
					if not best_remaining or remaining > best_remaining then
						best_remaining = remaining
						best_duration = duration
					end
					break
				end
			end
		end
	end

	return best_remaining, best_duration
end

HudElementAbilityTimer.init = function(self, parent, draw_layer, start_scale)
	local definitions = {
		scenegraph_definition = _create_scenegraph(),
		widget_definitions = _create_widgets(),
	}

	HudElementAbilityTimer.super.init(self, parent, draw_layer, start_scale, definitions)

	local widgets = self._widgets_by_name
	self._default_bar_color = table.clone(widgets.bar_fill.style.rect.color)
	self._default_text_color = table.clone(widgets.timer_text.style.text.text_color)
	self._default_health_color = table.clone(widgets.health_text.style.text.text_color)
	self._cooldown_start_value = nil
end

HudElementAbilityTimer.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementAbilityTimer.super.update(self, dt, t, ui_renderer, render_settings, input_service)

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
		self:_set_visible(false)
		return
	end

	local remaining, duration = _get_buff_remaining_time(buff_extension, tracked.buff_templates)

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
	end

	local current_deployable = nil
	local is_tracking_cooldown = false

	if not remaining and mod.tracked_deployables then
		local t = Managers.time:time("gameplay")
		for unit, data in pairs(mod.tracked_deployables) do
			local elapsed = t - data.start_time
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
					if not self._cooldown_start_value then
						self._cooldown_start_value = cooldown_remaining
					end

					remaining = cooldown_remaining
					duration = self._cooldown_start_value
					is_tracking_cooldown = true
				end
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
	local show_bar = display_mode == "both" or display_mode == "progress_only"
	local use_color = mod:get("use_progress_color") ~= false

	local text_widget = self._widgets_by_name.timer_text
	local health_widget = self._widgets_by_name.health_text
	local bar_bg = self._widgets_by_name.bar_bg
	local bar_fill = self._widgets_by_name.bar_fill
	local bracket = self._widgets_by_name.bracket
	local bar_bg = self._widgets_by_name.bar_bg

	local gauge_len = mod:get("gauge_length") or 210
	local gauge_thick = mod:get("gauge_thick") or 15
	local orientation = mod:get("comp_orientation") or 0
	local bar_dir = mod:get("bar_direction") or 1
	local alpha = mod:get("gauge_alpha") or 1.0
	local pos_x = mod:get("position_x") or 0
	local pos_y = mod:get("position_y") or 0

	local root_pos = self._ui_scenegraph.root.position
	root_pos[1] = 780 + pos_x
	root_pos[2] = 670 + pos_y

	local full_w = gauge_len
	local bar_h = gauge_thick
	local is_vertical = orientation == 1

	text_widget.style.text.text_color[1] = 255 * alpha
	health_widget.style.text.text_color[1] = 255 * alpha
	bar_bg.style.rect.color[1] = 160 * alpha
	bar_fill.style.rect.color[1] = 255 * alpha
	bracket.style.bracket.color[1] = 255 * alpha

	if is_vertical then
		bar_size = { bar_h, full_w }
	end

	local frac = math.max(0, math.min(1, remaining / duration))

	if is_tracking_cooldown then
		frac = 1 - frac
	end

	local gap = 6

	if is_vertical then
		text_widget.style.text.text_vertical_alignment = "center"
		text_widget.style.text.text_horizontal_alignment = "left"
		text_widget.style.text.offset[1] = bar_size[1] + gap
		text_widget.style.text.offset[2] = bar_h * 0.5
		health_widget.style.text.offset[1] = bar_size[1] + gap
		health_widget.style.text.offset[2] = bar_h * 0.5 + self._ui_scenegraph.timer_text.size[2] * 0.3
	else
		text_widget.style.text.text_vertical_alignment = "top"
		text_widget.style.text.text_horizontal_alignment = "left"
		text_widget.style.text.offset[1] = full_w + gap
		text_widget.style.text.offset[2] = 0
		health_widget.style.text.offset[1] = full_w + gap
		health_widget.style.text.offset[2] = self._ui_scenegraph.timer_text.size[2] * 0.3
	end

	if show_number then
		text_widget.content.visible = true
		text_widget.content.text = string.format("%.1f", remaining)
		local text_color = text_widget.style.text.text_color
		if is_tracking_cooldown then
			text_color[1] = 255 * alpha
			text_color[2] = 160
			text_color[3] = 80
			text_color[4] = 220
		elseif use_color then
			_apply_progress_color(frac, text_color)
		else
			text_color[1] = 255 * alpha
			text_color[2] = self._default_text_color[2]
			text_color[3] = self._default_text_color[3]
			text_color[4] = self._default_text_color[4]
		end
		text_widget.dirty = true
	else
		text_widget.content.visible = false
	end

	if mod:get("show_bubble_health") ~= false and current_deployable and current_deployable.name == "psyker_shield" and current_deployable.max_health and current_deployable.max_health > 0 then
		local health_percent = math.floor((current_deployable.current_health / current_deployable.max_health) * 100)
		health_widget.content.visible = true
		health_widget.content.text = string.format("%d%%", health_percent)
		local health_color = health_widget.style.text.text_color

		if use_color then
			_apply_health_color(health_percent, health_color)
		else
			health_color[1] = 255 * alpha
			health_color[2] = self._default_health_color[2]
			health_color[3] = self._default_health_color[3]
			health_color[4] = self._default_health_color[4]
		end

		health_widget.dirty = true
	else
		health_widget.content.visible = false
	end

	if show_bar then
		bar_bg.content.visible = true
		bar_fill.content.visible = true

		local sg_size = self._ui_scenegraph.bar.size
		if is_vertical then
			sg_size[1] = bar_h
			sg_size[2] = full_w
		else
			sg_size[1] = full_w
			sg_size[2] = bar_h
		end

		if mod:get("show_bracket") ~= false then
			bracket.content.visible = true
			local spacing = 0
			bracket.style.bracket.size = { full_w + spacing, bar_h }
			bracket.style.bracket.pivot = { (full_w + spacing)/2, bar_h/2 }
			if is_vertical then
				bracket.style.bracket.angle = math.pi * 0.5
				bracket.style.bracket.offset = { 0, 0, 10 }
			else
				bracket.style.bracket.angle = 0
				bracket.style.bracket.offset = { 0, 0, 10 }
			end
			bracket.dirty = true
		else
			bracket.content.visible = false
		end

		local fill_size = math.floor(full_w * frac)

		if is_vertical then
			bar_bg.style.rect.size = { bar_h, full_w }
			bar_fill.style.rect.size = { bar_h, fill_size }

			bar_fill.style.rect.vertical_alignment = "bottom"
			bar_fill.style.rect.horizontal_alignment = "left"
			bar_fill.style.rect.offset = {0, 0, 1}

			if bar_dir == 2 then
				bar_fill.style.rect.vertical_alignment = "top"
			elseif bar_dir == 3 then
				bar_fill.style.rect.vertical_alignment = "center"
			end
		else
			bar_bg.style.rect.size = { full_w, bar_h }
			bar_fill.style.rect.size = { fill_size, bar_h }

			bar_fill.style.rect.horizontal_alignment = "left"
			bar_fill.style.rect.vertical_alignment = "center"
			bar_fill.style.rect.offset = {0, 0, 1}

			if bar_dir == 2 then
				bar_fill.style.rect.horizontal_alignment = "right"
			elseif bar_dir == 3 then
				bar_fill.style.rect.horizontal_alignment = "center"
			end
		end

		local bar_color = bar_fill.style.rect.color
		if is_tracking_cooldown then
			bar_color[1] = 255 * alpha
			bar_color[2] = 160
			bar_color[3] = 80
			bar_color[4] = 220
		elseif use_color then
			_apply_progress_color(frac, bar_color)
		else
			bar_color[1] = self._default_bar_color[1] * alpha
			bar_color[2] = self._default_bar_color[2]
			bar_color[3] = self._default_bar_color[3]
			bar_color[4] = self._default_bar_color[4]
		end
		bar_fill.dirty = true
		bracket.dirty = true
	else
		bar_bg.content.visible = false
		bar_fill.content.visible = false
		bracket.content.visible = false
	end
end

HudElementAbilityTimer._set_visible = function(self, visible)
	local widgets = self._widgets_by_name
	if not visible then
		widgets.timer_text.content.visible = false
		widgets.health_text.content.visible = false
		widgets.bar_bg.content.visible = false
		widgets.bar_fill.content.visible = false
		widgets.bracket.content.visible = false
	end
end

HudElementAbilityTimer.draw = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementAbilityTimer.super.draw(self, dt, t, ui_renderer, render_settings, input_service)
end

HudElementAbilityTimer.destroy = function(self, ui_renderer)
	HudElementAbilityTimer.super.destroy(self, ui_renderer)
end

return HudElementAbilityTimer


