local this = {}

-- Private

local app_type = sdk.find_type_definition('via.Application')
local get_elapsed_second = app_type:get_method('get_UpTimeSecond')

-- Singleton
local lobby_manager

local function check_lobby_manager()
    if lobby_manager == nil then
        lobby_manager = sdk.get_managed_singleton("snow.LobbyManager")
    end
end

local player_manager

local function check_player_manager()
    if player_manager == nil then
        player_manager = sdk.get_managed_singleton("snow.player.PlayerManager")
    end
end



local local_player_id = 0

-- Public

this.get_time = function()
    return get_elapsed_second:call(nil)
end

this.init_local_player_id = function()
    check_player_manager()
    local_player_id = player_manager:call("getMasterPlayerID")
end

-- Only in quest
this.get_hunter = function(id)    
    check_lobby_manager()
    local hunterInfo = lobby_manager:get_field("_questHunterInfo")
    
    if hunterInfo then
        local hunterCount = hunterInfo:call("get_Count")
        if hunterCount then
            for i = 0, hunterCount-1 do
                local hunter = hunterInfo:call("get_Item", i)
                if hunter then
                    local playerId = hunter:get_field("_memberIndex")
                    if playerId == id then
                        local name = hunter:get_field("_name")
                        local rank = hunter:get_field("_hunterRank")
                        local rank2 = hunter:get_field("_masterRank")
                        return {
                            id = playerId,
                            name = name,
                            rank = rank,
                            rank2 = rank2
                        }
                    end
                end
            end
        end
    end

    if id == local_player_id then
        local hunter = lobby_manager:get_field("_myHunterInfo")
        local playerId = hunter:get_field("_memberIndex")
        local name = hunter:get_field("_name")
        local rank = hunter:get_field("_hunterRank")
        local rank2 = hunter:get_field("_masterRank")
        return {
            id = playerId,
            name = name,
            rank = rank,
            rank2 = rank2
        }
    end

    --_HunterUniqueId -> GUID

    -- player_manager:call("getPlayer", id)
    -- -> snow.player.PlayerBase
    -- attack = snow.player.PlayerBase -> get_field("_PlayerData") -> snow.player.PlayerData -> get_field("_Attack")
    -- defence = snow.player.PlayerBase -> get_field("_PlayerData") -> snow.player.PlayerData -> get_field("_Defence")
    -- ResistanceElement = snow.player.PlayerBase -> get_field("_PlayerData") -> snow.player.PlayerData -> get_field("_ResistanceElement") (1-5)
    -- CriticalRate = snow.player.PlayerBase -> get_field("_PlayerData") -> snow.player.PlayerData -> get_field("_CriticalRate")
    -- vitalMax = snow.player.PlayerBase -> get_field("_PlayerData") -> snow.player.PlayerData -> get_field("_vitalMax")
    -- vitalKeep = snow.player.PlayerBase -> get_field("_PlayerData") -> snow.player.PlayerData -> get_field("_vitalKeep")
    -- vital = snow.player.PlayerBase -> get_field("_PlayerData") -> snow.player.PlayerData -> get_field("_r_Vital")
    -- stamina = snow.player.PlayerBase -> get_field("_PlayerData") -> snow.player.PlayerData -> get_field("_stamina")
    -- staminaMax = snow.player.PlayerBase -> get_field("_PlayerData") -> snow.player.PlayerData -> get_field("_staminaMax")
    return nil
end

this.get_player_data = function(id)
    check_player_manager()
    local player = player_manager:call("getPlayer", id)

    if player == nil then
        player = player_manager:call("getPlayer", local_player_id)
    end

    if player then
        local data = player:call("get_PlayerData")
        if data then
            local attack = data:get_field("_Attack")
            local element_attack = data:get_field("_ElementAttack")
            local defence = data:get_field("_Defence")
            local resistance = data:get_field("_ResistanceElement")
            local critical = data:get_field("_CriticalRate")
            local vitalMax = data:get_field("_vitalMax")
            local vitalKeep = data:get_field("_vitalKeep")
            local vital = data:get_field("_r_Vital")
            local stamina = data:get_field("_stamina")
            local staminaMax = data:get_field("_staminaMax")
            return {
                attack = attack,
                element_attack = element_attack,
                defence = defence,
                resistance = resistance,
                critical = critical,
                vitalMax = vitalMax,
                vitalKeep = vitalKeep,
                vital = vital,
                stamina = stamina,
                staminaMax = staminaMax
            }
        end
        log.info("get_player_data: player:get_field('_PlayerData') is nil")
    end
    log.info("get_player_data: player is nil")
    return nil
end

this.get_hunters = function()
    check_lobby_manager()
    local hunters = {}
    local hunterInfo = lobby_manager:get_field("_questHunterInfo")
    
    if hunterInfo then
        local hunterCount = hunterInfo:call("get_Count")
        if hunterCount and hunterCount >= 1 then
            for i = 0, hunterCount-1 do
                local hunter = hunterInfo:call("get_Item", i)
                if hunter then
                    local playerId = hunter:get_field("_memberIndex")
                    local name = hunter:get_field("_name")
                    local rank = hunter:get_field("_hunterRank")
                    local rank2 = hunter:get_field("_masterRank")
                    table.insert(hunters, {
                        id = playerId,
                        name = name,
                        rank = rank,
                        rank2 = rank2
                    })
                end
            end
            if #hunters > 0 then
                return hunters
            end
        end        
    end

    local hunter = lobby_manager:get_field("_myHunterInfo")
    if hunter then
        local playerId = hunter:get_field("_memberIndex")
        local name = hunter:get_field("_name")
        local rank = hunter:get_field("_hunterRank")
        local rank2 = hunter:get_field("_masterRank")
        table.insert(hunters, {
            id = playerId,
            name = name,
            rank = rank,
            rank2 = rank2
        })
    end

    return hunters
end

return this