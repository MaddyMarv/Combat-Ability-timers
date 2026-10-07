local mod = get_mod("ability_timer")

require("scripts/ui/hud/elements/hud_element_base")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local HudElementAbilityTimerHealth = class("HudElementAbilityTimerHealth", "HudElementBase")

local function _create_scenegraph()
	local font_size = 28
	local text_w = 210
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
			position = { 600, 674, 100 },
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

HudElementAbilityTimerHealth.init = function(self, parent, draw_layer, start_scale)
	local definitions = {
		scenegraph_definition = _create_scenegraph(),
		widget_definitions = _create_widgets(),
	}

	HudElementAbilityTimerHealth.super.init(self, parent, draw_layer, start_scale, definitions)
	
	self:set_scenegraph_position("root", 600 + (mod:get("health_position_x") or 0), 674 + (mod:get("health_position_y") or 0), 100)
end

HudElementAbilityTimerHealth.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementAbilityTimerHealth.super.update(self, dt, t, ui_renderer, render_settings, input_service)

	if mod:get("show_native_hud") == false then
		self:_set_visible(false)
		return
	end

	local ability_state = mod.get_ability_state()
	if not ability_state or not ability_state.bubble_visible then
		self:_set_visible(false)
		return
	end

	self:_set_visible(true)

	local health_widget = self._widgets_by_name.health_text
	local alpha = mod:get("gauge_alpha") or 1.0
	health_widget.style.text.text_horizontal_alignment = mod:get("health_text_alignment") or "center"
	health_widget.style.text.font_size = mod:get("health_text_size") or 24

	health_widget.style.text.text_color[1] = 255 * alpha

	health_widget.content.visible = true
	health_widget.content.text = ability_state.bubble_text or string.format("%d%%", ability_state.bubble_percent or 100)
	local health_color = health_widget.style.text.text_color
	local src = ability_state.bubble_color
	health_color[1] = 255 * alpha
	health_color[2] = src[2]
	health_color[3] = src[3]
	health_color[4] = src[4]
	health_widget.dirty = true
end

HudElementAbilityTimerHealth._set_visible = function(self, visible)
	local widgets = self._widgets_by_name
	if not visible and widgets and widgets.health_text then
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
