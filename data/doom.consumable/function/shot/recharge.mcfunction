# doom.consumable:shot/recharge —— 连发弹匣：给刚射完的弩重新上膛
#
# ⚠ 2026-10-05 实测（加载期报错，由新套件的真机验证抓到）：
#   原写法 `item modify entity @s $(slot) doom.consumable:shot_recharge` **加载不过**：
#     Unknown slot '$(slot)' —— `item modify` 的槽位参数是**命令的解析期字面量**，
#     宏替换发生在解析**之后**，所以占位符在那个位置永远不是一个合法槽位。
#     （对比：`item replace entity @s $(slot) …` 是能工作的 —— 它走的是另一段解析路径，
#       rod/writeback 就靠这个。⇒ 「宏能不能进槽位」要看具体命令，不能类推。）
#   ⇒ 改成**按 main/off 分支写死槽位**，由一个非宏的包装函数分发。
#
# 前置（调用方保证）：
#   · 执行者是玩家本人
#   · storage doom.consumable:ctx shot.main 存在且为 1b/0b（主手 / 副手）
#   · storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc.mag 存在（本件要连发）
#
# 为什么用 item modify 而不是 item_display 中转体（P0-2 的核心做法）：
#   writeback 走中转体是**被迫**的 —— 那时要写的是「运行时算出来的值」（uses / dmg），
#   宏参数只能进**命令字符串**，进不了「storage 里的 item NBT」。
#   而连发重上膛要写的值是**固定的**（charged_projectiles = [1 支箭]）⇒
#   用 `item modify` 引用一个 item_modifier JSON 即可直接改**玩家手持**的物品，
#   不需要先把物品搬到中转体、也不需要回写整件物品的 NBT。
#
# ⚠ 只有弩有 charged_projectiles 语义：弓/三叉戟身上没有这个组件，
#   对它们调用是无害的空操作（只是加了个它们不读的组件），
#   所以调用方必须先按 `dc.mag` 字段过滤 —— 见 process_one 的 ⑨ 段。
execute if data storage doom.consumable:ctx shot.main run function doom.consumable:shot/recharge_main
execute unless data storage doom.consumable:ctx shot.main run function doom.consumable:shot/recharge_off
