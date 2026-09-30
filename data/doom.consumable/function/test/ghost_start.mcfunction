# doom.consumable:test/ghost_start —— 【第一轮】从零开始（客户端重同步 = 关）
#
# 一条命令做完：清场 → 定档位 → 发无冷却夹具 → 打印开局状态与做法。
# 之后的动作只有两个：按住右键 15~20 秒 → 跑 report_place。
scoreboard players set #resync dc.cfg 0
function doom.consumable:test/ghost_wipe
function doom.consumable:test/place_rapid
tellraw @s [{"text":"── 第一轮：重同步 = 关（基线） ──","color":"gold"}]
tellraw @s [{"text":"① 按住右键 15~20 秒，边放边扫动地面（准星别停着）。同时盯住手里那件荧石：一直看得见 / 偶尔闪 / 大部分看不见？","color":"yellow"}]
tellraw @s [{"text":"② 松手后跑 /function doom.consumable:test/report_place（再跑一次 probe_place_state 更好）","color":"yellow"}]
