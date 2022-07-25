
-- Privates

local current_damages = {}

local function init_current_damages(id)
    if not current_damages[id] then
        current_damages[id] = {
            total_damage = 0,
            physical_damage = 0,
            base_physical_attack_damage = 0,
            physical_sharp_adjust = 0,
            critical_adjust = 0,
            element_damage = 0,
            base_element_attack_damage = 0,
            element_sharp_adjust = 0,
            condition_damages = {}, -- { [condition_type] = damage }
            hit_count = 0,
            crit_count = 0,
            bad_crit_count = 0,
            weapon_type = -1,
            physical_rate = 0,
            element_rate = 0,
            -- condition_rates = {}, -- { [condition_type] = rate } TODO
            other_rates = 0
        }
    end
end

local function merge_current_damages(id, damages)
    init_current_damages(id)
    local current = current_damages[id]
    current.total_damage = current.total_damage + damages.total_damage
    current.physical_damage = current.physical_damage + damages.physical_damage
    current.base_physical_attack_damage = current.base_physical_attack_damage + damages.base_physical_attack_damage
    current.physical_sharp_adjust = current.physical_sharp_adjust + damages.physical_sharp_adjust
    current.critical_adjust = current.critical_adjust + damages.critical_adjust
    current.element_damage = current.element_damage + damages.element_damage
    current.base_element_attack_damage = current.base_element_attack_damage + damages.base_element_attack_damage
    current.element_sharp_adjust = current.element_sharp_adjust + damages.element_sharp_adjust
    if not current.condition_damages[damages.condition_type] then
        current.condition_damages[damages.condition_type] = 0
    end
    current.condition_damages[damages.condition_type] = current.condition_damages[damages.condition_type] + damages.condition_damage
    current.hit_count = current.hit_count + damages.hit_count
    current.crit_count = current.crit_count + damages.crit_count
    current.bad_crit_count = current.bad_crit_count + damages.bad_crit_count
    current.weapon_type = damages.weapon_type
end


local function merge_damage_rate(id, rate)
    init_current_damages(id)
    local current = current_damages[id]
    current.physical_rate = current.physical_rate + rate.physical_meat_adjust_rate
    current.element_rate = current.element_rate + rate.element_meat_adjust_rate
    current.other_rates = current.other_rates + ((rate.difficulty_adjust_rate + rate.parts_vital_adjust_rate + rate.final_damage_adjust_rate + rate.unique_damage_rate) / 4)
end

local base_physical_attack_damage = {}
local physical_sharp_adjust = {}
local base_element_attack_damage = {}
local element_sharp_adjust = {}
local player_attack = {}

local function handle_damage_calc(args)
    local enemy = sdk.to_managed_object(args[2]);
    if not enemy then
        return
    end
    
    --[[ local is_boss_enemy = enemy:call('get_isBossEnemy');
    if not is_boss_enemy then
        return
    end]]--
    
    local dead_or_captured = enemy:call('checkDie');
    if dead_or_captured then
        return
    end
    
    local info = sdk.to_managed_object(args[3]) -- snow.hit.EnemyCalcDamageInfo.AfterCalcInfo_DamageSide
    local attacker_type = info:call('get_DamageAttackerType')
    -- Only care about player (0)
    if attacker_type ~= 0 then
        return
    end

    local attacker_id = info:call('get_AttackerID');
    local total_damage     = tonumber(info:call('get_TotalDamage'))
    local physical_damage  = tonumber(info:call('get_PhysicalDamage'))
    local element_damage   = tonumber(info:call('get_ElementDamage'))
    local condition_damage = tonumber(info:call('get_ConditionDamage'))
    local condition_type   = tonumber(info:call('get_ConditionDamageType')) -- snow.enemy.EnemyDef.ConditionDamageType
    local weapon_type      = tonumber(info:call('get_WeaponType')) -- snow.player.PlayerWeaponType
    
    local critical_type = tonumber(info:call('get_CriticalResult')) -- snow.hit.CriticalType (0: not, 1: crit, 2: bad crit)s
    local critical_adjust = 1.0

    -- Calcparam
    local damage_calc = sdk.to_managed_object(info:get_field('_CalcParam'))
    local damage_calc_params = nil

    if damage_calc then
        DEBUG_CALC_PARAM = damage_calc
        local src_physical_damage = tonumber(damage_calc:call('get_SrcPhysicalDamage'))
        local src_element_damage = tonumber(damage_calc:call('get_SrcElementDamage'))
        local physical_meat_adjust_rate = tonumber(damage_calc:call('get_PhysicalMeatAdjustRate'))
        local element_meat_adjust_rate = tonumber(damage_calc:call('get_ElementMeatAdjustRate'))
        local difficulty_adjust_rate = tonumber(damage_calc:call('get_DifficultyAdjustRate'))
        local parts_vital_adjust_rate = tonumber(damage_calc:call('get_PartsVitalAdjustRate'))
        local final_damage_adjust_rate = tonumber(damage_calc:call('get_FinalDamageAdjustRate'))
        local unique_damage_rate = tonumber(damage_calc:call('get_UniqueDamageRate'))

        damage_calc_params = {
            src_physical_damage = src_physical_damage,
            src_element_damage = src_element_damage,
            physical_meat_adjust_rate = physical_meat_adjust_rate,
            element_meat_adjust_rate = element_meat_adjust_rate,
            difficulty_adjust_rate = difficulty_adjust_rate,
            parts_vital_adjust_rate = parts_vital_adjust_rate,
            final_damage_adjust_rate = final_damage_adjust_rate,
            unique_damage_rate = unique_damage_rate
        }
        
        if player_attack[attacker_id] > 0 then
            critical_adjust = (src_physical_damage * 100) / (base_physical_attack_damage[attacker_id] * player_attack[attacker_id] * physical_sharp_adjust[attacker_id])
        end
        
    end

    log.info("attacker_id: " .. attacker_id .. " total_damage: " .. total_damage .. " physical_damage: " .. physical_damage .. " element_damage: " .. element_damage)
    
    if total_damage > 0 then
        local damages = {
            total_damage = total_damage,
            physical_damage = physical_damage,
            base_physical_attack_damage = base_physical_attack_damage[attacker_id],
            physical_sharp_adjust = physical_sharp_adjust[attacker_id],
            critical_adjust = critical_adjust,
            element_damage = element_damage,
            base_element_attack_damage = base_element_attack_damage[attacker_id],
            element_sharp_adjust = element_sharp_adjust[attacker_id],
            condition_damage = condition_damage,
            condition_type = condition_type,
            hit_count = 1,
            crit_count = 0,
            bad_crit_count = 0,
            weapon_type = weapon_type
        }
        if critical_type == 1 then
            damages.crit_count = 1
        elseif critical_type == 2 then
            damages.bad_crit_count = 1
        end
        merge_current_damages(attacker_id, damages)

        if damage_calc_params ~= nil then
            log.info("src_physical_damage: " .. damage_calc_params.src_physical_damage)
            log.info("src_element_damage: " .. damage_calc_params.src_element_damage)
            log.info("physical_meat_adjust_rate: " .. damage_calc_params.physical_meat_adjust_rate)
            log.info("element_meat_adjust_rate: " .. damage_calc_params.element_meat_adjust_rate)
            log.info("difficulty_adjust_rate: " .. damage_calc_params.difficulty_adjust_rate)
            log.info("parts_vital_adjust_rate: " .. damage_calc_params.parts_vital_adjust_rate)
            log.info("final_damage_adjust_rate: " .. damage_calc_params.final_damage_adjust_rate)
            log.info("unique_damage_rate: " .. damage_calc_params.unique_damage_rate)
            merge_damage_rate(attacker_id, damage_calc_params)
            damage_calc_params = nil
        end

        base_physical_attack_damage[attacker_id]= 0
        physical_sharp_adjust[attacker_id] = 0
        base_element_attack_damage[attacker_id] = 0
        element_sharp_adjust[attacker_id] = 0
        player_attack[attacker_id] = 0
    end
