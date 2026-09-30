# doom.consumable:shot/diff_trident —— trident 的统计差分（stat 上涨 = 本刻射出一次）
execute store result score #shot_now dc.temp run scoreboard players get @s dc.shot_use_trident
execute store result score #shot_prev dc.temp run scoreboard players get @s dc.shot_prev_trident
scoreboard players operation @s dc.shot_prev_trident = @s dc.shot_use_trident
execute if score #shot_now dc.temp > #shot_prev dc.temp run function doom.consumable:shot/process_one
