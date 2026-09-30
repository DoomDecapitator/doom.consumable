# doom.consumable:schedule/limited — 扣一次使用次数，把恢复数据写进 CACHE.consumable
#
# 2026-09-11 代码评估后修复：
#   F4  current_uses 缺失会被判成"立即耗尽"：旧写法直接 store result，data get 失败时不写入 →
#       #uses 停在 0 → 减 1 变 -1 → 条件 ..0 成立 → **物品第一次使用就被销毁**。
#       现改为先置 -1 哨兵：只有"读不到字段"才保持负数，与"真的是 0"区分开；缺失时用 max_uses 兜底。
#   F2  扣血值必须基于 max_damage（耐久条 = damage / max_damage），不是 max_uses。
#       旧写法在 max_damage ≠ max_uses 时耐久条只走到一部分；当前两个物品恰好都是 5，掩盖了这个错误。
#   F7  删掉一行重复的 #damage 赋值。
#
# F3：清空手持的条件里**排除 disable**。其余模式（vanish / remainder / 默认）物品都该消失，
#     必须清掉手上那份；disable 的物品要原样留着（只是不能再触发），清了再由 do_restore 放回会闪一下。
#     旧写法的守卫只有 task_data{slot_path:…}，与它自己的注释（"vanish 需清除手上残留物品"）不符。
scoreboard players set #uses dc.temp 0
scoreboard players set #damage dc.temp 0
scoreboard players set #maxbar dc.temp 0

# 扣血基准：优先 max_damage 组件（耐久条 = damage / max_damage）；没有则退回 max_uses。
# 无 max_damage 的物品不会写 damage 组件（见 do_restore），这里的值用不上。
#
# 2026-09-20：四个 limited 苹果（limited/vanish/disable/remainder_apple）的 max_damage 行曾丢失，
#   导致苹果**没有耐久条**（glowstone 那一半都有）。已按参考实现 bs_改进版 补回 `max_damage: 5`。
#   现在 apple / glowstone 两支行为一致：耐久条 = 剩余次数（5→1，耗尽时满格 → 消失/返还/禁用）。
execute store result score #maxbar dc.temp run data get storage doom.consumable:ctx task_data.item.components."minecraft:max_damage"
execute if score #maxbar dc.temp matches ..0 store result score #maxbar dc.temp run data get storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc".max_uses

# #uses：读 current_uses；读不到才退回 max_uses
#
# ⚠ 2026-09-20 修正（由 doom.test:suite/consumable_limited 用例 E 抓到）：
#   旧写法先置 -1 哨兵、再无条件 `execute store result … run data get`，指望"字段缺失时 store 不发生"。
#   **实测这个假设是错的**：路径缺失时 store 仍然执行，把分数写成 0 —— 于是哨兵永远是 0、
#   兜底分支永远不触发 → #uses = 0-1 = -1 → 判为耗尽 → 物品**第一次使用就被销毁**。
#   现在改成用 `if data` 先把 store 本身挡住：字段不在，store 根本不执行，哨兵才真的有意义。
scoreboard players set #uses dc.temp -1
execute if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc".current_uses store result score #uses dc.temp run data get storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc".current_uses
execute if score #uses dc.temp matches ..-1 if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc".max_uses store result score #uses dc.temp run data get storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc".max_uses
scoreboard players remove #uses dc.temp 1

execute if score #uses dc.temp matches 1.. run scoreboard players operation #damage dc.temp = #maxbar dc.temp
execute if score #uses dc.temp matches 1.. run scoreboard players operation #damage dc.temp -= #uses dc.temp
execute if score #uses dc.temp matches ..0 run scoreboard players operation #damage dc.temp = #maxbar dc.temp
execute if score #uses dc.temp matches ..0 run scoreboard players set #uses dc.temp 0

