# 探针：**不带** max_damage/damage 的荧石 + reach 归零修饰符 —— 属性会被压低吗？
# 用法：/function doom.consumable:test/probe_reach_nodamage
#
# 为什么验这个（2026-09-20 实测链条）：
#   · probe_reach   ：物品**没有** max_damage/damage → 修饰符生效 → 放不下去 ✓
#   · probe_reach_full B：物品 damage=5=max_damage（原版"已破损"）→ 读数显示
#                         attribute_modifiers **确实在物品上**，但 block_interaction_range 仍是 4500 → 不生效 ✗
#   ⇒ 结论：**破损物品的属性修饰符不生效**。
#   ⇒ 推论：disable 分支若要用这条杠杆，就必须把 max_damage/damage 一起删掉。
#     本探针就是把那个"应该可行"的形态摆出来验一遍。
#
# 读法（跑完自动打出来）：
#   block_interaction_range×1000 被压低（0 或负）= 杠杆可用 ✔
#   仍是 4500                                   = 我的推论错了，得另找路子
# 然后拿在手上右键：**放不下去**才算真的成功。

data modify storage doom.consumable:ctx probe_item set value {id:"minecraft:glowstone",count:1,components:{"minecraft:max_stack_size":1,"minecraft:attribute_modifiers":[{type:"minecraft:block_interaction_range",id:"dc:no_reach",amount:-10.0,operation:"add_value",slot:"mainhand"}],"minecraft:custom_data":{dc:{detect:"place",type:"limited",max_uses:5,current_uses:0,depleted:"disable"}}}}

kill @e[type=item_display,tag=dc_probe]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item set from storage doom.consumable:ctx probe_item
item replace entity @s weapon.mainhand from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe]

tellraw @s [{"text":"===== [R3] 无 max_damage/damage + reach 修饰符 =====","color":"gold"}]
function doom.consumable:test/_reach_diag
tellraw @s [{"text":"现在拿在手上右键：期望【放不下去】。再试开箱子/挖方块，看代价","color":"yellow"}]
