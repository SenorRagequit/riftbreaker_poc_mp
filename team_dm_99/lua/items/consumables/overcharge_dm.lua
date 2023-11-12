local item = require("lua/items/item.lua")

class 'overcharge_dm' ( item )

function overcharge_dm:__init()
	item.__init(self,self)
end

function overcharge_dm:OnInit()
end

function overcharge_dm:OnEquipped()
	
end

function overcharge_dm:OnActivate()
end

function overcharge_dm:OnPickUp( owner)
    local health = EntityService:GetComponent( owner, "HealthComponent" )
	if (health == nil ) then
		local player =  PlayerService:GetPlayerForEntity( owner )
		owner = PlayerService:GetPlayerControlledEnt( player )
	end
    
    local healthInPercent = self.data:GetFloatOrDefault( "heal_amount", 100 )
    
    local healthLink = EntityService:GetComponent( owner, "HealthLinkComponent" )
    if ( healthLink ) then
        local helper = reflection_helper( healthLink) 
        local container = rawget(helper.links, "__ptr");
        local count = container:GetItemCount()
        for i=0,count - 1,1 do
            local item = reflection_helper( container:GetItem( i ) )
            HealthService:AddHealthInPercentage( item.second.id, healthInPercent )
        end
    end
    EntityService:RemoveEntity( self.entity )
end

return overcharge_dm
