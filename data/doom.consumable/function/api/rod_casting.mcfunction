# doom.consumable:api/rod_casting —— 查询执行者是否正在钓鱼（结果写进 #casting dc.temp：1 = 正在）
#
# 用例：外部逻辑据此决定"现在能不能做别的事"（例如限制区不让钓、正在钓时不给传送）。
# 读的是玩家分数 dc.rod_state（0 = 未抛竿 / 1 = 钓鱼中），由 rod/tick 的状态机维护。
scoreboard players set #casting dc.temp 0
execute if score @s dc.rod_state matches 1.. run scoreboard players set #casting dc.temp 1
