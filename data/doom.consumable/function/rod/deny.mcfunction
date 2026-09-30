# doom.consumable:rod/deny —— 否决一次抛竿：收回鱼漂 + 反馈 + 回调
#
# 只收「本刻新抛出来」的鱼漂（还没被 rod/tick 末尾打上 dc_rod_seen）——
#   别的玩家正在钓的鱼漂不会被误伤；同一 tick 多人同时被否决时也照收（这是刻意的）。
kill @e[type=minecraft:fishing_bobber,tag=!dc_rod_seen]

# 这一次抛竿不算数：状态回退（否则下一次右键会被误判成收杆）
scoreboard players set @s dc.rod_state 0

# 硬禁用：顺手挂长冷却 ⇒ 之后连"抛"都抛不出去（原版拦截 + 热键栏灰条反馈）
function doom.consumable:rod/lock

# 外部回调（第三方可在这里做提示 / 扣钱 / 记日志）
function #doom.consumable:on_rod_denied

# ---- 物品自带的反馈（可选）：dc.rod_deny_message / dc.rod_deny_sound ----
# ⚠ 用 storage 转交给宏，而不是 `with entity @s …components."minecraft:custom_data"."dc"`：
#   带引号的路径游戏能解析，但**静态检查（lint M4）认不出 `with` 子句** ⇒ 会误判成"缺参数"。
#   本项目一律用 storage 传宏参数（也更好读）。副手有声明时会覆盖主手的。
data remove storage doom.consumable:ctx rod_fb
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc".rod_deny_message run data modify storage doom.consumable:ctx rod_fb.msg set from entity @s SelectedItem.components."minecraft:custom_data"."dc".rod_deny_message
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc".rod_deny_sound run data modify storage doom.consumable:ctx rod_fb.sound set from entity @s SelectedItem.components."minecraft:custom_data"."dc".rod_deny_sound
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc".rod_deny_message run data modify storage doom.consumable:ctx rod_fb.msg set from entity @s equipment.offhand.components."minecraft:custom_data"."dc".rod_deny_message
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc".rod_deny_sound run data modify storage doom.consumable:ctx rod_fb.sound set from entity @s equipment.offhand.components."minecraft:custom_data"."dc".rod_deny_sound
execute if data storage doom.consumable:ctx rod_fb.msg run function doom.consumable:rod/deny_msg with storage doom.consumable:ctx rod_fb
execute if data storage doom.consumable:ctx rod_fb.sound run function doom.consumable:rod/deny_sound with storage doom.consumable:ctx rod_fb
data remove storage doom.consumable:ctx rod_fb
