# doom.consumable:recover/tick_one —— **单个玩家**的一步回复（tick 的逐玩家体）
# 调用：execute as <玩家> at @s run function doom.consumable:recover/tick_one
#
# ⚠⚠ 为什么必须"一个玩家一口气跑完"，而不是在 tick 里写两条 `as @a` 行：
#   共享临时（storage rb.item、中转体 tag dc_rb + limit=1）是**全局一份**。
#   若写成
#       execute as @a run function …/取件
#       execute as @a[scores=…] run function …/写回
#   那么第二条开始时，rb.item 里剩的是**最后一个玩家**的物品 ⇒ 多玩家必然乱序。
#   **单玩家测不出来**（套件就是单玩家）。合进一个逐玩家入口之后，
#   共享临时在同一次调用内写入、用完即清 ⇒ 天然串行。
#   （这条正是易错点总结 §2.4「递归/循环中的 storage 污染」；2026-09-26 由玩家当场指出并修。）
#
# 2026-09-27 改版（玩家报障「两件同时在身上时条会串台/跳变」）：
#   · 计时状态从**玩家分数**搬到**物品自己身上**（dc.rb_cd）⇒ 几件都各算各的，不串台
#   · 因此"每 tick 只认一件"的老限制必须去掉：改为**逐槽扫**（recover/scan，36 槽）+ 副手单独一步，
#     保证每一件都被访问到（旧版按"主手 > 副手 > 背包"只取第一件，第二件永远轮不到）
#   · 换手 / 换槽 / 进背包都不再影响进度：状态跟着物品走
#
# 门槛：身上一件带 dc{recover:1b} 的都没有 ⇒ 直接 return（绝大多数玩家零开销）。
#   只有真的带着这类物品的玩家才付出"36 条守卫行"的代价。
#
# 开关 #rb_bag dc.cfg：1（默认）= 连背包一起扫；0 = 退回"只认手部"（主手 + 副手）。
#   留在套件里当隔离手段：玩家身上别的测试残留不会污染"手部"用例。
execute unless data entity @s Inventory[{components:{"minecraft:custom_data":{dc:{recover:1b}}}}] unless data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{recover:1b} run return 0

# 0) 并发自检（易错点 §2.4.1 的运行时哨兵）：进入时共享临时键 rb.item 必须是**干净**的。
#    它由上一次调用在结尾清掉；这里还残留 ⇒ 有人跨行共享了它 ⇒ 报 E201（doom.log 负责防刷屏）。
#    ⚠ 必须在下面那行 `data remove … rb.item` **之前**，否则自己先把它清了，哨兵永远看不见残留。
#    （2026-09-27 recover 改版重写本文件时这条调用被漏掉，同日检视找回；勿再删。）
execute if data storage doom.consumable:ctx rb.item run function doom.consumable:core/report_ctx_dirty

# 清理共享临时（哨兵已确认它是干净的才走到这里）
data remove storage doom.consumable:ctx rb.item

# ---------- 副手（不在 Inventory 列表里，单独一步）----------
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{recover:1b} run data modify storage doom.consumable:ctx rb.item set from entity @s equipment.offhand
data modify storage doom.consumable:ctx args set value {name:"weapon.offhand",slot:1}
execute if data storage doom.consumable:ctx rb.item run function doom.consumable:recover/hit with storage doom.consumable:ctx args

# ---------- 主手 + 背包 ----------
# #rb_bag = 1：36 槽全扫。主手就是其中那个**选中的热键槽**，由扫描统一处理 ——
#   不要再单独处理一次主手，否则同一 tick 会把同一件扣两格。
execute if score #rb_bag dc.cfg matches 1 run function doom.consumable:recover/scan

# #rb_bag = 0：只认手部（主手 + 上面的副手），背包里的那件不动
data remove storage doom.consumable:ctx rb.item
execute if score #rb_bag dc.cfg matches 0 if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{recover:1b} run data modify storage doom.consumable:ctx rb.item set from entity @s SelectedItem
execute if score #rb_bag dc.cfg matches 0 run data modify storage doom.consumable:ctx args set value {name:"weapon.mainhand",slot:0}
execute if score #rb_bag dc.cfg matches 0 if data storage doom.consumable:ctx rb.item run function doom.consumable:recover/hit with storage doom.consumable:ctx args

# 兜底清理共享路径（recover/scan 自己也会清；这条保证"不扫背包"那条分支同样干净）
data remove storage doom.consumable:ctx rb.item
