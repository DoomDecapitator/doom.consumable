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
