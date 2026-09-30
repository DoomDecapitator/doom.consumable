# 探针：方块放置的现场（放置前后各跑一次，或"物品丢了"之后立刻跑）
#
# 用法：/function doom.consumable:test/probe_place_state
#
# 一次打全四组信息，用来判断链条断在哪一段：
#   ① 手上那件（id / count / dc）
#   ② 三个计时器（restore_timer / consume_timer / discard_timer）
#   ③ 缓存（CACHE.consumable / CACHE.hand / CACHE.inventory.mainhand）
#   ④ **附近的中转体**：item_display 残留（dc_tmp / dc_restore_tmp / dt_tmp）——
#      它们是"恢复写出错东西"的嫌疑犯：limit=1 是"最近的那个"，残留会让恢复选中错实体。
tellraw @s [{"text":"===== [PLC] 放置现场 =====","color":"gold"}]

tellraw @s [{"text":"① 手上 id = ","color":"gray"},{"nbt":"SelectedItem.id","entity":"@s","color":"white"},{"text":"   count = ","color":"gray"},{"nbt":"SelectedItem.count","entity":"@s","color":"white"}]
tellraw @s [{"text":"① 手上 dc = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:custom_data\".\"dc\"","entity":"@s","color":"white"}]
# 关键：disalbe（耗尽后）会给物品挂 attribute_modifiers（触达 -10）
#   —— 拿着它就放不下任何方块，且物品还在手上；这一行就是用来认定它的。
tellraw @s [{"text":"①z 手持物的 attribute_modifiers = ","color":"gold"},{"nbt":"SelectedItem.components.\"minecraft:attribute_modifiers\"","entity":"@s","color":"white"},{"text":"   （有内容 = 触达被压低，放不下去是设计如此）","color":"yellow"}]
tellraw @s [{"text":"① 副手 id = ","color":"gray"},{"nbt":"equipment.offhand.id","entity":"@s","color":"white"}]

execute if score @s dc.restore_timer matches 1.. run tellraw @s [{"text":"② restore_timer ≥ 1（有任务待返还）","color":"green"}]
execute if score @s dc.restore_timer matches ..0 run tellraw @s [{"text":"② restore_timer ≤ 0（没有待返还任务）","color":"red"}]
execute if score @s dc.consume_timer matches 1.. run tellraw @s [{"text":"② consume_timer ≥ 1（使用管线在走）","color":"yellow"}]

tellraw @s [{"text":"①d 副手激增次数 = ","color":"gray"},{"score":{"name":"@s","objective":"dc.off_spike_n"},"color":"white"},{"text":"   最后一次在刻 = ","color":"gray"},{"score":{"name":"@s","objective":"dc.off_spike"},"color":"white"},{"text":"   （>0 = 幽灵真的出现过，已记下刻）","color":"yellow"}]
tellraw @s [{"text":"①c 恢复到主手 = ","color":"gray"},{"score":{"name":"@s","objective":"dc.placed_main"},"color":"white"},{"text":"   恢复到副手 = ","color":"gray"},{"score":{"name":"@s","objective":"dc.placed_off"},"color":"white"},{"text":"   （副手 > 0 = 落点翻过去了）","color":"yellow"}]
tellraw @s [{"text":"①b 成就触发 = ","color":"gray"},{"score":{"name":"@s","objective":"dc.trigger"},"color":"white"},{"text":"   入口识别 = ","color":"gray"},{"score":{"name":"@s","objective":"dc.placed"},"color":"white"},{"text":"   上次采纳的叠数 = ","color":"gray"},{"score":{"name":"@s","objective":"dc.lastcount"},"color":"white"},{"text":"   （触发 − 识别 = 没被认出的放置次数）","color":"yellow"}]

function doom.library:api/open
tellraw @s [{"text":"③ CACHE.consumable = ","color":"gray"},{"nbt":"output[-1].data.CACHE.consumable","storage":"doom.library:io","color":"white"}]
tellraw @s [{"text":"③ CACHE.hand = ","color":"gray"},{"nbt":"output[-1].data.CACHE.hand","storage":"doom.library:io","color":"white"}]

tellraw @s [{"text":"④ 残留中转体（有则说明上次恢复没走到 kill）","color":"gray"}]
execute as @e[type=item_display,tag=dc_restore_tmp,limit=1] run tellraw @s [{"text":"   ↳ dc_restore_tmp 拿着："},{"nbt":"item.id","entity":"@e[type=item_display,tag=dc_restore_tmp,limit=1]","color":"white"}]
execute as @e[type=item_display,tag=dc_tmp,limit=1] run tellraw @s [{"text":"   ↳ dc_tmp（recover/step 共用 tag）拿着："},{"nbt":"item.id","entity":"@e[type=item_display,tag=dc_tmp,limit=1]","color":"white"}]
tellraw @s [{"text":"④ 判读：若上面出现残留中转体行，说明上次恢复没走到 kill —— 那一次的恢复很可能写错了物品。","color":"yellow"}]
