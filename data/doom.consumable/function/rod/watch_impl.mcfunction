# doom.consumable:rod/watch_impl [MACRO] —— 收杆监听的单玩家体
#
# 调用：rod/tick_one with storage doom.consumable:ctx rod（rod.uid = 玩家 UUID[0] int 分量）
# 判定（B1 根治，2026-09-30）：**自己的浮标没了** ⇒
#   · 还持杆（主/副手任一 fishing_rod）⇒ 玩家真按了右键收杆（含钓获取杆——on_rod_catch 在
#     retrieve 内同刻先行，之后这里再发通用 reel）⇒ rod/reel（发回调）
#   · 不持杆 ⇒ 外力（换手/丢杆/死亡/断线/超距自动收回）⇒ 静默归零（无回调，语义同旧版自愈）
# 引擎事实（javap 实锤）：收竿分支 = 零统计 + hurtAndBreak + ITEM_INTERACT_FINISH + 浮标实体消亡；
#   unbreakable 的 dc 杆不损耗耐久 ⇒ 耐久不能做区分信号——"还持不持杆"是唯一可靠旁证。
#   （超距断线会被并进"真收杆"——玩家仍持杆。已知并已接受的近似：两种都是"钓鱼结束了"。）
$execute if entity @e[type=minecraft:fishing_bobber, tag=dc_rod_own_$(uid)] run return 0
execute if items entity @s weapon.mainhand minecraft:fishing_rod run function doom.consumable:rod/reel
execute if score @s dc.rod_state matches 1.. if items entity @s weapon.offhand minecraft:fishing_rod run function doom.consumable:rod/reel
execute unless items entity @s weapon.mainhand minecraft:fishing_rod unless items entity @s weapon.offhand minecraft:fishing_rod run scoreboard players set @s dc.rod_state 0
