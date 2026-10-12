# ⚠ 2026-10-05 修复（由新增的 consumable_shot 套件用例 K1 抓到）：
#   原写法 `if data storage doom.consumable:ctx shot.main` 是**存在性**测试，
#   而 shot.main 恒为 **1b 或 0b 二者之一** ⇒ 该条件**永远为真** ⇒
#   「副手」那一支（unless …）**永远不执行**。
#   后果：主手不是 shot 武器、只有副手是时，process_one 会去读**主手**（读到石头 ⇒
#   dc 复核不过 ⇒ 整次扣次被丢弃），writeback / depleted 也会往**主手**写。
#   ⇒ 副手射击链在真机上**完全不工作**（静默无效果，不报错）。
#   ⇒ 改为**值判定** `shot{main:1b}`（1b=主手走 if，0b=副手走 unless）。
# doom.consumable:shot/depleted_disable —— disable 耗尽：物品留手 + use_cooldown 长冷却（拉不了弓的灰条）
# shot_locked 字段标记状态（tick_one 闸门后由锁定维护续杯——同 rod/lock 模式）。
kill @e[type=item_display,tag=dc_shot_tmp]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_item","dc_shot_tmp"],item:{id:"minecraft:stone",count:1}}
execute if data storage doom.consumable:ctx shot{main:1b} run data modify entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item set from entity @s SelectedItem
execute unless data storage doom.consumable:ctx shot{main:1b} run data modify entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item set from entity @s equipment.offhand
data modify entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item.components."minecraft:custom_data".dc.shot_locked set value 1b
data modify entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item.components."minecraft:use_cooldown" set value {seconds:3600f}
execute if data storage doom.consumable:ctx shot{main:1b} run item replace entity @s weapon.mainhand from entity @e[type=item_display,tag=dc_shot_tmp,limit=1] contents
execute unless data storage doom.consumable:ctx shot{main:1b} run item replace entity @s weapon.offhand from entity @e[type=item_display,tag=dc_shot_tmp,limit=1] contents
kill @e[type=item_display,tag=dc_shot_tmp,limit=1]
