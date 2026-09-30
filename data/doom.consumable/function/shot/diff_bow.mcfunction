# doom.consumable:shot/diff_bow —— bow 的统计差分（stat 上涨 = 本刻射出一次）
execute store result score #shot_now dc.temp run scoreboard players get @s dc.shot_use_bow
execute store result score #shot_prev dc.temp run scoreboard players get @s dc.shot_prev_bow
scoreboard players operation @s dc.shot_prev_bow = @s dc.shot_use_bow
execute if score #shot_now dc.temp > #shot_prev dc.temp run function doom.consumable:shot/process_one
