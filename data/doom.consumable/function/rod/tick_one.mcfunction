# doom.consumable:rod/tick_one —— 单个玩家的一步（tick 的逐玩家体）
#
# 调用：execute as <玩家> at @s run function doom.consumable:rod/tick_one
#
# 早退闸门：身上一件 dc{rod:1b} 都没有、且没在钓鱼 ⇒ 直接 return。
#   为什么要带上 dc.rod_state：玩家可能把鱼竿丢出去/换走，但状态还停在 1，
#   那也必须继续跟踪，否则状态永远卡住（收杆事件没人接）。
execute unless data entity @s Inventory[{components:{"minecraft:custom_data":{dc:{rod:1b}}}}] unless data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{rod:1b} unless score @s dc.rod_state matches 1.. run return 0

# B10 修复（2026-09-30 真机实锤）：__load__ 从不创建 dc.rod_state 分数，唯一建分路径全在本闸门之后
#   ⇒ 新玩家（reload 后加入）状态机冷启动死锁（matches ..0 对无分数永假）。
#   add 0 幂等建分：无分数建 0，已有分数不受影响。
scoreboard players add @s dc.rod_state 0

# ---- ① 统计事件：本刻「抛竿」次数是否上涨 ----
# 读一次、存一次；#rod_now/#rod_prev 是共享临时分数，但本文件一次只服务一个玩家（调用方是单行 as @a）⇒ 安全。
# B1 修复（2026-09-30 源码实锤）：used:fishing_rod 的 awardStat 只在 FishingRodItem.use 的**抛竿分支**
#   （字节码 198-205）；收竿分支零统计 ⇒ 统计上涨永远是抛竿。旧版"状态 1 + 统计涨 ⇒ 收杆"的路由
#   是错杀（真收杆从不涨统计，该路由只在状态残留后的下一次抛竿时错发 reel）——已删。
#   收杆事件源改走 ④ 的浮标死亡监听。
# B11 修复（2026-10-01 E2E 实测发现）：stat 目标分（dc.rod_use）与 dummy 分（dc.rod_prev）在"全新玩家首次 tick"
#   时可能不存在，此时下面第 22 行的 store 会失败 ⇒ 共享临时 #rod_prev 保留**上一个玩家**的残留值，
#   与 #rod_now 一比就可能误判"统计上升" ⇒ 发出一次幽灵 on_rod_cast +（随后浮标不存在）幽灵 on_rod_reel。
#   add 0 幂等建分（与上面 dc.rod_state 同一手法）：无分数建 0，已有分数不变。保证两者参与比较前一定有值。
scoreboard players add @s dc.rod_use 0
scoreboard players add @s dc.rod_prev 0

execute store result score #rod_now dc.temp run scoreboard players get @s dc.rod_use
execute store result score #rod_prev dc.temp run scoreboard players get @s dc.rod_prev
scoreboard players operation @s dc.rod_prev = @s dc.rod_use
execute if score #rod_now dc.temp > #rod_prev dc.temp run function doom.consumable:rod/cast

# ---- ② 锁定维护（disable 的"硬"半边）----
# 手持的是被禁用的鱼竿、且当前没挂冷却 ⇒ 挂一次长冷却，让原版自己拦住"使用"。
# 冷却到期后下一 tick 会自动续上 ⇒ 锁定期内始终不可用。
execute if items entity @s weapon.mainhand #doom.consumable:rod_locked unless data entity @s SelectedItem.components."minecraft:use_cooldown" run function doom.consumable:rod/lock
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{rod_locked:1b} unless data entity @s SelectedItem.components."minecraft:use_cooldown" run function doom.consumable:rod/lock
execute if items entity @s weapon.offhand #doom.consumable:rod_locked unless data entity @s equipment.offhand.components."minecraft:use_cooldown" run function doom.consumable:rod/lock
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{rod_locked:1b} unless data entity @s equipment.offhand.components."minecraft:use_cooldown" run function doom.consumable:rod/lock

# ---- ④ 收杆监听：在钓 + 自己的浮标没了 ⇒ 真收杆（外力则静默自愈）----
# uid 缺分（旧包升级后的状态残留）⇒ 先静默自愈——防止宏缺参让 watch_impl 整函数中止（宏纪律①）
execute if score @s dc.rod_state matches 1.. unless score @s dc.rod_uid matches ..2147483647 run scoreboard players set @s dc.rod_state 0
# 存 uid 进 storage（读分板比读实体 NBT 便宜）→ 宏体监听；storage 共享，但逐玩家串行 ⇒ 安全
execute if score @s dc.rod_state matches 1.. store result storage doom.consumable:ctx rod.uid int 1 run scoreboard players get @s dc.rod_uid
execute if score @s dc.rod_state matches 1.. run function doom.consumable:rod/watch_impl with storage doom.consumable:ctx rod