end

local function handle_calc_physical_result(args)
    local player = sdk.to_managed_object(args[2])
    if not player then
        return
    end

    local member_index = tonumber(player:call("getPlayerIndex"))
    if member_index < 0 then
        member_index = 0
    end
    local attack_data = sdk.to_managed_object(args[3])

    base_physical_attack_damage[member_index] = tonumber(attack_data:call('get_TotalDamage'))
    base_element_attack_damage[member_index] = tonumber(attack_data:call('get_AttackElementValue'))

    physical_sharp_adjust[member_index] = player:call('getPhysicalSharpnessAdjust', attack_data, player)
    element_sharp_adjust[member_index] = player:call('getElementSharpnessAdjust', attack_data, player)

    local player_data = sdk.to_managed_object(player:call('get_PlayerData'))
    player_attack[member_index] = player_data:get_field("_Attack")

    -- result = (base_damage * player_attack * sharpness * crit) / 100
end



local function test_hook(args)
    log.info("test_hook")

    local arg_this = sdk.to_managed_object(args[2])
    log.info("arg_this: " .. arg_this:get_type_definition():get_full_name())

    local arg1 = sdk.to_float(args[3])
    log.info("arg1: " .. arg1) -- snow.hit.userdata.PlHitAttackRSData
    --local arg2 = sdk.to_managed_object(args[4])
    --log.info("arg2: " .. arg2:get_type_definition():get_full_name()) -- snow.player.LongSword
    --local arg3 = sdk.to_managed_object(args[5])
    --log.info("arg3: " .. arg3:get_type_definition():get_full_name())

    --local base_damage = tonumber(arg1:call('get_BaseDamage'))
    --log.info("base_damage: " .. base_damage)
    --local total_damage = tonumber(arg1:call('get_TotalDamage'))
    -- result = (base_damage * player_attack * sharpness * crit) / 100
end

local function log_retval(retval)
    log.info("retval: " .. sdk.to_float(retval))
    return retval
end

-- Hooks

local enemy_character_base_type_def = sdk.find_type_definition('snow.enemy.EnemyCharacterBase');
local enemy_character_base_after_calc_damage_damage_side = enemy_character_base_type_def:get_method('afterCalcDamage_DamageSide');
sdk.hook(enemy_character_base_after_calc_damage_damage_side,
    function(args) handle_damage_calc(args); end,
    function(retval) return retval; end
);

-- snow.player.PlayerQuestBase calcHitReduceSharpness

local player_player_quest_base = sdk.find_type_definition('snow.player.PlayerQuestBase');
local player_player_quest_base_calc_charpness = player_player_quest_base:get_method('calcNormalPhysicalAttackResult');
sdk.hook(player_player_quest_base_calc_charpness,
    function(args) handle_calc_physical_result(args); end,
    function(retval) return retval; end
);


-- Publics

local this = {}

this.get_damages = function(id)
    if id == -1 then id = 0 end
    return current_damages[id]
end

this.reset_damages = function(id)
    if id == -1 then id = 0 end
    current_damages[id] = nil
end

return this