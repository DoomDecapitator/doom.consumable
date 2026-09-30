# doom.consumable:block/dev_create [MACRO] —— 在「被交互的方块」上现场建一台自动设备
#
# 参数（来自 storage doom.consumable:ctx dev）：seconds / key / ready / cooling / tag
#   ready / cooling 为 "-" ⇒ 不声明外观（这台设备只做逻辑冷却，不动方块）
# 标签 dc.block_cd_auto 用于「闲置清理」（见 block/prune）；显式设备（api/block_cd_place）不带这个标签，不会被清。
# 执行位置：已 align 到目标方块（found_block 保证）⇒ 方块中心 = ~0.5 ~0.5 ~0.5。
$summon minecraft:marker ~0.5 ~0.5 ~0.5 {Tags:["dc.block_cd","dc.block_cd_auto"],data:{dc:{cd_seconds:$(seconds),cd_ready:0,cd_key:"$(key)",cd_count:0}}}
$execute unless data storage doom.consumable:ctx dev{ready:"-"} run data modify entity @e[type=minecraft:marker,tag=dc.block_cd_auto,distance=..1,limit=1] data.dc.cd_block_ready set value "$(ready)"
$execute unless data storage doom.consumable:ctx dev{cooling:"-"} run data modify entity @e[type=minecraft:marker,tag=dc.block_cd_auto,distance=..1,limit=1] data.dc.cd_block_cooling set value "$(cooling)"
data remove storage doom.consumable:ctx dev
