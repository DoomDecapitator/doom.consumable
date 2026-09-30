# doom.consumable:api/block_cd_place —— 在执行者【脚下的方块】上装一个冷却设备
#
# 用法：站在目标方块上，执行 doom.consumable:api/block_cd_place（as 玩家 / at 玩家）
# 秒数：默认 5；可用「/scoreboard players set #block_seconds dc.cfg <秒>」覆盖后再调用
# 设备 = marker 实体（tag dc.block_cd），配置与到期刻都存在它身上 ⇒ 跨 reload / 重启存活。
# 同一格重复调用会先清掉旧设备（避免叠罗汉）。
execute at @s align xyz run kill @e[type=minecraft:marker,tag=dc.block_cd,distance=..1]
execute at @s align xyz run summon minecraft:marker ~0.5 ~-0.5 ~0.5 {Tags:["dc.block_cd"],data:{dc:{cd_seconds:5,cd_ready:0,cd_key:"device",cd_count:0}}}
scoreboard players set #blk_def dc.temp 5
execute if score #block_seconds dc.cfg matches 1.. store result score #blk_def dc.temp run scoreboard players get #block_seconds dc.cfg
execute at @s align xyz store result entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1.5,limit=1,sort=nearest] data.dc.cd_seconds int 1 run scoreboard players get #blk_def dc.temp
tellraw @s {"text":"[dc] 已在脚下方块装了冷却设备（默认 5 秒；可改 cd_seconds 或 #block_seconds）","color":"green"}
