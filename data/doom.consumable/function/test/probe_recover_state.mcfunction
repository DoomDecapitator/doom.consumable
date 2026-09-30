# 探针：读"伪耐久条"物品的当前状态（拿着它运行即可，不依赖"用一次"）
# 用法：手上拿着那件物品，运行 /function doom.consumable:test/probe_recover_state
#
# 2026-09-27 改版：计时状态**不再存在玩家分数上**（dc.recover / step / interval 已停用），
#   改由物品自带的 `dc.rb_cd`（离下一格的剩余 tick）表示 —— 所以这里直接打印物品里的字段，
#   再同步驱动一次 recover/tick 看它有没有动。
tellraw @s [{"text":"===== [RB] 状态 =====（2026-09-27 起状态在物品自己身上：dc.rb_cd）","color":"gold"}]
tellraw @s [{"text":"id = ","color":"gray"},{"nbt":"SelectedItem.id","entity":"@s","interpret":false,"color":"white"}]
tellraw @s [{"text":"damage / max_damage = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:damage\"","entity":"@s","interpret":false,"color":"white"},{"text":" / ","color":"dark_gray"},{"nbt":"SelectedItem.components.\"minecraft:max_damage\"","entity":"@s","interpret":false,"color":"white"}]
tellraw @s [{"text":"consumable = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:consumable\"","entity":"@s","interpret":false,"color":"white"}]
tellraw @s [{"text":"use_cooldown = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:use_cooldown\"","entity":"@s","interpret":false,"color":"white"}]
tellraw @s [{"text":"dc = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:custom_data\".\"dc\"","entity":"@s","interpret":false,"color":"white"}]

# 同步驱动一次：起表之后 rb_cd 应当出现，并逐 tick 递减
function doom.consumable:recover/tick
tellraw @s [{"text":"驱动 1 tick 后的 dc = ","color":"gold"},{"nbt":"SelectedItem.components.\"minecraft:custom_data\".\"dc\"","entity":"@s","interpret":false,"color":"white"}]
tellraw @s [{"text":"判读：damage ≥ 1 且 dc.rb_cd 出现（≈ recover_ticks−1）= 计时在跑，之后每 recover_ticks tick 涨一格；rb_cd 缺失 = 没在回（多半是 damage 为 0，或它不在手/背包里）","color":"yellow"}]
