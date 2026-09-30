# doom.consumable:rod/gate —— 抛竿闸门（判据写进 #rod_deny dc.temp：1 = 否决）
#
# 三层条件（命中任一即否决）：
#   ① 物品标签 #doom.consumable:rod_locked —— 最省事的"禁用名单"：
#      把某把鱼竿（或整个 minecraft:fishing_rod）丢进去就不能用
#   ② 物品字段 dc.rod_locked:1b —— 由 api/rod_disable 写、api/rod_enable 清（状态跟着物品走）
#   ③ 函数标签 #doom.consumable:rod_gate —— 外部条件钩子：
#      在里面 `scoreboard players set #rod_deny dc.temp 1` 即可否决（默认空标签 = 放行）
#
# 为什么是"软否决"（先抛后收）而不是"直接不让抛"：
#   原版没有"使用前"钩子；能拦住"使用"动作的只有 use_cooldown（见 rod/lock）。
#   本函数在服务器 tick 的后段运行（玩家交互包在最前处理）⇒ 鱼漂刚生出来就被 kill，
#   玩家看不到、也拿不到任何产物，等效于"没抛"。两道防线叠加：
#   锁定中的鱼竿本来就挂着长冷却（原版直接拦），万一冷却失效还有这一层兜底。

execute if items entity @s weapon.mainhand #doom.consumable:rod_locked run scoreboard players set #rod_deny dc.temp 1
execute if items entity @s weapon.offhand #doom.consumable:rod_locked run scoreboard players set #rod_deny dc.temp 1
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{rod_locked:1b} run scoreboard players set #rod_deny dc.temp 1
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{rod_locked:1b} run scoreboard players set #rod_deny dc.temp 1

# 外部条件钩子（默认空标签）
function #doom.consumable:rod_gate
