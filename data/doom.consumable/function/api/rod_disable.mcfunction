# doom.consumable:api/rod_disable —— 禁用执行者手上的鱼竿（写 dc.rod_locked:1b + 挂长冷却）
#
# 效果（两道防线）：
#   ① 软否决：之后每次抛竿都被 rod/gate 判为否决 ⇒ 同 tick 收回鱼漂（等效"抛不出去"）
#   ② 硬禁用：顺带挂 use_cooldown（由 rod/tick_one 续期）⇒ 原版直接拦住"使用"，
#      热键栏显示灰条 ⇒ 玩家看得见"现在不能用"
# 解除：function doom.consumable:api/rod_enable
# 另一条禁用入口：物品标签 #doom.consumable:rod_locked（把鱼竿丢进去即禁用，不用改物品数据）
function doom.consumable:rod/pick
execute unless data storage doom.consumable:ctx rod.item run return 0
data modify storage doom.consumable:ctx rod.item.components."minecraft:custom_data"."dc".rod_locked set value 1b
function doom.consumable:rod/writeback with storage doom.consumable:ctx rod
function doom.consumable:rod/lock