function doom.library:api/open
data modify storage doom.library:ctx _.cache_key set value "consumable"
data modify storage doom.library:ctx _.cache_data set value {}
data modify storage doom.library:ctx _.cache_data.item set from storage doom.consumable:ctx task_data.item
execute store result storage doom.library:ctx _.cache_data.args.uses int 1 run scoreboard players get #uses dc.temp
execute store result storage doom.library:ctx _.cache_data.args.damage int 1 run scoreboard players get #damage dc.temp
data modify storage doom.library:ctx _.cache_data.slot_path set from storage doom.consumable:ctx task_data.slot_path
# 2026-09-27：恢复落点（可为 hotbar.N）与物品 id 一起进缓存 —— 恢复链靠它们做"占用就不覆盖"的判定
execute if data storage doom.consumable:ctx task_data.slot_cmd run data modify storage doom.library:ctx _.cache_data.slot_cmd set from storage doom.consumable:ctx task_data.slot_cmd
execute if data storage doom.consumable:ctx task_data.id run data modify storage doom.library:ctx _.cache_data.id set from storage doom.consumable:ctx task_data.id
# Depleted modes: remainder, vanish, disable
#
# ⚠ 2026-09-20 定案的真机 bug —— 这是**顺序**问题，不是判定问题：
#   清空手持（item replace … with air）会触发 inventory_changed 成就 → core/save_inv，
#   而 save_inv 结尾会 `data remove` 掉 doom.library:ctx 的 _.cache_key / _.cache_data
#   （第 17 行还会清掉 doom.consumable:ctx task_data）。
#   旧顺序把清手持排在 api/cache **之前** → 宏参数 $(cache_key) 调用时已经不存在 →
#   **api/cache 整次调用被静默放弃**：连第一行 `set value {}` 都没执行，
#   所以旧条目连 timestamp 都完好无损（真机判据：do_check_timer 的 wrote_at 停在旧游戏刻不再前进）。
#   后果：缓存停留在上一次的"未耗尽 + args.uses=1" → do_check_timer 走 do_restore 把物品按旧次数放回手上 →
#   表现就是"耗尽后物品不消失、耐久条卡在 1/5、可以无限吃"。
#   ⇒ 规矩：**所有 inventory 改动都必须排在缓存写入之后**。

# 1) disable：物品留着，但既不再触发数据包、也不该还能被原版用掉
#    · 摘 detect  → process_usage_wrapper / mark_placed 的谓词不再匹配，数据包彻底撒手
#    · 写 "!minecraft:consumable" → **显式移除** consumable 组件，右键吃不动 / 喝不动
#
#    ⚠ 为什么不能直接 `data remove …components."minecraft:consumable"`：
#      1.20.5 起物品组件是**对物品原型的补丁**。苹果的 consumable 来自原型，
#      patch 里**本来就没有这个键** —— 删一条不存在的路径什么也不做，原版行为照旧。
#      1.21.5+ 用 `"!<组件id>":{}` 这种写法表示"显式移除"（也就是 item 参数 `[!组件]` 的 NBT 形态）。
#      2026-09-20 探针实测（test/probe_component）：
#        [A] 显式写入后 data remove → components = {}          → 照样能吃 ✗
#        [B] 写 "!minecraft:consumable":{} → 打印同一形态      → 吃不动 ✓
#        [C] item 参数 [!minecraft:consumable] → 与 B 完全一致  → 语法确实存在 ✓
#
#    · place 类（荧石）另一套：**放置受玩家属性 `block_interaction_range` 控制，物品侧没有开关**，
#      唯一杠杆是给物品挂 `attribute_modifiers` 把这条属性压低 —— 但必须先把 max_damage/damage 删掉。
#
#      ⚠ 2026-09-20 实测（test/probe_reach / probe_reach_full / probe_reach_nodamage）：
#        · 0 耐久（damage == max_damage，原版"已破损"）**挡不住放置** —— 别指望破损状态
#        · 破损物品的 attribute_modifiers **不生效**：读数显示修饰符确实在物品上，
#          但 block_interaction_range 仍是 4500（同 tick 读、拿很久再读都一样）
#        · 去掉 max_damage/damage 之后修饰符立刻生效：属性被压低 → **放不下去** ✓
#        · 代价（已由玩家确认）：reach 是全局属性，**拿着它连箱子都打不开** ——
#          语义从"数据包撒手"变成"这玩意儿拿在手里就是块废铁"。
#      max_damage/damage 是**我们自己写进补丁的**（不是荧石的原型默认组件），所以
#      `data remove` 就能真正移除 —— 不像苹果的 consumable 需要 `!` 前缀。
#      副作用：耐久条随之消失（破损态与修饰符二者不可兼得，这是引擎的硬约束）。
#
#    · 三类物品的 disable 语义因此并不对称，但都是"在引擎允许范围内做到最死"：
#        consume → 摘 detect + 让 consumable 彻底不存在（吃不动，拿着无害）
#        place   → 摘 detect + 删耐久 + 压低 reach（放不下去，代价是交互全禁）
#        其它    → 摘 detect（数据包撒手）
#
#    ⚠ 2026-09-20 补洞（由 disable 海洋之心这个用例暴露）：
#      consumable 可能来自**两个地方**，必须分别处理，否则补丁里会同时存在
#      `"consumable":{…}` 与 `"!minecraft:consumable":{}` 两个互相冲突的键：
#        · 来自物品原型（苹果）→ 补丁里没有这个键 → 只能写 `!` 形式显式移除
#        · 来自我们自己的补丁（海洋之心 —— 原版没这个组件）→ 必须 data remove 掉
#      所以顺序是：**先删补丁里那份（有才删），再写 `!` 标记**，两种情况都能善终。
execute if score #uses dc.temp matches ..0 if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{depleted:"disable"} run data remove storage doom.library:ctx _.cache_data.item.components."minecraft:custom_data"."dc".detect
execute if score #uses dc.temp matches ..0 if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{depleted:"disable",detect:"consume"} if data storage doom.library:ctx _.cache_data.item.components."minecraft:consumable" run data remove storage doom.library:ctx _.cache_data.item.components."minecraft:consumable"
execute if score #uses dc.temp matches ..0 if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{depleted:"disable",detect:"consume"} run data modify storage doom.library:ctx _.cache_data.item.components."!minecraft:consumable" set value {}
# place 类：先删耐久（脱离"破损"态，否则下一行不生效），再挂 reach 归零修饰符
# ⚠ data remove 必须用 if data 守住 —— 删不存在的路径会失败/中止，把后面的顺序全带走
execute if score #uses dc.temp matches ..0 if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{depleted:"disable",detect:"place"} if data storage doom.library:ctx _.cache_data.item.components."minecraft:max_damage" run data remove storage doom.library:ctx _.cache_data.item.components."minecraft:max_damage"
execute if score #uses dc.temp matches ..0 if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{depleted:"disable",detect:"place"} if data storage doom.library:ctx _.cache_data.item.components."minecraft:damage" run data remove storage doom.library:ctx _.cache_data.item.components."minecraft:damage"
execute if score #uses dc.temp matches ..0 if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{depleted:"disable",detect:"place"} run data modify storage doom.library:ctx _.cache_data.item.components."minecraft:attribute_modifiers" set value [{type:"minecraft:block_interaction_range",id:"dc:disabled",amount:-10.0,operation:"add_value",slot:"mainhand"}]

