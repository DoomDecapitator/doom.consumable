# doom.consumable:test/report_place —— 放置节奏报告（幽灵取证用）
#
# 用法：按住右键放一阵 → /function doom.consumable:test/report_place
# 判读：
#   · 空档 = 0，平均间隔 4~8 tick  ⇒ 放置链健康，点击全部落地；"看不见"只能是显示层
#   · 空档 > 0（合计几十 tick 以上）⇒ 那些时段"按了没反应"，且服务端当时是干净的（点击被吞/
#     落在不能替换的方块上），这就是幽灵的实体
tellraw @s [{"text":"===== [PLC] 放置节奏报告 =====","color":"gold"}]

# 平均值：轮内平均间隔 = sumgap / (n - bursts)
scoreboard players set #den dc.diag 0
scoreboard players set #avg dc.diag 0
scoreboard players operation #den dc.diag = #n dc.diag
scoreboard players operation #den dc.diag -= #bursts dc.diag
execute if score #den dc.diag matches 1.. run scoreboard players operation #avg dc.diag = #sumgap dc.diag
execute if score #den dc.diag matches 1.. run scoreboard players operation #avg dc.diag /= #den dc.diag

tellraw @s [{"text":"放置次数 n = ","color":"gray"},{"score":{"name":"#n","objective":"dc.diag"},"color":"white"},{"text":"   连续轮数 = ","color":"gray"},{"score":{"name":"#bursts","objective":"dc.diag"},"color":"white"},{"text":"   （一轮 = 间隔 < 10 秒的连续放置）","color":"yellow"}]
tellraw @s [{"text":"轮内平均间隔 = ","color":"gray"},{"score":{"name":"#avg","objective":"dc.diag"},"color":"white"},{"text":" tick   轮内最大间隔 = ","color":"gray"},{"score":{"name":"#maxgap","objective":"dc.diag"},"color":"white"},{"text":"   （原版按住右键 ≈ 每 4~5 tick 一次）","color":"yellow"}]
tellraw @s [{"text":"空档(16~199 tick) 次数 = ","color":"gray"},{"score":{"name":"#slow","objective":"dc.diag"},"color":"white"},{"text":"   合计空档 = ","color":"gray"},{"score":{"name":"#sumslow","objective":"dc.diag"},"color":"white"},{"text":" tick","color":"yellow"}]

tellraw @s [{"text":"手持 = ","color":"gray"},{"nbt":"SelectedItem.id","entity":"@s","color":"white"},{"text":" ×","color":"gray"},{"nbt":"SelectedItem.count","entity":"@s","color":"white"}]
tellraw @s [{"text":"  dc = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:custom_data\".\"dc\"","entity":"@s","color":"white"}]
tellraw @s [{"text":"  use_cooldown = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:use_cooldown\"","entity":"@s","color":"white"},{"text":"   ← 非空 = 原版冷却在管节奏（客户端会直接吞掉冷却中的右键，服务端零痕迹）","color":"yellow"}]
tellraw @s [{"text":"  attribute_modifiers = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:attribute_modifiers\"","entity":"@s","color":"white"},{"text":"   ← 非空 = 触达被压低（disable 态的代价）","color":"yellow"}]
tellraw @s [{"text":"原版 used:glowstone = ","color":"gray"},{"score":{"name":"@s","objective":"dc.u.glowstone"},"color":"white"},{"text":"   （与「数据包识别」对照：客户端若以为手是空的，这个数就不会再涨）","color":"yellow"}]
tellraw @s [{"text":"成就触发 = ","color":"gray"},{"score":{"name":"@s","objective":"dc.trigger"},"color":"white"},{"text":"   入口识别 = ","color":"gray"},{"score":{"name":"@s","objective":"dc.placed"},"color":"white"},{"text":"   恢复到主手/副手 = ","color":"gray"},{"score":{"name":"@s","objective":"dc.placed_main"},"color":"white"},{"text":"/","color":"gray"},{"score":{"name":"@s","objective":"dc.placed_off"},"color":"white"}]

tellraw @s [{"text":"客户端重同步 #resync = ","color":"gray"},{"score":{"name":"#resync","objective":"dc.cfg"},"color":"white"},{"text":"   （1 = 开；用 test/resync_on / test/resync_off 对比，判断幽灵是不是「槽位包没发」）","color":"yellow"}]

execute if score #n dc.diag matches 0 run tellraw @s [{"text":"⇒ 加载后还没有任何放置记录：先按住右键放几下，再跑本命令。","color":"red"}]
execute if score #n dc.diag matches 1.. if score #slow dc.diag matches 0 run tellraw @s [{"text":"⇒ 全程无空档：点击都落地了，放置链健康 —— 那种「看不见」属于显示层（客户端手里的模型/动画），不是数据包漏放。","color":"green"}]
execute if score #slow dc.diag matches 1.. run tellraw @s [{"text":"⇒ 存在静默空档：这些时段「按了没反应」，而服务端当时没有报错 —— 元凶要么是原版冷却，要么是交互落在不能替换的方块上。","color":"yellow"}]
