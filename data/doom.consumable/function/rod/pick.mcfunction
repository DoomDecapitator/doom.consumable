# doom.consumable:rod/pick —— 把「执行者手持的那把 dc 鱼竿」读进 storage（供 API 改组件后再写回）
#
# 产物（都在 storage doom.consumable:ctx rod 下）：
#   rod.item —— 物品整个 NBT（含 components）
#   rod.slot —— 写回目标槽位名（weapon.mainhand / weapon.offhand）
#   rod.src  —— 读取来源路径（SelectedItem / equipment.offhand，仅作调试标注）
#
# 优先级：主手是 dc 鱼竿就用主手，否则看副手；两处都不是 ⇒ rod.item 不存在（调用方 return）。
# ⚠ 写回用 `weapon.mainhand`（当前选中槽）就够：API 是"当场调用、当场写回"，不存在恢复链那种
#   1~2 tick 的换槽窗口 ⇒ 不需要 hotbar.N 精确定位（那套见 core/finalize_slot 与 restore/guard）。
data remove storage doom.consumable:ctx rod

execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{rod:1b} run data modify storage doom.consumable:ctx rod.item set from entity @s SelectedItem
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{rod:1b} run data modify storage doom.consumable:ctx rod.slot set value "weapon.mainhand"
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{rod:1b} run data modify storage doom.consumable:ctx rod.src set value "SelectedItem"
execute if data storage doom.consumable:ctx rod.item run return 0

execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{rod:1b} run data modify storage doom.consumable:ctx rod.item set from entity @s equipment.offhand
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{rod:1b} run data modify storage doom.consumable:ctx rod.slot set value "weapon.offhand"
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{rod:1b} run data modify storage doom.consumable:ctx rod.src set value "equipment.offhand"
