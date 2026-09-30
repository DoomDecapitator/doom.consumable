# doom.consumable:test/probe_rod —— 鱼竿接口现场探针（真机核对用）
#
# 一次执行回答三个问题：
#   ① 统计事件到底涨不涨：抛竿一次、收杆一次，各执行一次本函数看 dc.rod_use 的变化
#      （设计依赖它：每个"使用鱼竿"动作 +1）
#   ② 状态机跟不跟得上：抛竿后 dc.rod_state 应为 1，收杆 / 鱼漂消失后应为 0
#   ③ 鱼漂的 Owner 字段长什么样：api/rod_reel 的宏选择器依赖它的写法（Owner:[I;a,b,c,d]），
#      若某个版本改了字段，这里能一眼看出来
#
# 用法：手里拿 test/give_rod 给的那把，站在水边：
#   function doom.consumable:test/probe_rod   ← 抛竿前
#   右键抛竿，再执行一次
#   右键收杆，再执行一次
tellraw @s [{"text":"[dc.rod] 统计 dc.rod_use = ","color":"aqua"},{"score":{"name":"@s","objective":"dc.rod_use"}},{"text":"　状态 dc.rod_state = ","color":"aqua"},{"score":{"name":"@s","objective":"dc.rod_state"}},{"text":"　成功钩取 dc.rod_catch = ","color":"aqua"},{"score":{"name":"@s","objective":"dc.rod_catch"}}]
execute if entity @e[type=minecraft:fishing_bobber] run tellraw @s [{"text":"[dc.rod] 鱼漂 NBT（核对 Owner 字段，可整行发我）：","color":"yellow"}]
execute if entity @e[type=minecraft:fishing_bobber] run data get entity @e[type=minecraft:fishing_bobber,limit=1]
execute unless entity @e[type=minecraft:fishing_bobber] run tellraw @s [{"text":"[dc.rod] 当前世界里没有鱼漂（未抛竿 / 已收杆）","color":"gray"}]
