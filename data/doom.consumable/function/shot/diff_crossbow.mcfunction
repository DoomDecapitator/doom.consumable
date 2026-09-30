# doom.consumable:shot/diff_crossbow —— crossbow 的统计差分（stat 上涨 = 本刻射出一次）
execute store result score #shot_now dc.temp run scoreboard players get @s dc.shot_use_crossbow
execute store result score #shot_prev dc.temp run scoreboard players get @s dc.shot_prev_crossbow
scoreboard players operation @s dc.shot_prev_crossbow = @s dc.shot_use_crossbow
execute if score #shot_now dc.temp > #shot_prev dc.temp run function doom.consumable:shot/process_one
