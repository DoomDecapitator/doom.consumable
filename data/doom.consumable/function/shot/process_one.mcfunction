# doom.consumable:shot/process_one —— 一次射击的扣次处理
# 前置：diff_* 判定 stat 上涨；ctx.shot.main（1b=主手 / 0b=副手）由 tick_one 写入。
# 纪律：ctx.shot 键全部在本函数内连续行读写（宏参数源安全；跨 RCON 调用会撞 refresh_hand_cache 竞态）。

# ① 复制当前手持 + 复核还是 dc{detect:"shot"} 物品（防同刻换手错写别的物品）
execute if data storage doom.consumable:ctx shot.main run data modify storage doom.consumable:ctx shot.item set from entity @s SelectedItem
execute unless data storage doom.consumable:ctx shot.main run data modify storage doom.consumable:ctx shot.item set from entity @s equipment.offhand
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

# ⑨ 回调（无论扣没扣次都发 —— 事件语义；与 on_rod_cast 家族同款挂载点）
function #doom.consumable:on_shot

# ⑩ 清理
data remove storage doom.consumable:ctx shot
