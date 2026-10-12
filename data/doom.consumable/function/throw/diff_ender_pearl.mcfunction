# doom.consumable:throw/diff_ender_pearl —— 末影珍珠（minecraft:ender_pearl）的统计差分（stat 上涨 = 本刻扔出一次）
# 与 shot/diff_* 同构。
execute store result score #throw_now dc.temp run scoreboard players get @s dc.throw_use_ender_pearl
execute store result score #throw_prev dc.temp run scoreboard players get @s dc.throw_prev_ender_pearl
scoreboard players operation @s dc.throw_prev_ender_pearl = @s dc.throw_use_ender_pearl
execute if score #throw_now dc.temp > #throw_prev dc.temp run function doom.consumable:throw/process_one
