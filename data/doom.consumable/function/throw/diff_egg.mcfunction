# doom.consumable:throw/diff_egg —— 鸡蛋（minecraft:egg）的统计差分（stat 上涨 = 本刻扔出一次）
# 与 shot/diff_* 同构。
execute store result score #throw_now dc.temp run scoreboard players get @s dc.throw_use_egg
execute store result score #throw_prev dc.temp run scoreboard players get @s dc.throw_prev_egg
scoreboard players operation @s dc.throw_prev_egg = @s dc.throw_use_egg
execute if score #throw_now dc.temp > #throw_prev dc.temp run function doom.consumable:throw/process_one