# 2) 标记耗尽（vanish / disable 都不写）
execute if score #uses dc.temp matches ..0 unless data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{depleted:"disable"} unless data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{depleted:"vanish"} run data modify storage doom.library:ctx _.cache_data.depleted set value 1b

# 3) remainder：用 if data 守住 —— 源路径缺失时这行会失败，后面的缓存写入会跟着一起消失
execute if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc".remainder run data modify storage doom.library:ctx _.cache_data.remainder set from storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc".remainder

# 4) 写缓存。vanish 只在耗尽时跳过（正常使用中的 vanish 类物品照样要缓存）
scoreboard players set #no_write dc.temp 0
execute if score #uses dc.temp matches ..0 if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{depleted:"vanish"} run scoreboard players set #no_write dc.temp 1
execute if score #no_write dc.temp matches 1 run scoreboard players set @s dc.restore_timer -1
# 再设一次 cache_key 只是保险：万一将来又有别的嵌套奖励动了 ctx，这里也不会静默丢参数
execute if score #no_write dc.temp matches 0 run data modify storage doom.library:ctx _.cache_key set value "consumable"
execute if score #no_write dc.temp matches 0 run function doom.library:api/cache with storage doom.library:ctx _
data remove storage doom.library:ctx _.cache_key
data remove storage doom.library:ctx _.cache_data

# 5) 清空手持 —— 必须排在缓存写入之后（disable 保留物品）
# ⚠ 2026-09-27：清的是**当初那个槽**，而且只在那槽里还是**同一件**物品时才清 ——
#   旧版按 slot_path 清"当前手"，玩家换过槽就会把新槽里的东西直接删掉（同「吞物品」族）。
#   具体判定与写入挪到 schedule/clear_slot（**带参调用**的宏），
#   本文件因此保持"不含 $ 行"= 老调用方（套件、手工调用）不需要补参数就能继续工作。
#   ⚠ 缺 slot_cmd / id 时**不调用**：宏函数缺参会整次失败，宁可这次不清也不能炸掉后面。
execute if score #uses dc.temp matches ..0 unless data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{depleted:"disable"} if data storage doom.consumable:ctx task_data.slot_cmd if data storage doom.consumable:ctx task_data.id run function doom.consumable:schedule/clear_slot with storage doom.consumable:ctx task_data

# 6) vanish：清完手持直接结束（不写缓存、不恢复）
execute if score #no_write dc.temp matches 1 run return 0

scoreboard players set @s dc.restore_timer 1
