# doom.consumable:schedule/clear_slot [MACRO] —— 把"当初那个槽"里那件清掉（耗尽时用）
#
# 调用：execute if data storage doom.consumable:ctx task_data.slot_cmd if data storage doom.consumable:ctx task_data.id \
#           run function doom.consumable:schedule/clear_slot with storage doom.consumable:ctx task_data
# 宏参数：$(slot_cmd) 目标槽位名（hotbar.N / weapon.mainhand / weapon.offhand）、$(id) 物品 id
#
# ⚠⚠ 2026-09-27 两个教训都压在这里：
#   ① **只清"当初那个槽"**（旧版按 slot_path 清"当前手"）：玩家在消耗与恢复之间换过槽，
#      旧写法会把**新槽里**的东西直接删掉 —— 与 do_restore 的"吞物品"是同一个病。
#   ② 还要判"那槽里是不是**同一件**"：换上去的若是别的东西，一律不动。
#
# ⚠ 为什么单独成文件（而不是留在 schedule/limited 里写一行 $ ）：
#   含 $ 行的函数是**宏函数**，调用方必须给参数；不给的话整次调用会被拒（静默什么都不做）。
#   schedule/limited 是被多处方调用的老函数（还有手工/测试调用），把它变成宏函数等于给所有调用方
#   上了一道隐形门槛 —— 2026-09-27 就这么把 suite/consumable_limited 的 16 条断言打成失败。
#   现在 limited 保持"不写 $ 行"，需要清槽时在这里**带参**调用 ⇒ 老调用方一个字都不用改。
$execute if items entity @s $(slot_cmd) $(id) run item replace entity @s $(slot_cmd) with air
