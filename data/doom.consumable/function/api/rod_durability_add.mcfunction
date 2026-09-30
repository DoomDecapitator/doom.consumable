# doom.consumable:api/rod_durability_add [MACRO] —— 给手持鱼竿的耐久损耗加/减一个量
#
# 调用（**必须带参数**）：
#     function doom.consumable:api/rod_durability_add {value:1}    ← 多损耗 1 点
#     function doom.consumable:api/rod_durability_add {value:-3}   ← 修回 3 点（减到 0 为止）
# 作用对象：执行者手上那把带 dc{rod:1b} 的鱼竿（主手优先，其次副手）。
# 用例：自定义"每次抛竿磨损 1 点""钓到鱼回 1 点"这类规则（写在 #doom.consumable:on_rod_cast /
#   on_rod_catch 回调里调用本函数即可，不必改包）。
# ⚠ `data get` 读不到字段时会**保留旧值**（本项目已钉的坑）⇒ 先把分数清 0 再读。

function doom.consumable:rod/pick
execute unless data storage doom.consumable:ctx rod.item run return 0

scoreboard players set #rod_cur dc.temp 0
execute store result score #rod_cur dc.temp run data get storage doom.consumable:ctx rod.item.components."minecraft:damage"
# B11 修复（2026-09-30 真机实锤）：players add 拒绝负数（Brigadier "Integer must not be less than 0"）
#   ⇒ 负修整（README 文档化的 {value:-3} 用法）静默失效。改 set+operation（set 接受负数）。
$scoreboard players set #v dc.temp $(value)
scoreboard players operation #rod_cur dc.temp += #v dc.temp
scoreboard players reset #v dc.temp
execute if score #rod_cur dc.temp matches ..-1 run scoreboard players set #rod_cur dc.temp 0
execute store result storage doom.consumable:ctx rod.item.components."minecraft:damage" int 1 run scoreboard players get #rod_cur dc.temp
function doom.consumable:rod/writeback with storage doom.consumable:ctx rod
