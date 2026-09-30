# doom.consumable:test/ghost_start_on —— 【第二轮】从零开始（客户端重同步 = 开）
#
# 与 ghost_start 唯一的差别就是 #resync = 1 —— 这正是这一轮要对比的唯一变量。
scoreboard players set #resync dc.cfg 1
function doom.consumable:test/ghost_wipe
function doom.consumable:test/place_rapid
tellraw @s [{"text":"── 第二轮：重同步 = 开（对比轮） ──","color":"gold"}]
tellraw @s [{"text":"① 与第一轮**同样的时长、同样的扫法**按住右键；盯住同一个问题：手里那件是不是还看不见？","color":"yellow"}]
tellraw @s [{"text":"② 松手后跑 /function doom.consumable:test/report_place。两轮表现不同 ⇒ 病根就是槽位同步包；一样 ⇒ 与数据包无关。","color":"yellow"}]
