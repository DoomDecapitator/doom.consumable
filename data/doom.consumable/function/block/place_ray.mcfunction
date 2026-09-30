# doom.consumable:block/place_ray —— 从眼睛沿视线找「第一个非空气方块」= 刚放下的那一格
# 与 block/ray_step 同一手法；命中后 align xyz 再交给 place_mark（~ ~ ~ 就是那一格）。
scoreboard players add #pl_step dc.temp 1
execute unless block ~ ~ ~ #doom.consumable:air_like run execute align xyz run function doom.consumable:block/place_mark
execute if score #pl_hit dc.temp matches 1 run return 0
execute if score #pl_step dc.temp matches ..20 positioned ^ ^ ^0.25 run function doom.consumable:block/place_ray
