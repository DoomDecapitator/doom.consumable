# doom.consumable:shot/tick_one —— 单个玩家的一步
# 闸门：背包与副手都没有 dc{detect:"shot"} 物品 ⇒ return（零开销早退；Inventory 谓词覆盖全背包含主手）
execute unless data entity @s Inventory[{components:{"minecraft:custom_data":{dc:{detect:"shot"}}}}] unless data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{detect:"shot"} run return 0

# 惰性哨兵（B10 教训）：首见玩家把 prev 同步为当前 stat，消掉历史积累（防首判定假事件虚扣）。
# 「无分数」检测：matches 全域对无分数返回 false ⇒ unless 命中 ⇒ 同步；有分数零开销。
execute unless score @s dc.shot_prev_bow matches -2147483648..2147483647 run scoreboard players operation @s dc.shot_prev_bow = @s dc.shot_use_bow
execute unless score @s dc.shot_prev_crossbow matches -2147483648..2147483647 run scoreboard players operation @s dc.shot_prev_crossbow = @s dc.shot_use_crossbow
execute unless score @s dc.shot_prev_trident matches -2147483648..2147483647 run scoreboard players operation @s dc.shot_prev_trident = @s dc.shot_use_trident

# 差分判定：主手是哪件武器就查哪个 stat（物品 id + dc{detect:"shot"} 双条件合取）
data modify storage doom.consumable:ctx shot.main set value 1b
execute if items entity @s weapon.mainhand minecraft:bow if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{detect:"shot"} run function doom.consumable:shot/diff_bow
execute if items entity @s weapon.mainhand minecraft:crossbow if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{detect:"shot"} run function doom.consumable:shot/diff_crossbow
execute if items entity @s weapon.mainhand minecraft:trident if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{detect:"shot"} run function doom.consumable:shot/diff_trident
# 主手不是 shot 武器 ⇒ 查副手（同款三连；hand 标记改 0b）
execute unless items entity @s weapon.mainhand minecraft:bow unless items entity @s weapon.mainhand minecraft:crossbow unless items entity @s weapon.mainhand minecraft:trident run data modify storage doom.consumable:ctx shot.main set value 0b
execute unless items entity @s weapon.mainhand minecraft:bow unless items entity @s weapon.mainhand minecraft:crossbow unless items entity @s weapon.mainhand minecraft:trident if items entity @s weapon.offhand minecraft:bow if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{detect:"shot"} run function doom.consumable:shot/diff_bow
execute unless items entity @s weapon.mainhand minecraft:bow unless items entity @s weapon.mainhand minecraft:crossbow unless items entity @s weapon.mainhand minecraft:trident if items entity @s weapon.offhand minecraft:crossbow if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{detect:"shot"} run function doom.consumable:shot/diff_crossbow
execute unless items entity @s weapon.mainhand minecraft:bow unless items entity @s weapon.mainhand minecraft:crossbow unless items entity @s weapon.mainhand minecraft:trident if items entity @s weapon.offhand minecraft:trident if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{detect:"shot"} run function doom.consumable:shot/diff_trident

# ⚠ 2026-10-05 清理（由新增的 consumable_shot 套件用例 A2/B2/D2 抓到）：
#   `shot.main` 是给 process_one 用的**单次调用**载荷，但只有"stat 真的涨了"那条路会进
#   process_one，而清理写在 process_one 的末尾（⑪）。⇒ **没有涨的那些 tick 会把它留在
#   storage 里**（实测：持弓空跑一刻后 `ctx.shot = {main:1b}` 常驻）。
#   危害等级：**当前无功能影响** —— tick_one 每刻都会在派发前重写 shot.main，
#   下一拍的 process_one 读到的仍是本拍的值；而且本包内没有别的读者。
#   但仍必须清：① storage 是**跨包共享**的（`doom.consumable:ctx` 不是私有命名空间），
#   常驻残渣会让别的作者的 `data get` 诊断读到误导性内容；
#   ② 一旦将来给 process_one 增加别的入口（比如 API 直调），残渣就会变成**真 bug**。
#   ⇒ 在 tick_one 收尾无条件清一次：有事件的拍早被 process_one 清掉了，这里是幂等的空操作。
data remove storage doom.consumable:ctx shot
