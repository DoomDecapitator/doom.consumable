# ⚠ 2026-10-05 修复（由新增的 consumable_shot 套件用例 K1 抓到）：
#   原写法 `if data storage doom.consumable:ctx shot.main` 是**存在性**测试，
#   而 shot.main 恒为 **1b 或 0b 二者之一** ⇒ 该条件**永远为真** ⇒
#   「副手」那一支（unless …）**永远不执行**。
#   后果：主手不是 shot 武器、只有副手是时，process_one 会去读**主手**（读到石头 ⇒
#   dc 复核不过 ⇒ 整次扣次被丢弃），writeback / depleted 也会往**主手**写。
#   ⇒ 副手射击链在真机上**完全不工作**（静默无效果，不报错）。
#   ⇒ 改为**值判定** `shot{main:1b}`（1b=主手走 if，0b=副手走 unless）。
# doom.consumable:shot/process_one —— 一次射击的扣次处理
# 前置：diff_* 判定 stat 上涨；ctx.shot.main（1b=主手 / 0b=副手）由 tick_one 写入。
# 纪律：ctx.shot 键全部在本函数内连续行读写（宏参数源安全；跨 RCON 调用会撞 refresh_hand_cache 竞态）。

# ① 复制当前手持 + 复核还是 dc{detect:"shot"} 物品（防同刻换手错写别的物品）
execute if data storage doom.consumable:ctx shot{main:1b} run data modify storage doom.consumable:ctx shot.item set from entity @s SelectedItem
execute unless data storage doom.consumable:ctx shot{main:1b} run data modify storage doom.consumable:ctx shot.item set from entity @s equipment.offhand
execute unless data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc{detect:"shot"} run data remove storage doom.consumable:ctx shot
execute unless data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc{detect:"shot"} run return 0

# ② 箭补回（infinite/limited 都可配；原版消耗、包补回 = infinity 复刻）
execute if data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc.arrow_refund run data modify storage doom.consumable:ctx shot.refund.id set from storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc.arrow_refund
execute if data storage doom.consumable:ctx shot.refund.id run function doom.consumable:shot/refund_give with storage doom.consumable:ctx shot.refund

# ③ infinite 型：只补箭不扣次
scoreboard players set #is_inf dc.temp 0
execute if data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc{type:"infinite"} run scoreboard players set #is_inf dc.temp 1

# ④ 读 uses（-1 哨兵 + if data 守卫，缺 current_uses 退 max_uses；schedule/limited 的 F4 修正同款）
scoreboard players set #uses dc.temp -1
execute if data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc.current_uses store result score #uses dc.temp run data get storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc.current_uses
execute if score #uses dc.temp matches ..-1 store result score #uses dc.temp run data get storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc.max_uses

# ⑤ maxbar（max_damage 组件优先，退 max_uses）
scoreboard players set #maxbar dc.temp -1
execute if data storage doom.consumable:ctx shot.item.components."minecraft:max_damage" store result score #maxbar dc.temp run data get storage doom.consumable:ctx shot.item.components."minecraft:max_damage"
execute if score #maxbar dc.temp matches ..-1 store result score #maxbar dc.temp run data get storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc.max_uses

# ⑥ 扣次（仅 limited）
execute if score #is_inf dc.temp matches 0 run scoreboard players remove #uses dc.temp 1

# ⑦ 耗尽（uses <= 0 且非 infinite）：vanish（默认）/ disable / normal 分派
execute if score #is_inf dc.temp matches 0 if score #uses dc.temp matches ..0 run function doom.consumable:shot/depleted

# ⑧ 未耗尽：写回（uses 与 dmg=maxbar-uses 先写进 ctx.shot 供宏展开）
execute if score #is_inf dc.temp matches 0 if score #uses dc.temp matches 1.. store result storage doom.consumable:ctx shot.uses int 1 run scoreboard players get #uses dc.temp
execute if score #is_inf dc.temp matches 0 if score #uses dc.temp matches 1.. run scoreboard players operation #dmg dc.temp = #maxbar dc.temp
execute if score #is_inf dc.temp matches 0 if score #uses dc.temp matches 1.. run scoreboard players operation #dmg dc.temp -= #uses dc.temp
execute if score #is_inf dc.temp matches 0 if score #uses dc.temp matches 1.. store result storage doom.consumable:ctx shot.dmg int 1 run scoreboard players get #dmg dc.temp
execute if score #is_inf dc.temp matches 0 if score #uses dc.temp matches 1.. run function doom.consumable:shot/writeback with storage doom.consumable:ctx shot

# ⑨ 连发弹匣（dc.mag，P0-2）：给弩重新上膛 ⇒ 半自动连发
#
# 与 ② 箭补回的分工：② 补的是**背包里的弹药**（原版扣 1 支、这里还 1 支）；
#   本段补的是**弩身上那把"已上膛"**（原版射完会把 charged_projectiles 清空）。
#   两者都要有才叫"无限连发"：只有 ② ⇒ 射一发就得上一次膛；只有本段 ⇒ 膛里永远有箭但背包越射越空。
#
# 位置上必须排在**耗尽分支之后 ≠ 命中**的考虑：耗尽（⑦）已经把物品 vanish/disable/normal 处理掉了，
#   再对它 item modify 会把刚摘掉的 dc 又"改活"，也会给已空的手重新塞东西。
#   ⇒ 用 `unless 未耗尽` 的守卫（#uses 已 ≤ 0 且非 infinite 时不执行）。
#   注意 infinite 型 #is_inf=1 ⇒ #uses 没被扣过、可能停在正数，此时不该拦（infinite 弩就是要连发）。
scoreboard players set #no_mag dc.temp 0
execute if score #is_inf dc.temp matches 0 if score #uses dc.temp matches ..0 run scoreboard players set #no_mag dc.temp 1
execute if score #no_mag dc.temp matches 0 if data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc.mag run function doom.consumable:shot/recharge

# ⑩ 回调（无论扣没扣次都发 —— 事件语义；与 on_rod_cast 家族同款挂载点）
function #doom.consumable:on_shot

# ⑪ 清理
data remove storage doom.consumable:ctx shot
