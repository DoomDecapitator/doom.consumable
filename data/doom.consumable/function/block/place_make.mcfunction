# doom.consumable:block/place_make [MACRO] —— 在该格建设备，并把到期刻直接写成「现在 + 秒数*20」⇒ 出生即冷却
#
# 参数：plc.seconds（来自物品 dc.place_cd）
# 设备带 dc.block_cd_auto ⇒ 冷却结束后 600 tick 由 block/prune 自动清掉（不会堆实体）。
execute store result score #pl_now dc.temp run time query gametime
$scoreboard players set #pl_sec dc.temp $(seconds)
scoreboard players set #pl_20 dc.temp 20
scoreboard players operation #pl_sec dc.temp *= #pl_20 dc.temp
scoreboard players operation #pl_sec dc.temp += #pl_now dc.temp
data modify storage doom.consumable:ctx plc.ready set value 0
execute store result storage doom.consumable:ctx plc.ready int 1 run scoreboard players get #pl_sec dc.temp
function doom.consumable:block/place_spawn with storage doom.consumable:ctx plc
data remove storage doom.consumable:ctx plc.ready
