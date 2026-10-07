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
			position = { 600, 654, 100 },
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

local MAX_SEGMENTS = 10
local MAX_NOTCHES = 20

local function _create_widgets()
	local bg_passes = {}
	local fill_passes = {}
	local notch_passes = {}

	for i = 1, MAX_SEGMENTS do
		bg_passes[i] = {
			visible = false,
			pass_type = "rect",
			style_id = "rect_" .. i,
			style = {
				color = { 160, 0, 0, 0 },
				offset = { 0, 0, 0 },
				size = { 0, 0 },
			},
		}
		fill_passes[i] = {
			visible = false,
			pass_type = "rect",
			style_id = "rect_" .. i,
			style = {
				color = { 220, 255, 255, 255 },
				offset = { 0, 0, 1 },
				size = { 0, 0 },
			},
		}
	end

	for i = 1, MAX_NOTCHES do
		notch_passes[i] = {
			visible = false,
			pass_type = "rect",
			style_id = "notch_" .. i,
			style = {
				vertical_alignment = "top",
				horizontal_alignment = "left",
				color = { 255, 88, 99, 80 },
				offset = { 0, 0, 5 },
				size = { 0, 0 },
			},
		}
	end

	return {
		bar_bg = UIWidget.create_definition(bg_passes, "bar"),
		bar_fill = UIWidget.create_definition(fill_passes, "bar"),
		bar_notches = UIWidget.create_definition(notch_passes, "bar"),
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

	self:set_scenegraph_position("root", 600 + (mod:get("bar_position_x") or 0), 654 + (mod:get("bar_position_y") or 0), 100)
end

HudElementAbilityTimerBar.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementAbilityTimerBar.super.update(self, dt, t, ui_renderer, render_settings, input_service)

	if mod:get("show_native_hud") == false then
		self:_set_visible(false)
		return
	end

	local ability_state = mod.get_ability_state()
	if not ability_state or not (ability_state.bar_visible or ability_state.timer_visible) then
		self:_set_visible(false)
		return
	end

	self:_set_visible(true)

	local display_mode = mod:get("display_mode") or "both"
	local show_bar = display_mode == "both" or display_mode == "progress_only"

	local bar_bg = self._widgets_by_name.bar_bg
	local bar_fill = self._widgets_by_name.bar_fill
	local bar_notches = self._widgets_by_name.bar_notches
	local bracket = self._widgets_by_name.bracket

	local gauge_len = mod:get("gauge_length") or 210
	local gauge_thick = mod:get("gauge_thick") or 15
	local orientation = mod:get("comp_orientation") or 0
	local bar_dir = mod:get("bar_direction") or 1
	local alpha = mod:get("gauge_alpha") or 1.0

	local full_w = gauge_len
	local bar_h = gauge_thick
	local is_vertical = orientation == 1

	bracket.style.bracket.color[1] = 255 * alpha

	local frac = ability_state.fraction or 0

	if show_bar then
		bar_bg.content.visible = true
		bar_fill.content.visible = true
		bar_notches.content.visible = true

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

		local num_segments = math.clamp(ability_state.segments or 1, 1, MAX_SEGMENTS)
		local gap = (num_segments > 1) and (ability_state.segment_gap or 3) or 0

		local total_gaps = (num_segments - 1) * gap
		local seg_len = math.max(1, math.floor((full_w - total_gaps) / num_segments))
		local src_color = ability_state.bar_color
		local charges = ability_state.charges or 0
		local ready_color = mod:get("ready_charge_color") or { 255, 17, 90, 239 }

		local seg_fractions = ability_state.segment_fractions
		for i = 1, num_segments do
			local seg_frac = (seg_fractions and seg_fractions[i])
			if not seg_frac then
				if num_segments == 1 then
					seg_frac = frac
				else
					local seg_lo = (i - 1) / num_segments
					local seg_hi = i / num_segments
					if frac >= seg_hi then
						seg_frac = 1.0
					elseif frac <= seg_lo then
						seg_frac = 0.0
					else
						seg_frac = (frac - seg_lo) * num_segments
					end
				end
			end
			seg_frac = math.clamp(seg_frac, 0, 1)
			local fill_size = math.floor(seg_len * seg_frac)

			local bg_style = bar_bg.style["rect_" .. i]
			local fill_style = bar_fill.style["rect_" .. i]

			bg_style.color[1] = 160 * alpha

			local is_ready_block = (num_segments > 1 and i <= charges) or ability_state.mode == "ready"
			local seg_color = (ability_state.segment_colors and ability_state.segment_colors[i]) or (is_ready_block and ready_color or src_color)
			fill_style.color[1] = (seg_color[1] or 255) * alpha
			fill_style.color[2] = seg_color[2]
			fill_style.color[3] = seg_color[3]
			fill_style.color[4] = seg_color[4]

			if is_vertical then
				local seg_start
				local fill_offset_y
				if bar_dir == 1 then
					seg_start = full_w - (i * seg_len + (i - 1) * gap)
					fill_offset_y = seg_start + (seg_len - fill_size)
				elseif bar_dir == 3 then
					seg_start = (i - 1) * (seg_len + gap)
					fill_offset_y = seg_start + math.floor((seg_len - fill_size) / 2)
				else
					seg_start = (i - 1) * (seg_len + gap)
					fill_offset_y = seg_start
				end

				bg_style.size = { bar_h, seg_len }
				bg_style.offset = { 0, seg_start, 0 }

				fill_style.size = { bar_h, fill_size }
				fill_style.offset = { 0, fill_offset_y, 1 }
				fill_style.horizontal_alignment = "left"
				fill_style.vertical_alignment = "top"
			else
				local seg_start
				local fill_offset_x
				if bar_dir == 2 then
					seg_start = full_w - (i * seg_len + (i - 1) * gap)
					fill_offset_x = seg_start + (seg_len - fill_size)
				elseif bar_dir == 3 then
					seg_start = (i - 1) * (seg_len + gap)
					fill_offset_x = seg_start + math.floor((seg_len - fill_size) / 2)
				else
					seg_start = (i - 1) * (seg_len + gap)
					fill_offset_x = seg_start
				end

				bg_style.size = { seg_len, bar_h }
				bg_style.offset = { seg_start, 0, 0 }

				fill_style.size = { fill_size, bar_h }
				fill_style.offset = { fill_offset_x, 0, 1 }
				fill_style.horizontal_alignment = "left"
				fill_style.vertical_alignment = "center"
			end
		end

		for j = num_segments + 1, MAX_SEGMENTS do
			local bg_style = bar_bg.style["rect_" .. j]
			local fill_style = bar_fill.style["rect_" .. j]
			bg_style.size = { 0, 0 }
			bg_style.color[1] = 0
			fill_style.size = { 0, 0 }
			fill_style.color[1] = 0
		end

		local notches_per_seg = ability_state.notches_per_seg or 0
		local notch_count = 0
		local notch_c = ability_state.notch_color or { 255, 88, 99, 80 }
		local notch_len_pct = ability_state.notch_len_pct or 0.5

		local ui_scale = RESOLUTION_LOOKUP and RESOLUTION_LOOKUP.scale or 1
		local root_pos_x = 600 + (mod:get("bar_position_x") or 0)
		local root_pos_y = 654 + (mod:get("bar_position_y") or 0)
		local notch_thickness = math.max(1, (ability_state.notch_width or 2) / ui_scale)

		if notches_per_seg > 0 then
			for i = 1, num_segments do
				local seg_start
				if is_vertical then
					if bar_dir == 1 then
						seg_start = full_w - (i * seg_len + (i - 1) * gap)
					else
						seg_start = (i - 1) * (seg_len + gap)
					end
				else
					if bar_dir == 2 then
						seg_start = full_w - (i * seg_len + (i - 1) * gap)
					else
						seg_start = (i - 1) * (seg_len + gap)
					end
				end

				for k = 1, notches_per_seg do
					notch_count = notch_count + 1
					if notch_count <= MAX_NOTCHES then
						local notch_style = bar_notches.style["notch_" .. notch_count]
						local notch_pos = seg_start + math.floor((k / (notches_per_seg + 1)) * seg_len)
						notch_style.color[1] = (notch_c[1] or 255) * alpha
						notch_style.color[2] = notch_c[2]
						notch_style.color[3] = notch_c[3]
						notch_style.color[4] = notch_c[4]

						local notch_len = math.max(2, math.floor(bar_h * notch_len_pct))
						if is_vertical then
							local screen_notch_y = math.round((root_pos_y + notch_pos) * ui_scale) - 1
							local snapped_offset_y = (screen_notch_y - (root_pos_y * ui_scale)) / ui_scale
							notch_style.size = { notch_len, notch_thickness }
							notch_style.offset = { 0, snapped_offset_y, 5 }
						else
							local screen_notch_x = math.round((root_pos_x + notch_pos) * ui_scale) - 1
							local snapped_offset_x = (screen_notch_x - (root_pos_x * ui_scale)) / ui_scale
							notch_style.size = { notch_thickness, notch_len }
							notch_style.offset = { snapped_offset_x, 0, 5 }
						end
					end
				end
			end
		end

		for m = notch_count + 1, MAX_NOTCHES do
			local notch_style = bar_notches.style["notch_" .. m]
			notch_style.size = { 0, 0 }
			notch_style.color[1] = 0
		end

		bar_bg.dirty = true
		bar_fill.dirty = true
		bar_notches.dirty = true
		bracket.dirty = true
	else
		bar_bg.content.visible = false
		bar_fill.content.visible = false
		bar_notches.content.visible = false
		bracket.content.visible = false
	end
end

HudElementAbilityTimerBar._set_visible = function(self, visible)
	local widgets = self._widgets_by_name
	if not visible and widgets then
		if widgets.bar_bg then widgets.bar_bg.content.visible = false end
		if widgets.bar_fill then widgets.bar_fill.content.visible = false end
		if widgets.bar_notches then widgets.bar_notches.content.visible = false end
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
