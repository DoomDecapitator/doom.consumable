# doom.consumable:throw/diff_xp_bottle —— 经验瓶（minecraft:experience_bottle）的统计差分（stat 上涨 = 本刻扔出一次）
# 与 shot/diff_* 同构。
execute store result score #throw_now dc.temp run scoreboard players get @s dc.throw_use_xp_bottle
execute store result score #throw_prev dc.temp run scoreboard players get @s dc.throw_prev_xp_bottle
scoreboard players operation @s dc.throw_prev_xp_bottle = @s dc.throw_use_xp_bottle
execute if score #throw_now dc.temp > #throw_prev dc.temp run function doom.consumable:throw/process_one
