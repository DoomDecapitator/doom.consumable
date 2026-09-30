# doom.consumable:core/finalize_slot —— 给 task_data 定死"恢复落点"与"物品 id"
#
# 调用：execute if data storage doom.consumable:ctx task_data.hand run function doom.consumable:core/finalize_slot
# 前置：task_data.slot_path 已定（weapon.mainhand / weapon.offhand）、task_data.item 已在。
#
# 2026-09-27 新增。这两个字段是给恢复链的**写入守卫**用的（见 restore/guard）：
#   · id       —— "目标槽位里还是不是同一件"（是 ⇒ 可以覆盖：那是同一叠没用完的）
#   · slot_cmd —— 目标槽位名。主手能精确到 `hotbar.N`（用消耗/放置那一刻的 SelectedItemSlot）；
#                 副手固定 `weapon.offhand`。
#
# 为什么必须精确到槽位：旧版只有 `slot_path`，而 `weapon.mainhand` 指的是
#   **当前选中那一格**，不是"当初用的那一格"。消耗与恢复之间隔着 1~2 tick，
#   玩家换一下槽（滚轮/数字键）或捡到别的东西，恢复就会写进**新槽**，
#   `item replace` 是无条件替换 ⇒ 新槽里原本的东西被直接抹掉。
#   玩家报障原话：「频繁切换物品使用会吞物品」。
#   （这一条在作者自己的 mark_placed 注释里也出现过同族现象："物品被送到下一个槽位"。）
#
# 兼容性：SelectedItemSlot 读不到（或旧缓存没有 sel）时 slot_cmd 退化成 slot_path，行为与旧版一致，
#   由 restore/guard 的"占用就换地方"兜底，绝不覆盖。

execute if data storage doom.consumable:ctx task_data.item.id run data modify storage doom.consumable:ctx task_data.id set from storage doom.consumable:ctx task_data.item.id

# 默认落点 = slot_path（旧行为）
execute if data storage doom.consumable:ctx task_data.slot_path run data modify storage doom.consumable:ctx task_data.slot_cmd set from storage doom.consumable:ctx task_data.slot_path

# 主手：能拿到"当时的选中槽号"就精确成 hotbar.N
data remove storage doom.consumable:ctx sel
scoreboard players set #sel dc.temp -1
execute if data storage doom.consumable:ctx task_data{slot_path:"weapon.mainhand"} if data storage doom.consumable:ctx task_data.sel store result score #sel dc.temp run data get storage doom.consumable:ctx task_data.sel
execute if score #sel dc.temp matches 0..8 store result storage doom.consumable:ctx sel.n int 1 run scoreboard players get #sel dc.temp
execute if score #sel dc.temp matches 0..8 run function doom.consumable:core/sel_slot_cmd with storage doom.consumable:ctx sel
execute if score #sel dc.temp matches 0..8 if data storage doom.consumable:ctx sel.cmd run data modify storage doom.consumable:ctx task_data.slot_cmd set from storage doom.consumable:ctx sel.cmd
data remove storage doom.consumable:ctx sel
