local mod = get_mod("ability_timer")

require("scripts/ui/hud/elements/hud_element_base")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local HudElementAbilityTimerText = class("HudElementAbilityTimerText", "HudElementBase")

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

HudElementAbilityTimerText.init = function(self, parent, draw_layer, start_scale)
	local definitions = {
		scenegraph_definition = _create_scenegraph(),
		widget_definitions = _create_widgets(),
	}

	HudElementAbilityTimerText.super.init(self, parent, draw_layer, start_scale, definitions)

	self:set_scenegraph_position("root", 600 + (mod:get("timer_position_x") or 0), 620 + (mod:get("timer_position_y") or 0), 100)
end

HudElementAbilityTimerText.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementAbilityTimerText.super.update(self, dt, t, ui_renderer, render_settings, input_service)

	if mod:get("show_native_hud") == false then
		self:_set_visible(false)
		return
	end

	local ability_state = mod.get_ability_state()
	if not ability_state or not ability_state.timer_visible then
		self:_set_visible(false)
		return
	end

	self:_set_visible(true)

	local display_mode = mod:get("display_mode") or "both"
	local show_number = display_mode == "both" or display_mode == "timer_only"

	local text_widget = self._widgets_by_name.timer_text
	local alpha = mod:get("gauge_alpha") or 1.0

	text_widget.style.text.text_color[1] = 255 * alpha

	if show_number then
		text_widget.content.visible = true
		text_widget.style.text.text_horizontal_alignment = mod:get("timer_text_alignment") or "center"
		text_widget.style.text.font_size = mod:get("timer_text_size") or 28
		text_widget.content.text = ability_state.timer_text

		local text_color = text_widget.style.text.text_color
		local src = ability_state.text_color
		text_color[1] = 255 * alpha
		text_color[2] = src[2]
		text_color[3] = src[3]
		text_color[4] = src[4]
		text_widget.dirty = true
	else
		text_widget.content.visible = false
	end
end

HudElementAbilityTimerText._set_visible = function(self, visible)
	local widgets = self._widgets_by_name
	if not visible and widgets and widgets.timer_text then
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
