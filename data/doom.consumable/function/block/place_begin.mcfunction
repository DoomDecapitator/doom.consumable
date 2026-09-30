# doom.consumable:block/place_begin —— 放置链挂钩：给「刚放下那一格」挂上「出生即冷却」的设备
#
# 由 core/mark_placed 调用（调用前已确认**放置前的快照**里声明了 dc.place_cd）。
# ⚠ 实测坑：挂钩那一刻**手上已经不是那件物品了**（放置链是"用掉 dc 物品 → 放下方块 → 下一 tick 再把 dc 物品还回手"，
#   所以 `SelectedItem…dc.place_cd` 恒假 ⇒ 挂钩静默失效）。秒数只能从**使用前快照**取：
#   doom.library:io output[-1].data.CACHE.usage.data.{main_snap|off_snap}
execute unless data storage doom.consumable:ctx plc.seconds run data modify storage doom.consumable:ctx plc.seconds set from storage doom.library:io output[-1].data.CACHE.usage.data.main_snap.components."minecraft:custom_data"."dc".place_cd
execute unless data storage doom.consumable:ctx plc.seconds run data modify storage doom.consumable:ctx plc.seconds set from storage doom.library:io output[-1].data.CACHE.usage.data.off_snap.components."minecraft:custom_data"."dc".place_cd
execute unless data storage doom.consumable:ctx plc.seconds run return 0
scoreboard players set #pl_step dc.temp 0
scoreboard players set #pl_hit dc.temp 0
execute anchored eyes run function doom.consumable:block/place_ray
