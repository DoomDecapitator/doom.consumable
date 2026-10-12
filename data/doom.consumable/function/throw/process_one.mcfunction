# doom.consumable:throw/process_one —— 一次投掷的扣次处理
#
# ★ 与 shot/process_one **同构**（刻意的：作者只学一套心智模型）。差异只有两点：
#   ① 本链没有 arrow_refund（投掷物没有"箭"这种可补回的中介；要无限就写 type:"infinite"）
#   ② 不接连发弹匣（dc.mag 是弩专有 —— 投掷物没有 charged_projectiles 语义）
#
# 前置：diff_* 判定 stat 上涨；ctx.throw.main（1b=主手 / 0b=副手）由 tick_one 写入。
# ⚠ 主/副手判定必须用**值判定** `throw{main:1b}`，不能用存在性判定 `throw.main`
#   —— 后者恒为真（main 不是 1b 就是 0b），会把副手路径变成死代码。
#   这个坑 shot 链真实踩过（2026-10-05 由 consumable_shot 用例 K1 抓到并修复），此处直接就写对。

# ① 复制当前手持 + 复核还是 dc{detect:"throw"} 物品（防同刻换手错写别的物品）
execute if data storage doom.consumable:ctx throw{main:1b} run data modify storage doom.consumable:ctx throw.item set from entity @s SelectedItem
execute unless data storage doom.consumable:ctx throw{main:1b} run data modify storage doom.consumable:ctx throw.item set from entity @s equipment.offhand
execute unless data storage doom.consumable:ctx throw.item.components."minecraft:custom_data".dc{detect:"throw"} run data remove storage doom.consumable:ctx throw
execute unless data storage doom.consumable:ctx throw.item.components."minecraft:custom_data".dc{detect:"throw"} run return 0

# ② 记录物品 id（耗尽时清槽要用；也便于诊断）
execute if data storage doom.consumable:ctx throw.item.id run data modify storage doom.consumable:ctx throw.id set from storage doom.consumable:ctx throw.item.id

# ③ infinite 型：不扣次
scoreboard players set #is_inf dc.temp 0
execute if data storage doom.consumable:ctx throw.item.components."minecraft:custom_data".dc{type:"infinite"} run scoreboard players set #is_inf dc.temp 1

# ④ 读 uses（-1 哨兵 + if data 守卫，缺 current_uses 退 max_uses —— 同 shot 的 F4 防御）
scoreboard players set #uses dc.temp -1
execute if data storage doom.consumable:ctx throw.item.components."minecraft:custom_data".dc.current_uses store result score #uses dc.temp run data get storage doom.consumable:ctx throw.item.components."minecraft:custom_data".dc.current_uses
execute if score #uses dc.temp matches ..-1 store result score #uses dc.temp run data get storage doom.consumable:ctx throw.item.components."minecraft:custom_data".dc.max_uses

# ⑤ maxbar（max_damage 组件优先，退 max_uses）
scoreboard players set #maxbar dc.temp -1
execute if data storage doom.consumable:ctx throw.item.components."minecraft:max_damage" store result score #maxbar dc.temp run data get storage doom.consumable:ctx throw.item.components."minecraft:max_damage"
execute if score #maxbar dc.temp matches ..-1 store result score #maxbar dc.temp run data get storage doom.consumable:ctx throw.item.components."minecraft:custom_data".dc.max_uses

# ⑥ 扣次（仅 limited）
execute if score #is_inf dc.temp matches 0 run scoreboard players remove #uses dc.temp 1

# ⑦ 耗尽（uses <= 0 且非 infinite）：vanish / disable / normal 分派
execute if score #is_inf dc.temp matches 0 if score #uses dc.temp matches ..0 run function doom.consumable:throw/depleted

# ⑧ 未耗尽：写回（uses 与 dmg=maxbar-uses 写进 ctx.throw 供宏展开）
execute if score #is_inf dc.temp matches 0 if score #uses dc.temp matches 1.. store result storage doom.consumable:ctx throw.uses int 1 run scoreboard players get #uses dc.temp
execute if score #is_inf dc.temp matches 0 if score #uses dc.temp matches 1.. run scoreboard players operation #dmg dc.temp = #maxbar dc.temp
execute if score #is_inf dc.temp matches 0 if score #uses dc.temp matches 1.. run scoreboard players operation #dmg dc.temp -= #uses dc.temp
execute if score #is_inf dc.temp matches 0 if score #uses dc.temp matches 1.. store result storage doom.consumable:ctx throw.dmg int 1 run scoreboard players get #dmg dc.temp
execute if score #is_inf dc.temp matches 0 if score #uses dc.temp matches 1.. run function doom.consumable:throw/writeback with storage doom.consumable:ctx throw

# ⑨ 回调（无论扣没扣次都发 —— 事件语义；与 on_shot 家族同款挂载点）
function #doom.consumable:on_throw

# ⑩ 清理
data remove storage doom.consumable:ctx throw
