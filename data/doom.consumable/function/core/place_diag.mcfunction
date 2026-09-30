# doom.consumable:core/place_diag —— 放置节奏记录（静默，只为"幽灵"取证）
#
# 为什么记"间隔"能分辨幽灵的两种可能：
#   · 原版按住右键的放置节拍固定（约每 4~5 tick 一次 = 4 次/秒左右），所以成功放置之间的间隔
#     应当是一串密集的 5~8 tick。
#   · 若密集串里夹着 16~199 tick 的空档，说明那段时间"点了但什么都没发生"：
#     客户端把点击吞了，或交互落在不能替换的方块上（原版行为，服务端零痕迹）—— 正是我们看不见的那层。
#   · 间隔 ≥ 200 tick（10 秒）视作"换了一轮"（中间去干别的了），只记 #bursts，不算空档。
#   · 若全部密集、且次数 ≈ 按住时长 × 4，则放置链完全健康，"看不见"是纯显示层的事。
#
# 调用点：core/mark_placed 的最后（此刻本 tick 的放置已被认出、落点也已定好）。
execute store result score #now dc.diag run time query gametime
scoreboard players operation #gap dc.diag = #now dc.diag
scoreboard players operation #gap dc.diag -= #last dc.diag
# 第一条记录没有"上一次"，间隔记 0
execute if score #n dc.diag matches 0 run scoreboard players set #gap dc.diag 0
# 换轮：间隔 ≥ 200 tick
# ⚠ `execute if/unless score` 的比较运算**两侧都必须是计分板持有者**，
#   右边写数字（`unless score #gap dc.diag < 200`）是加载期参数错误 ——
#   2026-09-26 实测：整个 place_diag 加载失败，三轮回合的节奏统计全空。
#   要和字面量比只能用 `matches`（`matches 200..` 等价于 ≥200）。
execute if score #gap dc.diag matches 200.. run scoreboard players add #bursts dc.diag 1
# 空档：16 ≤ 间隔 < 200 —— 这一段就是"按了没反应"的时长
execute if score #gap dc.diag matches 16..199 run scoreboard players add #slow dc.diag 1
execute if score #gap dc.diag matches 16..199 run scoreboard players operation #sumslow dc.diag += #gap dc.diag
# 轮内最大间隔（只取 < 200 的，换轮间隔不代表卡顿）
execute if score #gap dc.diag matches 1..199 unless score #gap dc.diag <= #maxgap dc.diag run scoreboard players operation #maxgap dc.diag = #gap dc.diag
execute if score #gap dc.diag matches ..199 run scoreboard players operation #sumgap dc.diag += #gap dc.diag
scoreboard players add #n dc.diag 1
scoreboard players operation #last dc.diag = #now dc.diag
