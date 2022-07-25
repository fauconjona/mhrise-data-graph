local UTIL   = require('mhrise-data-graph/util')
local DAMAGE   = require('mhrise-data-graph/modules/hunters/damages')

-- Privates 

local hunters = nil
local start_time = 0

local function init_hunters()
    hunters = UTIL.get_hunters()

    log.info("hunters:")
    log.info(json.dump_string(hunters))

    for _, hunter in ipairs(hunters) do
        hunter.offset = 0
        
        -- damages
        hunter.total_damages = {}
        hunter.physical_damages = {}
        hunter.base_physical_attacks = {}
        hunter.physical_sharp_adjusts = {}
        hunter.critical_adjusts = {}
        hunter.elemental_damages = {}
        hunter.base_elemental_attacks = {}
        hunter.elemental_sharp_adjusts = {}
        hunter.hits = {}
        hunter.criticals = {}
        hunter.bad_criticals = {}
        hunter.conditionals = {{}, {}, {}, {}, {}, {}}
        hunter.weapon_types = {}
        hunter.physical_rates = {}
        hunter.elemental_rates = {}
        hunter.other_rates = {}

        -- datas
        hunter.attacks = {}
        hunter.element_attacks = {}
        hunter.defences = {}
        hunter.critical_rates = {}
        hunter.vitals = {}
    end
end

-- Publics

local this = {}
this.started = false

this.init = function()    
    log.info('Hunters module initialized')
end

this.start = function()
    this.started = true
    start_time = UTIL.get_time()

    init_hunters()

    log.info('Hunters module started')
end

this.results = function()
    return hunters
end

this.stop = function()
    this.started = false
    log.info('Hunters module stopped')
end

this.update = function()
    if not this.started then
        return
    end

    -- check there is a new hunter
    local newHunters = UTIL.get_hunters()
    if #newHunters ~= #hunters then
        log.info("New hunters detected")
        for _, newHunter in ipairs(newHunters) do
            local found = false
            for _, hunter in ipairs(hunters) do
                if newHunter.id == hunter.id then
                    found = true
                    break
                end
            end
            if not found then
                newHunter.total_damages = {}
                newHunter.physical_damages = {}
                newHunter.base_physical_attacks = {}
                newHunter.physical_sharp_adjusts = {}
                newHunter.critical_adjusts = {}
                newHunter.elemental_damages = {}
                newHunter.base_elemental_attacks = {}
                newHunter.elemental_sharp_adjusts = {}
                newHunter.hits = {}
                newHunter.criticals = {}
                newHunter.bad_criticals = {}
                newHunter.conditionals = {{}, {}, {}, {}, {}, {}}
                newHunter.offset = UTIL.get_time() - start_time
                newHunter.weapon_types = {}
                newHunter.physical_rates = {}
                newHunter.elemental_rates = {}
                newHunter.other_rates = {}
                
                newHunter.attacks = {}
                newHunter.element_attacks = {}
                newHunter.defences = {}
                newHunter.critical_rates = {}
                newHunter.vitals = {}

                table.insert(hunters, newHunter)
                log.info("New hunter detected: " .. newHunter.name)
                log.info(json.dump_string(newHunter))
            end
        end
    end


    --for each hunter
    for _, hunter in ipairs(hunters) do
        local damages = DAMAGE.get_damages(hunter.id)
        
        if damages == nil then
            table.insert(hunter.total_damages, 0)
            table.insert(hunter.physical_damages, 0)
            table.insert(hunter.base_physical_attacks, 0)
            table.insert(hunter.physical_sharp_adjusts, 0)
            table.insert(hunter.critical_adjusts, 0)
            table.insert(hunter.elemental_damages, 0)
            table.insert(hunter.base_elemental_attacks, 0)
            table.insert(hunter.elemental_sharp_adjusts, 0)
            table.insert(hunter.hits, 0)
            table.insert(hunter.criticals, 0)
            table.insert(hunter.bad_criticals, 0)
            for _, condition in ipairs(hunter.conditionals) do
                table.insert(condition, 0)
            end
            table.insert(hunter.weapon_types, -1)
            table.insert(hunter.physical_rates, 0)
            table.insert(hunter.elemental_rates, 0)
            table.insert(hunter.other_rates, 0)
        else
            table.insert(hunter.total_damages, damages.total_damage)
            table.insert(hunter.physical_damages, damages.physical_damage)
            table.insert(hunter.base_physical_attacks, damages.base_physical_attack_damage)
            table.insert(hunter.physical_sharp_adjusts, damages.physical_sharp_adjust / damages.hit_count)
            table.insert(hunter.critical_adjusts, damages.critical_adjust / damages.hit_count)
            table.insert(hunter.elemental_damages, damages.element_damage)
            table.insert(hunter.base_elemental_attacks, damages.base_element_attack_damage)
            table.insert(hunter.elemental_sharp_adjusts, damages.element_sharp_adjust / damages.hit_count)
            table.insert(hunter.hits, damages.hit_count)
            table.insert(hunter.criticals, damages.crit_count)
            table.insert(hunter.bad_criticals, damages.bad_crit_count)
            for i, condition in ipairs(hunter.conditionals) do
                local condition_damage = damages.condition_damages[i]
                if condition_damage ~= nil then
                    table.insert(condition, condition_damage)
                else
                    table.insert(condition, 0)
                end
            end
            table.insert(hunter.weapon_types, damages.weapon_type)
            table.insert(hunter.physical_rates, damages.physical_rate / damages.hit_count)
            table.insert(hunter.elemental_rates, damages.element_rate / damages.hit_count)
            table.insert(hunter.other_rates, damages.other_rates / damages.hit_count)
        end

        DAMAGE.reset_damages(hunter.id)

        local datas = UTIL.get_player_data(hunter.id)

        if datas == nil then 
            table.insert(hunter.attacks, 0)
            table.insert(hunter.element_attacks, 0)
            table.insert(hunter.defences, 0)
            table.insert(hunter.critical_rates, 0)
            table.insert(hunter.vitals, 0)
        else
            table.insert(hunter.attacks, datas.attack)
            table.insert(hunter.element_attacks, datas.element_attack)
            table.insert(hunter.defences, datas.defence)
            table.insert(hunter.critical_rates, datas.critical)
            table.insert(hunter.vitals, datas.vital)
        end
    end
end

return this