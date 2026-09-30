# doom.consumable:core/refresh_hand_cache — sync mainhand/offhand to library cache
function doom.library:api/open
data modify storage doom.library:ctx _.cache_key set value "inventory"
data modify storage doom.library:ctx _.cache_data set value {}
data modify storage doom.library:ctx _.cache_data.Inventory set from entity @s Inventory
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc" run data modify storage doom.library:ctx _.cache_data.mainhand set from entity @s SelectedItem
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc" run data modify storage doom.library:ctx _.cache_data.offhand set from entity @s equipment.offhand
function doom.library:api/cache with storage doom.library:ctx _
data remove storage doom.library:ctx _.cache_key
data remove storage doom.library:ctx _.cache_data