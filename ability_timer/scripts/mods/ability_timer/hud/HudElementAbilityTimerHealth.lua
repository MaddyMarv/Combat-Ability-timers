local mod = get_mod("ability_timer")

require("scripts/ui/hud/elements/hud_element_base")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local HudElementAbilityTimerHealth = class("HudElementAbilityTimerHealth", "HudElementBase")

local COMBAT_ABILITY_TYPE = "combat_ability"

local ABILITY_GROUPS = {
	veteran = {
		volley_fire_stance = { setting_id = "veteran_ability_stance" },
		veteran_stealth = { setting_id = "veteran_ability_stealth" },
		voice_of_command = { setting_id = "veteran_ability_shout" },
	},
	zealot = {
		zealot_dash = { setting_id = "zealot_ability_dash" },
		bolstering_prayer = { setting_id = "zealot_ability_relic" },
		zealot_invisibility = { setting_id = "zealot_ability_invisibility" },
	},
	psyker = {
		psyker_shout = { setting_id = "psyker_ability_shout" },
		psyker_shield = { setting_id = "psyker_ability_shield" },
		psyker_overcharge_stance = { setting_id = "psyker_ability_overcharge" },
	},
	ogryn = {
		ogryn_charge = { setting_id = "ogryn_ability_charge" },
		ogryn_gunlugger_stance = { setting_id = "ogryn_ability_ranged_stance" },
		ogryn_taunt_shout = { setting_id = "ogryn_ability_taunt" },
	},
	adamant = {
		adamant_shout = { setting_id = "arbites_ability_shout" },
		adamant_charge = { setting_id = "arbites_ability_charge" },
		adamant_stance = { setting_id = "arbites_ability_stance" },
		adamant_area_buff_drone = { setting_id = "arbites_ability_drone" },
	},
	broker = {
		broker_focus_stance = { setting_id = "broker_ability_focus" },
		broker_punk_rage_stance = { setting_id = "broker_ability_punk_rage" },
		broker_stimm_field = { setting_id = "broker_ability_stimm_field" },
	},
	cryptic = {
		cryptic_discharge = { setting_id = "cryptic_ability_discharge" },
		cryptic_precision_stance = { setting_id = "cryptic_ability_precision_stance" },
		cryptic_chordclaw = { setting_id = "cryptic_ability_chordclaw" },
	},
}

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
			position = { 661.25, 620, 100 },
		},
		health_text = {
			parent = "root",
			horizontal_alignment = "center",
			vertical_alignment = "top",
			size = { text_w, text_h },
			position = { 0, 0, 0 },
		},
	}
end

local function _create_widgets()
	local health_text_style = table.clone(UIFontSettings.hud_body)
	health_text_style.font_type = "machine_medium"
	health_text_style.font_size = 24
	health_text_style.drop_shadow = true
	health_text_style.text_horizontal_alignment = "center"
	health_text_style.text_vertical_alignment = "center"
	health_text_style.text_color = table.clone(UIHudSettings.color_tint_main_1)
	health_text_style.offset = { 0, 0, 1 }

	return {
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
	}
end

local function _apply_health_color(health_percent, color)
	local clamped = math.max(0, math.min(100, health_percent or 100)) / 100
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

local function _get_equipped_combat_ability(ability_extension)
	local equipped = ability_extension and ability_extension:equipped_abilities()
	return equipped and equipped[COMBAT_ABILITY_TYPE]
end

HudElementAbilityTimerHealth.init = function(self, parent, draw_layer, start_scale)
	local definitions = {
		scenegraph_definition = _create_scenegraph(),
		widget_definitions = _create_widgets(),
	}

	HudElementAbilityTimerHealth.super.init(self, parent, draw_layer, start_scale, definitions)

	local widgets = self._widgets_by_name
	self._default_health_color = table.clone(widgets.health_text.style.text.text_color)
end

HudElementAbilityTimerHealth.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementAbilityTimerHealth.super.update(self, dt, t, ui_renderer, render_settings, input_service)

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
	local ability_extension = ScriptUnit.has_extension(player_unit, "ability_system")
	if not ability_extension then
		self:_set_visible(false)
		return
	end

	local combat_ability = _get_equipped_combat_ability(ability_extension)
	local ability_group = combat_ability and combat_ability.ability_group
	local per_class = ABILITY_GROUPS[archetype_name]
	local tracked = per_class and ability_group and per_class[ability_group]

	if not tracked or mod:get(tracked.setting_id) == false then
		self:_set_visible(false)
		return
	end

	local current_deployable = nil
	if mod.tracked_deployables then
		local t_time = Managers.time:time("gameplay")
		for unit, data in pairs(mod.tracked_deployables) do
			local elapsed = t_time - data.start_time
			local d_rem = data.duration - elapsed

			if d_rem > 0 then
				current_deployable = data
				break
			end
		end
	end

	if not current_deployable then
		self:_set_visible(false)
		return
	end

	self:_set_visible(true)

	local use_color = mod:get("use_progress_color_text") ~= false
	local health_widget = self._widgets_by_name.health_text
	local alpha = mod:get("gauge_alpha") or 1.0
	local pos_x = mod:get("health_position_x") or 0
	local pos_y = mod:get("health_position_y") or 0
	
	health_widget.style.text.text_horizontal_alignment = mod:get("health_text_alignment") or "center"
	health_widget.style.text.font_size = mod:get("health_text_size") or 24

	self:set_scenegraph_position("root", 661.25 + pos_x, 620 + pos_y, 100)

	health_widget.style.text.text_color[1] = 255 * alpha

	if mod:get("show_bubble_health") ~= false and current_deployable.name == "psyker_shield" and current_deployable.max_health and current_deployable.max_health > 0 then
		local health_percent = math.floor((current_deployable.current_health / current_deployable.max_health) * 100)
		health_widget.content.visible = true
		health_widget.content.text = string.format("%d%%", health_percent)
		local health_color = health_widget.style.text.text_color

		if use_color then
			_apply_health_color(health_percent, health_color)
		else
			local custom_color = mod:get("text_color") or self._default_health_color
			health_color[1] = custom_color[1] * alpha
			health_color[2] = custom_color[2]
			health_color[3] = custom_color[3]
			health_color[4] = custom_color[4]
		end

		health_widget.dirty = true
	else
		health_widget.content.visible = false
	end
end

HudElementAbilityTimerHealth._set_visible = function(self, visible)
	local widgets = self._widgets_by_name
	if not visible then
		widgets.health_text.content.visible = false
	end
end

HudElementAbilityTimerHealth.draw = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementAbilityTimerHealth.super.draw(self, dt, t, ui_renderer, render_settings, input_service)
end

HudElementAbilityTimerHealth.destroy = function(self, ui_renderer)
	HudElementAbilityTimerHealth.super.destroy(self, ui_renderer)
end

return HudElementAbilityTimerHealth
