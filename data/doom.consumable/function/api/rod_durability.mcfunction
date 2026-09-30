# doom.consumable:api/rod_durability [MACRO] —— 设置手持鱼竿的耐久（damage 组件）
#
# 调用（**必须带参数**；缺参数时整个函数体会被静默放弃）：
#     function doom.consumable:api/rod_durability {value:0}     ← 0 = 满耐久（"清空耐久损耗"）
#     function doom.consumable:api/rod_durability {value:10}    ← 已损耗 10 点
# 作用对象：**执行者手上**那把带 dc{rod:1b} 的鱼竿（主手优先，其次副手）。
# 说明：耐久条 = damage / max_damage。设成 max_damage 就是"空条"（鱼竿不会坏、仍可使用）。
# 执行者必须是玩家本人（写回靠 item replace entity @s …）。
function doom.consumable:rod/pick
execute unless data storage doom.consumable:ctx rod.item run return 0
$data modify storage doom.consumable:ctx rod.item.components."minecraft:damage" set value $(value)
function doom.consumable:rod/writeback with storage doom.consumable:ctx rod
