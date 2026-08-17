local mod = get_mod("ability_timer")

require("scripts/ui/hud/elements/hud_element_base")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local HudElementAbilityTimerCharges = class("HudElementAbilityTimerCharges", "HudElementBase")

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
			position = { 695, 620, 100 },
		},
		charges_text = {
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
		charges_text = UIWidget.create_definition({
			{
				visible = false,
				pass_type = "text",
				style_id = "text",
				value = "",
				value_id = "text",
				style = text_style,
			},
		}, "charges_text"),
	}
end

local function _apply_dynamic_color(current, max, color)
    local fraction = 0
    if max > 0 then
        fraction = current / max
    end
    fraction = math.max(0, math.min(1, fraction))

    local r, g
    if fraction == 1 then
        r = 0
        g = 255
    elseif fraction == 0 then
        r = 255
        g = 0
    else
        r = 255
        g = 255
    end

    color[2] = r
    color[3] = g
    color[4] = 0
end

local function _get_equipped_combat_ability(ability_extension)
	local equipped = ability_extension and ability_extension:equipped_abilities()
	return equipped and equipped[COMBAT_ABILITY_TYPE]
end

HudElementAbilityTimerCharges.init = function(self, parent, draw_layer, start_scale)
	local definitions = {
		scenegraph_definition = _create_scenegraph(),
		widget_definitions = _create_widgets(),
	}

	HudElementAbilityTimerCharges.super.init(self, parent, draw_layer, start_scale, definitions)

	local widgets = self._widgets_by_name
	self._default_text_color = table.clone(widgets.charges_text.style.text.text_color)
end

HudElementAbilityTimerCharges.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementAbilityTimerCharges.super.update(self, dt, t, ui_renderer, render_settings, input_service)

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

	local max_charges = ability_extension:max_ability_charges(COMBAT_ABILITY_TYPE)
	if not max_charges or max_charges <= 0 then
		self:_set_visible(false)
		return
	end

    local remaining_charges = ability_extension:remaining_ability_charges(COMBAT_ABILITY_TYPE) or 0
    remaining_charges = math.floor(remaining_charges + 0.0001)

    local show_charges = mod:get("show_charges") ~= false
    local always_show = mod:get("always_show_charges") ~= false

    if not show_charges then
        self:_set_visible(false)
        return
    end

    if remaining_charges <= 1 and not always_show then
        self:_set_visible(false)
        return
    end

	self:_set_visible(true)

	local text_widget = self._widgets_by_name.charges_text
	local alpha = mod:get("gauge_alpha") or 1.0
	local pos_x = mod:get("charges_position_x") or 0
	local pos_y = mod:get("charges_position_y") or 0
	
	text_widget.style.text.text_horizontal_alignment = mod:get("charges_text_alignment") or "center"

	local root_pos = self._ui_scenegraph.root.position
	root_pos[1] = 695 + pos_x
	root_pos[2] = 620 + pos_y

	text_widget.style.text.text_color[1] = 255 * alpha

    text_widget.content.visible = true
    text_widget.content.text = string.format("%d", remaining_charges)
    local text_color = text_widget.style.text.text_color
    
    local use_color = mod:get("use_progress_color") ~= false
    if use_color then
        _apply_dynamic_color(remaining_charges, max_charges, text_color)
    else
        text_color[1] = 255 * alpha
        text_color[2] = self._default_text_color[2]
        text_color[3] = self._default_text_color[3]
        text_color[4] = self._default_text_color[4]
    end
    text_widget.dirty = true
end

HudElementAbilityTimerCharges._set_visible = function(self, visible)
	local widgets = self._widgets_by_name
	if not visible then
		widgets.charges_text.content.visible = false
	end
end

HudElementAbilityTimerCharges.draw = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementAbilityTimerCharges.super.draw(self, dt, t, ui_renderer, render_settings, input_service)
end

HudElementAbilityTimerCharges.destroy = function(self, ui_renderer)
	HudElementAbilityTimerCharges.super.destroy(self, ui_renderer)
end

return HudElementAbilityTimerCharges
