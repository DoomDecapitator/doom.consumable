# doom.consumable:core/snapshot_hand —— 每 tick 记一份"手部快照"（专供放置链的入口用）
#
# 为什么不能用现成的 CACHE.inventory：
#   save_inv 由 inventory_changed 驱动，而**放置本身就会改库存** ⇒ 它会在放置的那一 tick
#   跑起来，开头 `cache_data set value {}` 把上一份主手快照抹掉、再写入"放置之后"的状态
#   （count=1 时手已经空了）⇒ 奖励函数读到的永远是放置后的样子。
#   （2026-09-26 真机实测：兜底读 CACHE.inventory.mainhand 拿到的是空。）
#
# 本快照在 tick 函数的**最前面**写下（早于本 tick 的任何手持改动），因此它就是"放置之前"那份；
# 同时记下当时的游戏刻 time —— mark_placed 只认"时刻戳等于当前刻"的快照，
# 避免用到上一 tick 的陈旧物品（否则吃掉最后一件后随手放个方块，会把陈旧物品复活 = 凭空造物）。
function doom.library:api/open
data modify storage doom.library:ctx _.cache_key set value "hand"
data modify storage doom.library:ctx _.cache_data set value {}
execute store result storage doom.library:ctx _.cache_data.time int 1 run time query gametime
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc" run data modify storage doom.library:ctx _.cache_data.mainhand set from entity @s SelectedItem
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc" run data modify storage doom.library:ctx _.cache_data.offhand set from entity @s equipment.offhand
# 2026-09-27：记下这一 tick 选中的热键槽（放置链的恢复落点靠它精确回原槽）
execute if data entity @s SelectedItemSlot store result storage doom.library:ctx _.cache_data.sel int 1 run data get entity @s SelectedItemSlot
function doom.library:api/cache with storage doom.library:ctx _
data remove storage doom.library:ctx _.cache_key
data remove storage doom.library:ctx _.cache_data
