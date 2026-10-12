# doom.consumable:throw/tick_one —— 单个玩家的一步（投掷链）
#
# 结构与 shot/tick_one **逐行同构**（这是刻意的：作者只需学一套）；
# 差别只有两处：
#   ① 事件源是 dc.throw_use_{snowball,egg,ender_pearl,xp_bottle}，不是弓弩戟
#   ② 物品 id 用**逐件**判定（`items entity @s weapon.mainhand minecraft:snowball` …），
#      因为投掷物各自独立，不像弓/弩/三叉戟那样共享同一套 dc 字段语义
#
# 闸门：背包与副手都没有 dc{detect:"throw"} 物品 ⇒ return（零开销早退，同 shot）
execute unless data entity @s Inventory[{components:{"minecraft:custom_data":{dc:{detect:"throw"}}}}] unless data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{detect:"throw"} run return 0

# 惰性哨兵（同 shot：首见玩家同步 prev = 当前 stat，消历史积累防首判定虚扣）
execute unless score @s dc.throw_prev_snowball matches -2147483648..2147483647 run scoreboard players operation @s dc.throw_prev_snowball = @s dc.throw_use_snowball
execute unless score @s dc.throw_prev_egg matches -2147483648..2147483647 run scoreboard players operation @s dc.throw_prev_egg = @s dc.throw_use_egg
execute unless score @s dc.throw_prev_ender_pearl matches -2147483648..2147483647 run scoreboard players operation @s dc.throw_prev_ender_pearl = @s dc.throw_use_ender_pearl
execute unless score @s dc.throw_prev_xp_bottle matches -2147483648..2147483647 run scoreboard players operation @s dc.throw_prev_xp_bottle = @s dc.throw_use_xp_bottle

# 差分判定（主手优先，副手兜底）——与 shot 同构，只是每种投掷物各查各的 stat
data modify storage doom.consumable:ctx throw.main set value 1b
execute if items entity @s weapon.mainhand minecraft:snowball if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{detect:"throw"} run function doom.consumable:throw/diff_snowball
execute if items entity @s weapon.mainhand minecraft:egg if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{detect:"throw"} run function doom.consumable:throw/diff_egg
execute if items entity @s weapon.mainhand minecraft:ender_pearl if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{detect:"throw"} run function doom.consumable:throw/diff_ender_pearl
execute if items entity @s weapon.mainhand minecraft:experience_bottle if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{detect:"throw"} run function doom.consumable:throw/diff_xp_bottle
execute unless items entity @s weapon.mainhand minecraft:snowball unless items entity @s weapon.mainhand minecraft:egg unless items entity @s weapon.mainhand minecraft:ender_pearl unless items entity @s weapon.mainhand minecraft:experience_bottle run data modify storage doom.consumable:ctx throw.main set value 0b
execute unless items entity @s weapon.mainhand minecraft:snowball unless items entity @s weapon.mainhand minecraft:egg unless items entity @s weapon.mainhand minecraft:ender_pearl unless items entity @s weapon.mainhand minecraft:experience_bottle if items entity @s weapon.offhand minecraft:snowball if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{detect:"throw"} run function doom.consumable:throw/diff_snowball
execute unless items entity @s weapon.mainhand minecraft:snowball unless items entity @s weapon.mainhand minecraft:egg unless items entity @s weapon.mainhand minecraft:ender_pearl unless items entity @s weapon.mainhand minecraft:experience_bottle if items entity @s weapon.offhand minecraft:egg if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{detect:"throw"} run function doom.consumable:throw/diff_egg
execute unless items entity @s weapon.mainhand minecraft:snowball unless items entity @s weapon.mainhand minecraft:egg unless items entity @s weapon.mainhand minecraft:ender_pearl unless items entity @s weapon.mainhand minecraft:experience_bottle if items entity @s weapon.offhand minecraft:ender_pearl if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{detect:"throw"} run function doom.consumable:throw/diff_ender_pearl
execute unless items entity @s weapon.mainhand minecraft:snowball unless items entity @s weapon.mainhand minecraft:egg unless items entity @s weapon.mainhand minecraft:ender_pearl unless items entity @s weapon.mainhand minecraft:experience_bottle if items entity @s weapon.offhand minecraft:experience_bottle if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{detect:"throw"} run function doom.consumable:throw/diff_xp_bottle

# 清理（同 shot/tick_one：没事件的 tick 也要清掉 throw.main，不留跨包残渣）
data remove storage doom.consumable:ctx throw
