# doom.consumable:block/allow —— 放行：刷新到期刻（now + cd_seconds*20）+ 计数 + 外部回调
#
# 到期刻写在设备实体上 ⇒ 跨 reload、跨重启存活（不需要额外 storage 账本）。
scoreboard players set #blk_sec dc.temp 5
execute store result score #blk_sec dc.temp run data get entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] data.dc.cd_seconds
scoreboard players set #blk_20 dc.temp 20
scoreboard players operation #blk_sec dc.temp *= #blk_20 dc.temp
scoreboard players operation #blk_sec dc.temp += #blk_now dc.temp
execute store result entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] data.dc.cd_ready int 1 run scoreboard players get #blk_sec dc.temp

scoreboard players set #blk_cnt dc.temp 0
execute store result score #blk_cnt dc.temp run data get entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] data.dc.cd_count
scoreboard players add #blk_cnt dc.temp 1
execute store result entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] data.dc.cd_count int 1 run scoreboard players get #blk_cnt dc.temp
scoreboard players add @s dc.block_use 1

data remove storage doom.consumable:ctx block

# 冷却态外观（可选）：设备声明了 cd_block_cooling ⇒ 当场把方块换成「冷却中」形态
#   （到期自动换回由 block/tick_restore 每 5 tick 轮询完成）
execute if data entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] data.dc.cd_block_cooling run data modify storage doom.consumable:ctx blk.state set from entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] data.dc.cd_block_cooling
execute if data storage doom.consumable:ctx blk.state run function doom.consumable:block/set_device_state with storage doom.consumable:ctx blk
data remove storage doom.consumable:ctx blk.state
data modify storage doom.consumable:ctx block.key set from entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] data.dc.cd_key
function #doom.consumable:on_block_use
data remove storage doom.consumable:ctx block
