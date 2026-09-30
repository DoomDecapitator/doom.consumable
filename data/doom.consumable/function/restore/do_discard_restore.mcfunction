# doom.consumable:restore/do_discard_restore —— 把"丢出去被收回"的物品还回去
#
# 落点优先级（2026-09-27 与 do_restore 统一）：
#   ① 原槽位（空 或 还是同一件）→ ② 第一个空槽 → ③ 掉在脚下（PickupDelay 0）
#   判定与写回都复用 restore/guard / restore/write_at / restore/put_anywhere ——
#   三条链（吃/放/丢）从此走同一套"绝不覆盖"的落点规则，避免又出现"某一条链吞东西"。
#
# 为什么要统一：旧版这里只有"原槽空就写回，否则掉脚下"（对主副手各写一遍），
#   一是没有"还是同一件"的分支（一叠没用完时会把整叠覆盖掉），二是落点写死主副手，
#   三是一旦原槽被占就只能掉地上 —— 现在换成"先找空槽，实在没有才掉地上"，玩家体验更稳。
scoreboard players set @s dc.discard_timer -1

function doom.library:api/open
# B13 修复（同 do_check_timer）：真删 players.data 的 CACHE.discard；output[-1] 副本供后续行使用
data modify storage doom.library:ctx _.cache_key set value "discard"
function doom.library:api/cache_clear with storage doom.library:ctx _
data remove storage doom.library:ctx _.cache_key

execute unless data storage doom.library:io output[-1].data.CACHE.discard.data.item run data remove storage doom.library:io output[-1].data.CACHE.discard
execute unless data storage doom.library:io output[-1].data.CACHE.discard.data.item run return 0

# 兼容层：只带 slot_path 的旧缓存 / 手工构造的缓存 —— 补齐 slot_cmd 与 id（见 do_check_timer 里的同款注释）
execute unless data storage doom.library:io output[-1].data.CACHE.discard.data.slot_cmd if data storage doom.library:io output[-1].data.CACHE.discard.data.slot_path run data modify storage doom.library:io output[-1].data.CACHE.discard.data.slot_cmd set from storage doom.library:io output[-1].data.CACHE.discard.data.slot_path
execute unless data storage doom.library:io output[-1].data.CACHE.discard.data.id if data storage doom.library:io output[-1].data.CACHE.discard.data.item.id run data modify storage doom.library:io output[-1].data.CACHE.discard.data.id set from storage doom.library:io output[-1].data.CACHE.discard.data.item.id

# 中转体（先清后建；tag 与恢复链共用 dc_restore_tmp —— 两条链各自"用完即杀"，tick 内顺序执行不冲突）
kill @e[type=item_display,tag=dc_restore_tmp]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_item","dc_restore_tmp"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_restore_tmp,limit=1] item set from storage doom.library:io output[-1].data.CACHE.discard.data.item
# 「幽灵」修法（同 do_restore）：丢出去与塞回来发生在同一 tick、物品逐字节相同 ⇒
#   服务端会判定"槽位没变"而不发同步包 ⇒ 客户端停在自己预测的"已丢出"画面上（手里空的，东西其实在）。
#   塞回之前盖一个每刻唯一的戳，强制发包。开关 #resync dc.cfg（默认 1）。
execute as @e[type=item_display,tag=dc_restore_tmp,limit=1] run function doom.consumable:restore/mark_sync

function doom.consumable:restore/guard with storage doom.library:io output[-1].data.CACHE.discard.data
execute if score #can dc.temp matches 1 run function doom.consumable:restore/write_at with storage doom.library:io output[-1].data.CACHE.discard.data
execute if score #can dc.temp matches 0 run function doom.consumable:restore/put_anywhere
kill @e[type=item_display,tag=dc_restore_tmp,limit=1]

data remove storage doom.library:io output[-1].data.CACHE.discard
advancement revoke @s only doom.consumable:inv_change
