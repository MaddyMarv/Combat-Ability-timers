local mod = get_mod("ability_timer")

local packages_to_load = {
	"packages/ui/hud/player_buffs/player_buffs",
	"packages/ui/hud/player_ability/player_ability",
}

mod.on_enabled = function()
	for _, package_path in ipairs(packages_to_load) do
		Managers.package:load(package_path, mod:get_name(), nil, true)
	end

	mod:register_hud_element({
		class_name = "HudElementAbilityTimer",
		filename = "ability_timer/scripts/mods/ability_timer/HudElementAbilityTimer",
		visibility_groups = {
			"alive",
		},
		use_hud_scale = false,
	})
end

mod.tracked_deployables = {}

local function _add_deployable(unit, name, duration, icon, game_session, game_object_id, max_health)
    if not unit then return end
    mod.tracked_deployables[unit] = {
        name = name,
        start_time = Managers.time:time("gameplay"),
        duration = duration,
        icon = icon,
        game_session = game_session,
        game_object_id = game_object_id,
        max_health = max_health,
        current_health = max_health,
        damage_taken = 0,
        last_poll_time = -math.huge
    }
end

local function _remove_deployable(unit)
    if not unit then return end
    mod.tracked_deployables[unit] = nil
end

mod:hook_safe("PsykerForceFieldUnitExtension", "init", function(self, context, unit, extension_init_data, game_session, game_object_id)
    local owner_unit = self.owner_unit or extension_init_data.owner_unit
    local local_player = Managers.player:local_player(1)

    if local_player and owner_unit == local_player.player_unit then
        local icon = "content/ui/textures/icons/abilities/hud/psyker/psyker_ability_force_field"
        local talent_settings = require("scripts/settings/talent/talent_settings")
        local shield_settings = talent_settings.psyker_3.combat_ability
        local is_bubble = self:is_sphere_shield()
        local max_health = is_bubble and shield_settings.sphere_health or shield_settings.health

        _add_deployable(unit, "psyker_shield", self._max_duration or 20, icon, game_session, game_object_id, max_health)
    end
end)

mod:hook_safe("PsykerForceFieldUnitExtension", "on_death", function(self)
    _remove_deployable(self._unit)
end)

mod:hook_safe("PsykerForceFieldUnitExtension", "destroy", function(self)
    _remove_deployable(self._unit)
end)

mod:hook_safe("PsykerForceFieldUnitExtension", "game_object_initialized", function(self, session, object_id)
    local deployable = mod.tracked_deployables[self._unit]
    if deployable and deployable.name == "psyker_shield" then
        deployable.game_session = session
        deployable.game_object_id = object_id
    end
end)

mod:hook_safe("UnitSpawnerManager", "spawn_husk_unit", function(self, game_object_id, owner_id)
    local session = self._game_session
    local unit = self._network_units[game_object_id]
    if not unit then return end

    local local_player = Managers.player:local_player(1)
    if not local_player then return end

    local unit_template_id = GameSession.game_object_field(session, game_object_id, "unit_template")
    local unit_template_name = self._unit_template_network_lookup[unit_template_id]

    if unit_template_name == "broker_stimm_field_crate_deployable" then
        local owner_unit_id = GameSession.game_object_field(session, game_object_id, "owner_unit_id")
        if owner_unit_id ~= NetworkConstants.invalid_game_object_id then
            local owner_unit = Managers.state.unit_spawner:unit(owner_unit_id)
            if owner_unit and owner_unit == local_player.player_unit then
                local talent_settings = require("scripts/settings/talent/talent_settings")
                local ability_settings = talent_settings.broker.combat_ability.stimm_field
                local lifetime = ability_settings.life_time

                local owner_talent_extension = ScriptUnit.has_extension(owner_unit, "talent_system")
                if owner_talent_extension and owner_talent_extension:has_special_rule("broker_stimm_field_linger") then
                    lifetime = ability_settings.sub_1_life_time
                end

                _add_deployable(unit, "broker_stimm_field", lifetime, "content/ui/textures/icons/buffs/hud/broker/broker_stimm_field")
            end
        end

    elseif unit_template_name == "item_deployable_projectile" then
        local owner_unit_id = GameSession.game_object_field(session, game_object_id, "owner_unit_id")
        if owner_unit_id ~= NetworkConstants.invalid_game_object_id then
            local owner_unit = Managers.state.unit_spawner:unit(owner_unit_id)
            if owner_unit and owner_unit == local_player.player_unit then
                local item_id = GameSession.game_object_field(session, game_object_id, "item_id")
                local item_name = NetworkLookup.player_item_names[item_id]

                if item_name == "content/items/weapons/player/drone_area_buff" then
                    _add_deployable(unit, "adamant_drone", 20, "content/ui/textures/icons/abilities/hud/adamant/adamant_ability_area_buff_drone")
                end
            end
        end
    end
end)

mod:hook_safe("UnitSpawnerManager", "_remove_network_unit", function(self, unit)
    _remove_deployable(unit)
end)

mod:hook_safe("ProximityBrokerStimmField", "init", function(self, context, init_data, owner_unit)
    local is_owner = owner_unit == Managers.player:local_player(1).player_unit
    if is_owner then
        _add_deployable(self._unit, "broker_stimm_field", self._life_time, "content/ui/textures/icons/buffs/hud/broker/broker_stimm_field")
    end
end)

mod:hook_safe("ProximityAreaBuffDrone", "init", function(self, context, init_data, owner_unit)
    local is_owner = owner_unit == Managers.player:local_player(1).player_unit
    if is_owner then
        _add_deployable(self._unit, "adamant_drone", self._life_time, "content/ui/textures/icons/abilities/hud/adamant/adamant_ability_area_buff_drone")
    end
end)

local POLL_INTERVAL = 0.05

local function _update_bubble_health(unit, health_extension, game_session, game_object_id, is_server)
    local deployable = mod.tracked_deployables[unit]
    if not deployable or deployable.name ~= "psyker_shield" then return end

    if not is_server then
        if game_session and game_object_id then
            deployable.current_health = GameSession.game_object_field(game_session, game_object_id, "health") or deployable.max_health
        end
    else
        if health_extension then
            deployable.current_health = health_extension:current_health() or deployable.max_health
        end
    end

    deployable.damage_taken = math.max(0, deployable.max_health - deployable.current_health)
end

mod:hook_safe("PsykerForceFieldUnitHealthExtension", "_add_damage", function(self, damage)
    local unit = self._unit
    local deployable = mod.tracked_deployables[unit]
    if deployable and deployable.name == "psyker_shield" then
        _update_bubble_health(unit, self, self._game_session, self._game_object_id, true)
    end
end)

mod:hook_safe("PsykerForceFieldUnitExtension", "fixed_update", function(self, unit, dt, t)
    local deployable = mod.tracked_deployables[unit]
    if not deployable or deployable.name ~= "psyker_shield" then return end
    if (t - deployable.last_poll_time) <= POLL_INTERVAL then return end

    _update_bubble_health(unit, self._health_extension, self._game_session, self._game_object_id, self._is_server)
    deployable.last_poll_time = t
end)



