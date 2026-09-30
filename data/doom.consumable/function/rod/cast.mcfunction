# doom.consumable:rod/cast —— 一次「抛竿」事件（rod/tick_one 判定：状态 0 + 统计上涨）
#
# 闸门：默认放行；任一禁用条件成立 ⇒ rod/deny（同 tick 收回鱼漂，等效"没抛出去"）
scoreboard players set #rod_deny dc.temp 0
function doom.consumable:rod/gate
execute if score #rod_deny dc.temp matches 1 run function doom.consumable:rod/deny
execute if score #rod_deny dc.temp matches 0 run function doom.consumable:rod/cast_ok
