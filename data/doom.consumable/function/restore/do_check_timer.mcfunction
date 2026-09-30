# doom.consumable:restore/do_check_timer
scoreboard players set @s dc.restore_timer -1
execute as @s run function doom.library:api/open
# B13 修复（2026-09-30 真机实锤）：旧尾行只删 output 读副本，players.data 的 CACHE.consumable 永久残留
#   （P-4 的 glowstone 快照十几分钟后仍可读出；潜伏错恢复风险）。api/open 已把数据落到 output[-1]，
#   本函数后续行全读 output 副本 ⇒ 在这里真删源数据不影响任何判定。宏参数与调用同函数内连续行（宏纪律）。
data modify storage doom.library:ctx _.cache_key set value "consumable"
function doom.library:api/cache_clear with storage doom.library:ctx _
data remove storage doom.library:ctx _.cache_key
# F5 修复：do_depleted 只做一件事 —— give @s $(remainder) 1。
#   若物品既没有 remainder 也没有 depleted 字段，耗尽时 depleted 会被置位，
#   而 $(remainder) 缺失会让**整个宏调用被静默放弃**：物品已经消失、既不返还也不报错。
#   现在把两种情况显式分开，缺 remainder 时给一条提示。
execute if data storage doom.library:io output[-1].data.CACHE.consumable.data.depleted if data storage doom.library:io output[-1].data.CACHE.consumable.data.remainder run function doom.consumable:restore/do_depleted with storage doom.library:io output[-1].data.CACHE.consumable.data
# 可见提示单独走一个宏文件：即使它失败也不影响上面的 give（见 notify_depleted 注释）
execute if data storage doom.library:io output[-1].data.CACHE.consumable.data.depleted if data storage doom.library:io output[-1].data.CACHE.consumable.data.remainder run function doom.consumable:restore/notify_depleted with storage doom.library:io output[-1].data.CACHE.consumable.data
execute if data storage doom.library:io output[-1].data.CACHE.consumable.data.depleted unless data storage doom.library:io output[-1].data.CACHE.consumable.data.remainder run tellraw @s [{"text":"[dc] 物品已耗尽：既没有 depleted 模式也没有 remainder —— 不会返还任何东西","color":"yellow"}]
# 兼容层：只带 slot_path 的旧缓存 / 手工构造的缓存 —— 把 slot_cmd 与 id 补齐，
#   否则 restore/guard 的宏参数缺失会让判定降级成"不可写"，物品会被塞到别处（不会丢，但不是原槽）。
execute unless data storage doom.library:io output[-1].data.CACHE.consumable.data.slot_cmd if data storage doom.library:io output[-1].data.CACHE.consumable.data.slot_path run data modify storage doom.library:io output[-1].data.CACHE.consumable.data.slot_cmd set from storage doom.library:io output[-1].data.CACHE.consumable.data.slot_path
execute unless data storage doom.library:io output[-1].data.CACHE.consumable.data.id if data storage doom.library:io output[-1].data.CACHE.consumable.data.item.id run data modify storage doom.library:io output[-1].data.CACHE.consumable.data.id set from storage doom.library:io output[-1].data.CACHE.consumable.data.item.id
execute unless data storage doom.library:io output[-1].data.CACHE.consumable.data.depleted run function doom.consumable:restore/do_restore with storage doom.library:io output[-1].data.CACHE.consumable.data
data remove storage doom.library:io output[-1].data.CACHE.consumable
