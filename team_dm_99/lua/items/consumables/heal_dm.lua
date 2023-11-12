local item = require("lua/items/item.lua")

class 'heal_dm' ( item )

function heal_dm:__init()
	item.__init(self,self)
end

function heal_dm:OnInit()
    self.amount   = self.data:GetFloat( "amount" )
end

function heal_dm:OnEquipped()
	
end

function heal_dm:OnActivate()
end

function heal_dm:OnPickUp( owner )

	local health = EntityService:GetComponent( owner, "HealthComponent" )
	if (health == nil ) then
		local player =  PlayerService:GetPlayerForEntity( owner )
		owner = PlayerService:GetPlayerControlledEnt( player )
	end
	HealthService:AddHealthInPercentage( owner, self.amount )
    EntityService:RemoveEntity( self.entity )
end

return heal_dm
