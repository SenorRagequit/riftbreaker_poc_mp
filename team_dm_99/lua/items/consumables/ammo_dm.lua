local item = require("lua/items/item.lua")

class 'ammo_dm' ( item )

function ammo_dm:__init()
	item.__init(self,self)
end

function ammo_dm:OnInit()
    self.ammoCount   = self.data:GetFloat( "amount" )
    self.resource   = self.data:GetString( "resource" )
end

function ammo_dm:OnEquipped()
	
end

function ammo_dm:OnActivate()
end

function ammo_dm:OnPickUp( owner )
    local player = PlayerService:GetPlayerForEntity( owner )

    local ammoResource = ResourceManager:GetResource("GameplayResourceDef", self.resource)
    if ( ammoResource ~= nil ) then
        local ammoResourceHelper = reflection_helper( ammoResource )
        PlayerService:AddResourceAmount(player, self.resource , self.ammoCount * ammoResourceHelper.production, false )
    end	

    local slots = {
        "LEFT_HAND",
        "RIGHT_HAND",
    }
    
    for slot in Iter(slots ) do
        local equippedItem = ItemService:GetEquippedItem( owner, slot )
        if ( equippedItem == INVALID_ID) then
            goto continue 
        end
        
        if ( ItemService:HasAmmoToShoot( equippedItem ) ) then
            goto continue 
        end

        local owner = ItemService:GetOwner( equippedItem )
        QueueEvent("NextSubSlotRequest", owner, slot )
        ::continue::
    end

    EntityService:RemoveEntity( self.entity )
end

return ammo_dm
