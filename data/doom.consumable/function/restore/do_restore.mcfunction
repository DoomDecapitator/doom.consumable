# doom.consumable:restore/do_restore —— 把中转体上那件塞回玩家（**写入前判占用**）
#
# 调用：execute at @s run function doom.consumable:restore/do_restore
# 前置：调用方（restore/do_check_timer）已把 CACHE.consumable 读进 output[-1]，且未被判为 depleted。
#
# ⚠⚠ 2026-09-27 加固：玩家报障「频繁切换物品使用会吞物品」。
#   病根：旧版无条件 `item replace entity @s weapon.mainhand/offhand …`。
#   `weapon.mainhand` 指的是**当前选中那一格**，不是"当初用的那一格"；而消耗与恢复之间隔着
#   1~2 tick（mark_consumed → consume_timer → schedule → restore_timer）。玩家在这期间
#   换一下槽（滚轮/数字键）或捡到别的东西，恢复就写进**新槽**，把新槽里原本的东西直接抹掉。
#   现在三重落点：
#     ① 目标槽位空            → 写回（正常：max_stack_size=1 的物品用完槽位是空的）
#     ② 目标槽位还是同一件    → 写回（正常：一叠没用完，原版扣了 1，这里补回去）
#     ③ 被别的东西占了        → **绝不覆盖**：restore/put_anywhere 找第一个空槽，没有就掉在脚下
#   目标槽位由 core/finalize_slot 定：主手精确到 `hotbar.N`（取消耗那一刻的 SelectedItemSlot），
#   副手固定 `weapon.offhand`；拿不到读数时退化成 slot_path（旧行为），由 ③ 兜底。
scoreboard players set @s dc.restore_timer -1

# 中转体：用**本流程专用** tag，并且先无条件清一遍残留，再建中转体。
#   原来用共用 tag `dc_tmp` 且不预清理，隐患有两个：
#     ① 上一次恢复若没走到最后的 kill（任何一行中途失败都会这样），残留的中转体会一直躺在地上；
#        下一次恢复的 `limit=1` 是"最近的那个"，可能选中它 ⇒ 于是"恢复"写出的是**别人身上的物品**
#        （item_display 的默认物品是石头，最坏情况是把手上的东西换成石头）。
#     ② recover/step 也在用同一个 `dc_tmp` —— 两个流程同 tick 撞上时同样会互抢。
#   recover/step 早就改成"先 kill 再 summon"了，这里照同一规则办。
#   2026-09-27：丢弃链（restore/do_discard_restore）也改用同一个 tag —— 两条链都是"先 kill 再建、
#   用完立刻 kill"，且在 tick 里顺序执行，不会互相踩；继续各用一套 tag 反而要多维护一份槽位分派。
kill @e[type=item_display,tag=dc_restore_tmp]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_item","dc_restore_tmp"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_restore_tmp,limit=1] item set from storage doom.library:io output[-1].data.CACHE.consumable.data.item
data modify entity @e[type=item_display,tag=dc_restore_tmp,limit=1] item.components."minecraft:custom_data"."dc".current_uses set from storage doom.library:io output[-1].data.CACHE.consumable.data.args.uses
# FIXED (L): 仅当物品带 max_damage 才写 damage 组件。
#   这一层守卫保护的是 infinite / discard 这类**本来就没有耐久条**的物品：
#   它们的缓存里没有 args.damage，无条件 `set from` 会静默失败/中止本文件。
#   带 max_damage 的物品一律写 —— 耐久条 = damage / max_damage = 已用次数（2026-09-20）。
execute if data storage doom.library:io output[-1].data.CACHE.consumable.data.item.components."minecraft:max_damage" run data modify entity @e[type=item_display,tag=dc_restore_tmp,limit=1] item.components."minecraft:damage" set from storage doom.library:io output[-1].data.CACHE.consumable.data.args.damage
# ⚠ 2026-09-26「幽灵」病根 + 修法：**槽位同步包没发**。
#   AbstractContainerMenu 的同步是"对比式"的 —— 只有槽位内容与它记录的远端副本不同才发包。
#   本流程里"原版消耗"与"我们恢复"发生在**同一 tick**，恢复出来的又与原物品**逐字节相同**，
#   于是服务端在 tick 末对比时认为"什么都没变" ⇒ 一个包都不发；
#   而客户端在放置那一下已经按自己的预测把手上的东西抹掉了 ⇒ **手里看不见，但功能完全正常**。
#   修法：塞回去之前盖一个每刻唯一的戳（restore/mark_sync），物品每次都"不一样" ⇒ 强制发包。
#   真机 A/B：关＝看不见、放得下；开＝全程看得见（唯一变量就是这个戳）。
#   开关 #resync dc.cfg（默认 1 = 开）；0 只用来复现。
execute as @e[type=item_display,tag=dc_restore_tmp,limit=1] run function doom.consumable:restore/mark_sync

# 落点判定 → ①/② 写回原槽；③ 换地方（绝不覆盖）
function doom.consumable:restore/guard with storage doom.library:io output[-1].data.CACHE.consumable.data
execute if score #can dc.temp matches 1 run function doom.consumable:restore/write_at with storage doom.library:io output[-1].data.CACHE.consumable.data
execute if score #can dc.temp matches 0 run function doom.consumable:restore/put_anywhere

# 无论走哪条路，中转体都只活到这一行为止
kill @e[type=item_display,tag=dc_restore_tmp,limit=1]
