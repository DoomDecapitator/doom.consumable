# 探针（单独一个文件）：1.21.5+ 的 **item 参数** `[!组件]` 写法是否存在
# 用法：/function doom.consumable:test/probe_itemarg
#
# 为什么单独成文件：这是**解析期**风险。若 `!组件` 语法在这个版本不存在，
#   本文件会整个加载失败（latest.log 里能看到 Failed to load function）。
#   项目惯例：高风险命令单独成文件，失败时只损失它自己，不连累别的探针。
#
# 这个变体的价值：如果它可用，就说明游戏**自己**认可的"显式移除"语法存在，
#   那么 [B] 打印出来的 components 就是标准形态，可以直接抄进 schedule/limited 的 disable 分支。
item replace entity @s weapon.mainhand with minecraft:apple[!minecraft:consumable]
tellraw @s [{"text":"[C] item 参数 [!minecraft:consumable] → components = ","color":"gold"},{"nbt":"SelectedItem.components","entity":"@s","interpret":false}]
tellraw @s [{"text":"（能加载出来就说明语法存在；再右键试一下能不能吃）","color":"yellow"}]
