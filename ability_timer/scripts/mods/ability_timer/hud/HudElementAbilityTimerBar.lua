local mod = get_mod("ability_timer")

require("scripts/ui/hud/elements/hud_element_base")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local HudElementAbilityTimerBar = class("HudElementAbilityTimerBar", "HudElementBase")

local function _create_scenegraph()
	local bar_w = 210
	local bar_h = 15

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
			size = { 210, 15 },
			position = { 600, 653.6, 100 },
		},
		bar = {
			parent = "root",
			horizontal_alignment = "left",
			vertical_alignment = "top",
			size = { bar_w, bar_h },
			position = { 0, 0, 0 },
		},
	}
end

local function _create_widgets()
	return {
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

HudElementAbilityTimerBar.init = function(self, parent, draw_layer, start_scale)
	local definitions = {
		scenegraph_definition = _create_scenegraph(),
		widget_definitions = _create_widgets(),
	}

	HudElementAbilityTimerBar.super.init(self, parent, draw_layer, start_scale, definitions)

	self:set_scenegraph_position("root", 600 + (mod:get("bar_position_x") or 0), 653.6 + (mod:get("bar_position_y") or 0), 100)
end

HudElementAbilityTimerBar.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementAbilityTimerBar.super.update(self, dt, t, ui_renderer, render_settings, input_service)

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
	local show_bar = display_mode == "both" or display_mode == "progress_only"

	local bar_bg = self._widgets_by_name.bar_bg
	local bar_fill = self._widgets_by_name.bar_fill
	local bracket = self._widgets_by_name.bracket

	local gauge_len = mod:get("gauge_length") or 210
	local gauge_thick = mod:get("gauge_thick") or 15
	local orientation = mod:get("comp_orientation") or 0
	local bar_dir = mod:get("bar_direction") or 1
	local alpha = mod:get("gauge_alpha") or 1.0

	local full_w = gauge_len
	local bar_h = gauge_thick
	local is_vertical = orientation == 1

	bar_bg.style.rect.color[1] = 160 * alpha
	bar_fill.style.rect.color[1] = 255 * alpha
	bracket.style.bracket.color[1] = 255 * alpha

	local frac = ability_state.fraction

	if show_bar then
		bar_bg.content.visible = true
		bar_fill.content.visible = true

		if is_vertical then
			self:_set_scenegraph_size("bar", bar_h, full_w)
		else
			self:_set_scenegraph_size("bar", full_w, bar_h)
		end

		if mod:get("show_bracket") ~= false then
			bracket.content.visible = true
			local spacing = 0
			bracket.style.bracket.size = { full_w + spacing, bar_h }
			bracket.style.bracket.pivot = { (full_w + spacing) / 2, bar_h / 2 }
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
			bar_fill.style.rect.offset = { 0, 0, 1 }

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
			bar_fill.style.rect.offset = { 0, 0, 1 }

			if bar_dir == 2 then
				bar_fill.style.rect.horizontal_alignment = "right"
			elseif bar_dir == 3 then
				bar_fill.style.rect.horizontal_alignment = "center"
			end
		end

		local bar_color = bar_fill.style.rect.color
		local src = ability_state.bar_color
		bar_color[1] = 255 * alpha
		bar_color[2] = src[2]
		bar_color[3] = src[3]
		bar_color[4] = src[4]
		bar_fill.dirty = true
		bracket.dirty = true
	else
		bar_bg.content.visible = false
		bar_fill.content.visible = false
		bracket.content.visible = false
	end
end

HudElementAbilityTimerBar._set_visible = function(self, visible)
	local widgets = self._widgets_by_name
	if not visible and widgets then
		if widgets.bar_bg then widgets.bar_bg.content.visible = false end
		if widgets.bar_fill then widgets.bar_fill.content.visible = false end
		if widgets.bracket then widgets.bracket.content.visible = false end
	end
end

HudElementAbilityTimerBar.draw = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementAbilityTimerBar.super.draw(self, dt, t, ui_renderer, render_settings, input_service)
end

HudElementAbilityTimerBar.destroy = function(self, ui_renderer)
	HudElementAbilityTimerBar.super.destroy(self, ui_renderer)
end

return HudElementAbilityTimerBar
