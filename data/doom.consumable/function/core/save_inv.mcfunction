# doom.consumable:core/save_inv — 由成就 inventory_changed 触发，保存背包 + 主副手快照
#
# 2026-09-11 代码评估：删掉了这里原有的"count diff 检测"路径。
#   原代码：
#     execute if entity @s[tag=dc.used] ... run function .../check_mainhand
#     execute if entity @s[tag=dc.used] ... run function .../check_offhand
#     execute if data ... task_data.slot_path run function .../process_consumed
#     tag @s remove dc.used
#   但 **dc.used 在整个工程里从未被 add 过**（全盘检索确认：只有 2 次检查、1 次移除、1 次取反）——
#   于是这三行永远不成立，check_mainhand / check_offhand / process_consumed 都是不可达代码。
#
#   判定这是**旧设计残留**而不是"漏写了一个 tag"的依据：
#   mark_placed 的头注释明确写着 "FIXED (K1): 放置即消耗…不再依赖 count diff（放置不改变 count，原逻辑永不触发）" ——
#   也就是说 place 类检测已经从 count diff 改成由 item_used_on_block 成就直接驱动，这条路被替换掉了。
#   保留死代码的代价是：读代码的人会以为这里有一层兜底检测，从而对漏检做出错误判断。
advancement revoke @s only doom.consumable:inv_change
# 2026-09-20：删掉了这里原有的 `data remove storage doom.consumable:ctx task_data`。
#   它和被删掉的 check_mainhand / check_offhand / process_consumed 是同一批旧设计残留 ——
#   那三个消费者没了，这行清理就成了纯粹的地雷：save_inv 由 inventory_changed 触发，
#   可能在**别人执行到一半**时嵌套跑起来，把在飞的 task_data 清掉，
#   于是紧接着读 task_data 的 schedule/* 会拿到空输入并静默按"字段缺失"处理。
#   （实测：doom.test:suite/consumable_limited 用例 J 就踩到过 —— DBG 打印 in=-1 maxbar=0。）
#   现在 task_data 的清理归设置它的那几个函数自己负责：
#   process_type 结尾、mark_placed 结尾、process_usage_wrapper 开头。
execute as @s run function doom.library:api/open
# Save compound cache
data modify storage doom.library:ctx _.cache_key set value "inventory"
data modify storage doom.library:ctx _.cache_data set value {}
data modify storage doom.library:ctx _.cache_data.Inventory set from entity @s Inventory
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc" run data modify storage doom.library:ctx _.cache_data.mainhand set from entity @s SelectedItem
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc" run data modify storage doom.library:ctx _.cache_data.offhand set from entity @s equipment.offhand
function doom.library:api/cache with storage doom.library:ctx _
data remove storage doom.library:ctx _.cache_key
data remove storage doom.library:ctx _.cache_data
