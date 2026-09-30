# doom.consumable:api/rod_reel —— 收回执行者自己的鱼漂（并清状态；无回调）
#
# 用途：
#   ① 外部逻辑"打断钓鱼"（玩家进限制区、被传送、切维度前收尾、剧情打断……）
#   ② 按钮模式：on_rod_cast 回调里调用 = orbital 式"抛竿当单击触发器"（浮标活不过一 tick，
#     状态归 0 ⇒ 每次右键都是干净的 cast 事件）
# B1 修复（2026-09-30 真机实锤）：旧版用 `Owner:[I;…]` NBT 匹配——1.21.6 浮标存档**没有
#   Owner 字段**（旧注释里"匹配会静默失败"的警告已成现实，收不掉）。新版匹配抛竿时打的
#   归属标签 dc_rod_own_<uid>（rod/bind_impl），uid 读 @s dc.rod_uid 分数（cast_ok 缓存）。
#   手动核对法：`tag @e[type=fishing_bobber] list` 看归属标签是否在。
# 与 rod/reel 的区别：本函数是"外部强收"（清状态、**不**发 on_rod_reel 回调）；
#   玩家自己按右键收杆走的是 rod/watch_impl → rod/reel（有回调）。
# ⚠ 只收 dc 鱼竿抛出的浮标（归属标签只在 rod/cast_ok 绑定）；纯原版浮标请直接 /kill。
#   强收**不走**引擎 retrieve：没有拉拽/钓获/耐久损耗——它是"打断"，不是"收杆"。
data remove storage doom.consumable:ctx rod
execute store result storage doom.consumable:ctx rod.uid int 1 run scoreboard players get @s dc.rod_uid
execute if data storage doom.consumable:ctx rod.uid run function doom.consumable:api/rod_reel_impl with storage doom.consumable:ctx rod
scoreboard players set @s dc.rod_state 0
data remove storage doom.consumable:ctx rod
