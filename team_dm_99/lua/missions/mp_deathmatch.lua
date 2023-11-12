require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/enumerables.lua")
local uTeam = require("lua/utils/team_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mp_deathmatch' ( mission_base )

G_MP_MISSION_STATE_WARMUP = 0
G_MP_MISSION_STATE_GAME   = 1
G_MP_MISSION_STATE_FINISH   = 2
G_MP_MISSION_STATE_PREPARATION = 3

G_MP_MISSION_STATE = "mission_state"

function mp_deathmatch:__init()
    mission_base.__init(self,self)
end

function ResetMultiplayerRound()
    PlayerService:ResetDeathStats()
end

function mp_deathmatch:init()
    mission_base.init( self );

    QueueEvent("DisableBuildModeRequest", INVALID_ID )

    -- SRQ: Create 2 teams, TeamA + TeamB
    local l_teamA = PlayerService:CreatePlayerTeam("TeamA", true)
    local l_teamB = PlayerService:CreatePlayerTeam("TeamB", true)

    -- SRQ: Make the teams hate each other
    EntityService:SetTeamRelation( l_teamA, l_teamB, "hostility" )
    EntityService:SetTeamRelation( l_teamB, l_teamA, "hostility" )


    local team = EntityService:GetTeam( "player" )
    EntityService:SetTeamRelation( team, team, "hostility" )

	MissionService:SetSkipSpawnPortalSequence(true)

    ConsoleService:ExecuteCommand("debug_server_randomize_player_id 1")
    ConsoleService:ExecuteCommand("camera_distance 50")
	ConsoleService:ExecuteCommand("camera_pitch -55")
	ConsoleService:ExecuteCommand("camera_dynamic_radius_factor 12")
	ConsoleService:ExecuteCommand("camera_dynamic_speed_factor 1.0")
    ConsoleService:ExecuteCommand("mech_near_death_immortal_time 0")
    ConsoleService:ExecuteCommand("change_slot_on_empty_ammo 1")
    ConsoleService:ExecuteCommand("map_no_resources_margin 0")
    
	self:RegisterHandler( event_sink, "PlayerControlledEntityChangeEvent",  "OnPlayerControlledEntityChangeEvent" )
	self:RegisterHandler( event_sink, "RespawnFailedEvent",			        "OnRespawnFailedEvent" )
	self:RegisterHandler( event_sink, "PlayerCreatedEvent",                 "OnPlayerCreatedEvent" )
	self:RegisterHandler( event_sink, "PlayerInitializedEvent",             "OnPlayerInitializedEvent" )
	self:RegisterHandler( event_sink, "PlayerDiedEvent",                    "OnPlayerDiedEvent" )

    local campaignData = CampaignService:GetCampaignData()
    self.campaignState = campaignData:GetIntOrDefault(G_MP_MISSION_STATE, G_MP_MISSION_STATE_WARMUP)

    campaignData:SetInt( G_MP_MISSION_STATE, self.campaignState )
    self.fsm = self:CreateStateMachine()
    self.timer = 0;
	self.fsm:AddState( "idle", {  enter="OnIdleStart", execute="OnIdleExecute", exit="OnIdleExit" } )
	self.fsm:AddState( "win", { enter="OnWinStart",  execute="OnWinExecute", exit="OnWinExit" } )
	self.fsm:AddState( "preparation", { enter="OnPreparationStart", exit="OnPreparationExit" } )
    self.fragLimit = campaignData:GetFloatOrDefault( "frag_limit", 0 )
    
    self.fsm:ChangeState("idle")

    self.player_bots = {}
    local player_bot_ids = Split( campaignData:GetStringOrDefault("player_bots", ""), "," )
    for player_bot_id in Iter( player_bot_ids ) do
        self.player_bots[tonumber(player_bot_id)] = false
    end

    self.botFSM = self:CreateStateMachine()
	self.botFSM:AddState( "check_bots", { execute="OnCheckBotsExecute", interval=1.0 } )
    self.botFSM:ChangeState("check_bots")
end

function mp_deathmatch:OnWinStart( state)
    self.timer = 30.0
    state:SetDurationLimit( self.timer )
    self:ShowTimer()
    GuiService:OperateHudByMask( "HT_HUD_SCOREBOARD", true )
end

function mp_deathmatch:OnPreparationStart( state)
    state:SetDurationLimit( 5 )
end

function mp_deathmatch:OnPreparationExit( state)
    local campaignData = CampaignService:GetCampaignData()
    self.campaignState = G_MP_MISSION_STATE_GAME
    campaignData:SetInt(G_MP_MISSION_STATE, G_MP_MISSION_STATE_GAME )
    self.fsm:ChangeState("idle" )
end

function mp_deathmatch:GetBotCount()
    local bots_count = 0
    for _,spawned in pairs(self.player_bots) do
        if spawned then
            bots_count = bots_count + 1
        end
    end

    return bots_count
end

function mp_deathmatch:GetPlayerCount()
    local players_count = 0
    for entity in Iter(PlayerService:GetPlayersMechs()) do
        if EntityService:GetBlueprintName(entity) == "player/character" then
            players_count = players_count + 1
        end
    end

    return players_count
end

function mp_deathmatch:OnCheckBotsExecute()
    local campaignData = CampaignService:GetCampaignData()

    local max_bot_count = campaignData:GetIntOrDefault("max_bot_count", 0)
    local max_player_count = tonumber( ConsoleService:GetConfig("server_max_players_count") )

    local players_count = self:GetPlayerCount()
    max_bot_count = math.min(max_bot_count, max_player_count)

    local allowed_bot_count = math.min( math.max(0, max_player_count - players_count), max_bot_count )

    local bots_count = self:GetBotCount()
    while bots_count > allowed_bot_count do
        self:KickPlayerBot()
        bots_count = bots_count - 1
    end

    if bots_count < allowed_bot_count then
        self:SpawnPlayerBot()
    end
end

function mp_deathmatch:KickPlayerBot()
    for player_id, spawned in pairs(self.player_bots) do
        if spawned then
            PlayerService:RemovePlayerBot(player_id)
            self.player_bots[player_id] = false
            return
        end
    end
end

function mp_deathmatch:SpawnPlayerBot()
    for player_id, spawned in pairs(self.player_bots) do
        if (not spawned) then
            local player_team = PlayerService:GetPlayerTeam(player_id)
            PlayerService:CreatePlayerBot("player/character_bot", player_id, player_team )
            self.player_bots[player_id] = true
            return
        end
    end

    player_team = uTeam:GetTeamWithFewerPlayersAB("TeamA", "TeamB")
    l_teamANum = EntityService:GetTeam( "TeamA" )

    if (player_team == l_teamANum) then
        player_id = PlayerService:CreateFakePlayer("Bot - Team A")
    else
        player_id = PlayerService:CreateFakePlayer("Bot - Team B")
    end


    PlayerService:CreatePlayerBot("player/character_bot", player_id, player_team )
    PlayerService:SetPlayerTeam(player_id, player_team)

    self.player_bots[player_id] = true

    local player_bot_ids = ""
    for player_id, _ in pairs(self.player_bots) do
        if player_bot_ids == "" then
            player_bot_ids = tostring(player_id)
        else
            player_bot_ids = player_bot_ids .. "," .. tostring(player_id)
        end
    end

    local campaignData = CampaignService:GetCampaignData()
    campaignData:SetString("player_bots", player_bot_ids)
end

function mp_deathmatch:OnWinExecute( state, tick )
    self.timer = self.timer - tick
end

function mp_deathmatch:OnWinExit(state)
    local newMissionName = G_MP_MISSION_STATE_WARMUP .. tostring(self)
    local campaignData = CampaignService:GetCampaignData()
    campaignData:SetInt(G_MP_MISSION_STATE, G_MP_MISSION_STATE_WARMUP  )
    CampaignService:UnlockMission(newMissionName , self.nextMissionName )
    CampaignService:ChangeCurrentMission( newMissionName )
end

function mp_deathmatch:ShowTimer()
    self.timerSet = true
    local currentStateName = self.fsm:GetCurrentState()
    local currentState = self.fsm:GetState( currentStateName )
    if (currentState == nil ) then
        return
    end
    local time = currentState:GetDurationLimit() - currentState:GetDuration()

    if ( self.campaignState == G_MP_MISSION_STATE_WARMUP )  then
        QueueEvent("HudTimerResetRequest", event_sink, GetLogicTime(), time, "gui/menu/multiplayer/warmup" )
    elseif ( self.campaignState == G_MP_MISSION_STATE_GAME ) then
        QueueEvent("HudTimerResetRequest", event_sink, GetLogicTime(),  time, "gui/menu/multiplayer/game" )
    else
        QueueEvent("HudTimerResetRequest", event_sink, GetLogicTime(),  time, "gui/menu/multiplayer/next_map" )
    end
end

function mp_deathmatch:OnIdleStart( state)
    local campaignData = CampaignService:GetCampaignData()
    ResetMultiplayerRound()
    if ( self.campaignState == G_MP_MISSION_STATE_WARMUP )  then
        self.timer = campaignData:GetFloatOrDefault("warmup_duration", 30.0)
        ConsoleService:ExecuteCommand("set cheat_unlimited_ammo 1")
    else
        if ( self.fragLimit > 0 ) then
            self:RegisterHandler( event_sink, "PlayerDeathStatsRefreshEvent",      "OnPlayerDeathStatsRefreshEvent" )
        end
        ConsoleService:ExecuteCommand("set cheat_unlimited_ammo 0")
        self.timer = campaignData:GetFloatOrDefault("game_duration", 1200.0)
    end

    if ( self.timer == 0 and self.campaignState == G_MP_MISSION_STATE_WARMUP ) then
        ConsoleService:ExecuteCommand("set cheat_unlimited_ammo 0")
        self.timer = campaignData:GetFloatOrDefault("game_duration", 1200.0)
        self.campaignState = G_MP_MISSION_STATE_GAME
        campaignData:SetInt( G_MP_MISSION_STATE, self.campaignState )
    end
    
    local players = PlayerService:GetAllPlayers()
    local playersCount = #players

    if ( self.campaignState == G_MP_MISSION_STATE_WARMUP and playersCount < 2  )  then
        return
    end
    
    if ( self.timer > 0 ) then
        state:SetDurationLimit( self.timer )
        self:ShowTimer()
    end
end

function mp_deathmatch:OnIdleExecute( state, tick )
    if ( self.campaignState == G_MP_MISSION_STATE_WARMUP and self.timerSet == nil ) then
        local players = PlayerService:GetAllPlayers()
        local playersCount = #players
    
        if ( playersCount < 2  )  then
            return
        end
        
        if ( self.timer > 0 ) then
            state:SetDurationLimit( self.timer )
            self:ShowTimer()
        end
    end
end
function mp_deathmatch:CleanPlayerEnts()
    local predicate = {
        signature="PlayerReferenceComponent",
        filter = function(entity)
            local playerReference =reflection_helper(EntityService:GetComponent( entity, "PlayerReferenceComponent" ))            
            local internalEnum = playerReference.reference_type.internal_enum 
            if ( internalEnum == 3 ) then -- Remove only other
                return true
            elseif ( internalEnum == 0) then
                HealthService:SetImmortality( entity, false )
                QueueEvent("DamageRequest",entity, 999999.0, "", 0, 0)
                return false
            else
                return false
            end
        end
    };

    local playable_min = MissionService:GetPlayableRegionMin();
    local playable_max = MissionService:GetPlayableRegionMax();
	local entities = FindService:FindEntitiesByPredicateInBox( playable_min, playable_max, predicate );
    for entity in Iter(entities) do
        EntityService:RemoveEntity( entity )
    end
end

function mp_deathmatch:OnIdleExit(state)
    local campaignData = CampaignService:GetCampaignData()
    local missionName = CampaignService:GetCurrentMissionId()
    if ( self.campaignState == G_MP_MISSION_STATE_WARMUP )  then
        self:CleanPlayerEnts( true )
        self.campaignState = G_MP_MISSION_STATE_PREPARATION
        campaignData:SetInt(G_MP_MISSION_STATE, G_MP_MISSION_STATE_PREPARATION )
        self.fsm:ChangeState("preparation")
    else
        self.campaignState = G_MP_MISSION_STATE_FINISH
        campaignData:SetInt(G_MP_MISSION_STATE, self.campaignState  )
        
        local currentCampaignDefName = CampaignService:GetCurrentCampaignDefName()
        local campaignDef = ResourceManager:GetResource("CampaignDef", currentCampaignDefName )
        Assert(campaignDef ~= nil, "ERROR: No campaign def with name '" .. currentCampaignDefName .. "'")
        local helperCampaignDef = reflection_helper(campaignDef)
        local missionDef = CampaignService:GetCurrentMissionDefName()

        local index = nil
        local missionCount = helperCampaignDef.mission_list.count
        for i=1,missionCount  do
            local mission = "missions/" .. helperCampaignDef.mission_list[i] .. ".mission"
            if ( mission == missionDef ) then
                index = i 
            end
        end
        
        Assert( index ~= nil, "Error: Missing mission def in mission list: '" .. missionDef .. "'")
        self.nextMissionName =  helperCampaignDef.mission_list[1]
        if ( index ~= nil ) then
            index = index + 1
            if ( index <= helperCampaignDef.mission_list.count ) then
                self.nextMissionName =  helperCampaignDef.mission_list[index]
            end
        end

        self.fsm:ChangeState("win")
    end
end

function mp_deathmatch:OnPlayerDeathStatsRefreshEvent( event )
    local playerKills = event:GetPlayerKills()

    for playerId, kills in pairs(playerKills) do
        local allCount = 0
        for  killed, count in pairs(kills) do
            allCount = allCount + count
        end
        if ( allCount >= self.fragLimit ) then
            self.fsm.Deactivate()
        end
    end
end

function mp_deathmatch:PrepareSpawnPoints(safeRadius)
    self.spawn_points = {};

    local entities = FindService:FindEntitiesByBlueprint("logic/spawn_player")
    for entity in Iter( entities ) do 
        self.spawn_points[ entity ] = INVALID_ID
    end
end

function mp_deathmatch:UpdatePickupSpawnTimes()
    local playersCount = self:GetPlayerCount()

    local predicate = {
        signature="DatabaseComponent",
    };

    local playable_min = MissionService:GetPlayableRegionMin();
    local playable_max = MissionService:GetPlayableRegionMax();
	local entities = FindService:FindEntitiesByPredicateInBox( playable_min, playable_max, predicate );
    for entity in Iter(entities) do
        local entityDatabase = EntityService:GetDatabase( entity ) 
        for key in Iter( entityDatabase:GetStringKeys() ) do
            if ( string.match(key, ".players_steps")) then
                local field = string.gsub(key, ".players_steps", "")
                local stringValues = entityDatabase:GetString( key )
                local values = Split( stringValues, "," )
                for index, value in ipairs(values ) do
                    local playerCountToValue = Split(value, ":")
                        if ( playersCount < tonumber(playerCountToValue[1]) or index == #values ) then
                        entityDatabase:SetFloat( field, tonumber(playerCountToValue[2])) 
                        goto continue
                    end
                end
            end
            ::continue::
        end
    end

end

function mp_deathmatch:OnPlayerCreatedEvent( event )
    local player_id = event:GetPlayerId()
    local player_team = PlayerService:GetPlayerTeam(player_id)
    if player_team == EntityService:GetTeam("player") or player_team == INVALID_TEAM then
        player_team = uTeam:GetTeamWithFewerPlayersAB("TeamA", "TeamB")
        PlayerService:SetPlayerTeam(player_id, player_team)
    end

    self:UpdatePickupSpawnTimes()
    self:RandomizePlayerSpawnPoint(event:GetPlayerId())
end

function mp_deathmatch:OnPlayerInitializedEvent( event )
    GuiService:OperateHudByMask( "HT_HUD_RESOURCE", false )
    GuiService:OperateHudByMask( "HT_HUD_DEATHS", true )

    if ( self.timerSet ) then
        self:ShowTimer()
    end
end

function mp_deathmatch:RefilConsumables( player )
    local slots = 
    {
        "USABLE_1",
        "USABLE_2",
        "USABLE_3",
        "USABLE_4",
        "USABLE_5",
        "USABLE_6",
        "USABLE_7",
        "USABLE_8",
    }

    for slotName in Iter(slots) do
        local items = PlayerService:GetAllEquippedItemsInSlot(slotName, player )
        if ( #items > 0 ) then
            for item in Iter(items) do
                local item = EntityService:GetConstComponent( item, "InventoryItemComponent" )
                if ( item ~= nil ) then
                    local helper = reflection_helper( item )
                    if( helper.storage_limit > 0 ) then
                        local itemRuntime = EntityService:GetComponent( item, "InventoryItemRuntimeDataComponent" )
                        reflection_helper(itemRuntime).use_count = helper.storage_limit
                    end
                end
            end
        end
    end
end

function mp_deathmatch:OnTimerElapsedEvent(evt)
    if (evt:GetName() ~= "EndOfImmortality") then
        return
    end
    local mechEntity = evt:GetEntity()
    HealthService:SetImmortality( mechEntity, false )

end

function mp_deathmatch:CheckFragLimit()
    if (self.campaignState == G_MP_MISSION_STATE_GAME) then
        local campaignData = CampaignService:GetCampaignData()
        local fragLimit = campaignData:GetIntOrDefault("frag_limit", 0 )
        if ( fragLimit > 0 ) then
            local currentMaxFrag = 0
            local singleton = EntityService:GetSingletonComponent( "PlayerStatsComponent" )
            if ( singleton ) then
                local  playersStatsComponent = reflection_helper(singleton)
                for i=1,playersStatsComponent.player_kills.count do
                    local playerStats = playersStatsComponent.player_kills[i]
                    local currentPlayerKills = 0
                    for j=1,playerStats.value.count do
                        currentPlayerKills = currentPlayerKills + playerStats.value[j].value 
                    end
                    if ( currentMaxFrag < currentPlayerKills ) then
                        currentMaxFrag = currentPlayerKills
                    end
                end
            end
            if ( currentMaxFrag >= fragLimit ) then
                self.fsm:Deactivate()
            end
        end
    end
end

function mp_deathmatch:RandomizePlayerSpawnPoint( player_id )
    local player_spawn_point = PlayerService:GetPlayerSpawnPoint( player_id )
    local player_positions = {}

    local players = PlayerService:GetPlayersMechs()
    for entity in Iter(players) do
        local position = EntityService:GetPosition(entity)
        table.insert( player_positions, position )
    end

    local DistanceSort = function( a, b )
        return a < b
    end 

    local spawn_point = { entity = INVALID_ID, distance = nil }
    for entity, assigned_player in pairs(self.spawn_points) do
        if entity ~= player_spawn_point and assigned_player == INVALID_ID then
            local spawn_position = EntityService:GetPosition(entity)

            local player_distances = {}
            for position in Iter(player_positions) do
                table.insert( player_distances, Distance( position, spawn_position ) );
            end

            table.sort( player_distances, DistanceSort )

            if not spawn_point.distance or spawn_point.distance < player_distances[1] then
                spawn_point.entity = entity
                spawn_point.distance = player_distances[1]
            end
        end
    end

    if spawn_point.entity ~= INVALID_ID then
        self.spawn_points[ spawn_point.entity ] = player_id
        PlayerService:SetPlayerSpawnPoint( player_id, spawn_point.entity )
    end
end

function mp_deathmatch:OnPlayerDiedEvent(evt)
    local entity = evt:GetEntity()

    local resources = {
        "ammo_dm_bouncing_blades",
        "ammo_dm_minigun",
        "ammo_dm_grenade_launcher",
        "ammo_dm_railgun",
        "ammo_dm_acid_spitter",
    }

    local rotation = RandFloat( 0.0, 180.0 )
    Assert( EntityService:IsAlive( entity ), "Error: mech entity is not alive!")

    local first = true
    if ( self.campaignState == G_MP_MISSION_STATE_GAME) then
        for resource in Iter(resources) do
            local amount  = PlayerService:GetResourceAmount(evt:GetPlayerId(), resource  )
            local blueprint = "items/loot/mech_tombstone_empty_item"
            if ( first ) then
               blueprint =  "items/loot/mech_tombstone_item"
               first = false
            end
            if ( amount > 0 ) then
                local tombstone = EntityService:SpawnEntity( blueprint, entity, "neutral" )
                EntityService:Rotate( tombstone, 0.0, 1.0, 0.0, rotation  )
                EntityService:CreateResourceComponent( tombstone,resource , amount  )

                local playerReference = EntityService:CreateComponent( tombstone, "PlayerReferenceComponent" )
                if ( playerReference ) then
                    local helper = reflection_helper( playerReference )
                    helper.reference_type.internal_enum = 3
                    helper.player_id = evt:GetPlayerId()
                end
            end
        end

        self:CheckFragLimit()
    end

    self:RandomizePlayerSpawnPoint(PlayerService:GetPlayerByMech( entity ))
end

function mp_deathmatch:OnPlayerControlledEntityChangeEvent( event )
    local mechEntity = event:GetControlledEntity()
    if ( mechEntity == INVALID_ID) then
        return
    end

    -- Refill consumables
    self:RefilConsumables( event:GetPlayerId() )

    HealthService:SetImmortality( mechEntity, true )
    EntityService:CreateComponent( mechEntity, "TimerComponent")
    QueueEvent( "SetTimerRequest", mechEntity, "EndOfImmortality", 3 )
    self:RegisterHandler( mechEntity, "TimerElapsedEvent", "OnTimerElapsedEvent")

    --PlayerService:SetResourceAmount("ammo_mech_low_caliber", 0, event:GetPlayerId() )
    --PlayerService:SetResourceAmount("ammo_mech_high_caliber", 0, event:GetPlayerId() )
    --PlayerService:SetResourceAmount("ammo_mech_liquid", 0, event:GetPlayerId() )
    --PlayerService:SetResourceAmount("ammo_mech_explosive", 0, event:GetPlayerId() )
    --PlayerService:SetResourceAmount("ammo_mech_energy_cell", 0, event:GetPlayerId() )
	
    PlayerService:SetResourceAmount("ammo_dm_bouncing_blades", 10, event:GetPlayerId() )
    PlayerService:SetResourceAmount("ammo_dm_minigun", 75, event:GetPlayerId() )
    PlayerService:SetResourceAmount("ammo_dm_grenade_launcher", 5, event:GetPlayerId() )
    PlayerService:SetResourceAmount("ammo_dm_railgun", 3, event:GetPlayerId() )
    PlayerService:SetResourceAmount("ammo_dm_acid_spitter", 25, event:GetPlayerId() )

    MissionService:EnableAllSpawnpoints()

    local mechDatabase = EntityService:GetDatabase( mechEntity)
    if ( mechDatabase ~= nil ) then
        mechDatabase:SetInt( "leave_portal", 0)
    end

    local player_id = PlayerService:GetPlayerByMech( mechEntity )
    for entity, assigned_player in pairs(self.spawn_points) do
        if assigned_player == player_id then
            self.spawn_points[ entity ] = INVALID_ID
        end
    end
end

function mp_deathmatch:OnRespawnFailedEvent()
end

function mp_deathmatch:OnMissionFinish( evt)
    self.fsm:Deactivate()
end

ConsoleService:RegisterCommand( "debug_reset_round", function( args )
    ResetMultiplayerRound()
end)

return mp_deathmatch
