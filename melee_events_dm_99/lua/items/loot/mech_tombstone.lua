local item = require("lua/items/item.lua")

class 'mech_tombstone' ( item )

function mech_tombstone:__init()
	item.__init(self,self)
end

function mech_tombstone:OnInit()
end

function mech_tombstone:OnEquipped()
	
end

function mech_tombstone:OnActivate()
end

function mech_tombstone:OnPickUp( owner)


    EntityService:RemoveEntity( self.entity )
end

return mech_tombstone
