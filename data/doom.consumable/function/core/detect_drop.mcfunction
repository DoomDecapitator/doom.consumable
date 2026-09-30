# doom.consumable:core/detect_drop — 扫描刚丢出的可丢弃物品
# 双 tick 窗口（Age:0s / Age:1s）容忍同 tick 的时序竞态：若 detect_drop 在本 tick 已经跑过、
# 物品才刚生成，就要靠下一 tick 的 Age:1s 那趟补上。
#
# F6 修复：冷却中的物品**不杀**（只把 PickupDelay 设为 0 让它被捡回），
#   于是它下一 tick 还是会命中 Age:1s 那趟 → 玩家收到两条 "on cooldown"。
#   现在冷却分支给它打上 dc_bounced 标记，两趟都排除它。
#   标记会随实体一起消失（捡起后实体销毁），所以不会影响下次丢弃。
execute as @e[type=item,tag=!dc_bounced,nbt={Age:0s,Item:{components:{"minecraft:custom_data":{dc:{discardable:1b}}}}}] at @s run function doom.consumable:schedule/discard_infinite
execute as @e[type=item,tag=!dc_bounced,nbt={Age:1s,Item:{components:{"minecraft:custom_data":{dc:{discardable:1b}}}}}] at @s run function doom.consumable:schedule/discard_infinite
