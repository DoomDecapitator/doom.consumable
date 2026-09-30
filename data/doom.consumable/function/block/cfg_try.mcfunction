# doom.consumable:block/cfg_try [MACRO] —— 单条配置的匹配尝试（命中即把结果写进 storage doom.consumable:ctx dev）
#
# 参数（来自 entries[i]）：tag=方块标签 · seconds=秒数 · key=设备名 · ready/cooling=可选外观（"-" 表示不改方块）
# 命中判据：执行位置所在方块属于 #$(tag)；且本次还没命中过（#cfg_hit）⇒ 第一条命中的配置生效。
$execute unless score #cfg_hit dc.temp matches 1 if block ~ ~ ~ #$(tag) run scoreboard players set #cfg_hit dc.temp 1
$execute unless score #cfg_hit dc.temp matches 1 if block ~ ~ ~ #$(tag) run data modify storage doom.consumable:ctx dev.seconds set value $(seconds)
$execute unless score #cfg_hit dc.temp matches 1 if block ~ ~ ~ #$(tag) run data modify storage doom.consumable:ctx dev.key set value "$(key)"
$execute unless score #cfg_hit dc.temp matches 1 if block ~ ~ ~ #$(tag) run data modify storage doom.consumable:ctx dev.ready set value "$(ready)"
$execute unless score #cfg_hit dc.temp matches 1 if block ~ ~ ~ #$(tag) run data modify storage doom.consumable:ctx dev.cooling set value "$(cooling)"
$execute unless score #cfg_hit dc.temp matches 1 if block ~ ~ ~ #$(tag) run data modify storage doom.consumable:ctx dev.tag set value "$(tag)"
