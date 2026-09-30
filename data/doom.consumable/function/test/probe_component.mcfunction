# 探针：把 minecraft:apple 的 consumable 组件"弄没"，NBT 层到底该怎么写
# 用法：/function doom.consumable:test/probe_component
#
# 背景（这是本次要验证的核心）：
#   1.20.5 起物品组件是**对物品原型的补丁（patch）**。苹果的 consumable 来自原型，
#   所以 patch 里**本来就没有这个 key** ——
#     · `data remove` 一条不存在的路径 = 命令失败/什么都不做，默认值照样生效
#     · 想真的移除，必须写入"显式移除"的标记
#   1.21.5 给这个标记定了 NBT 形态（下面变体 B 用的 `!` 前缀）。
#
# 两个变体都是纯 NBT 操作，没有解析风险；风险更高的 item 参数写法在 probe_itemarg 里单独一个文件。
tellraw @s [{"text":"===== [P] consumable 探针 =====","color":"gold"}]

# ---------- 变体 A：先显式写入 consumable，再 data remove 掉 ----------
# 期望：如果"删 key"真的等于"移除组件"，那么 A 就应该和 B 等效。
#       如果 A 打印出的 components 里没有 consumable、但苹果照样能吃 —— 说明默认值回来了。
summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:apple",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item.components."minecraft:consumable" set value {}
data remove entity @e[type=item_display,tag=dc_probe,limit=1] item.components."minecraft:consumable"
item replace entity @s weapon.mainhand from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe,limit=1]
tellraw @s [{"text":"[A] 显式写入后 data remove → components = ","color":"gold"},{"nbt":"SelectedItem.components","entity":"@s","interpret":false}]

# ---------- 变体 B：用 1.21.5 的 `!` 前缀写成"显式移除" ----------
summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:apple",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item.components."!minecraft:consumable" set value {}
item replace entity @s weapon.mainhand from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe,limit=1]
tellraw @s [{"text":"[B] ! 前缀写法 → components = ","color":"gold"},{"nbt":"SelectedItem.components","entity":"@s","interpret":false}]

tellraw @s [{"text":"现在拿在手上右键：","color":"yellow"},{"text":"吃不动 = 成功；还能吃 = 原型默认值回来了，这个写法不够","color":"yellow"}]
