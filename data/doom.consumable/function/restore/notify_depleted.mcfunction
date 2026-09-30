# doom.consumable:restore/notify_depleted — 耗尽返还时的可见提示
# Call: function doom.consumable:restore/notify_depleted with storage doom.library:io output[-1].data.CACHE.consumable.data
#
# 2026-09-20 新增：返还物是 give 出去的，落在**第一个空位**——而耗尽时刚腾空的那格往往
#   就是玩家正握着的格子，所以它经常直接出现在手上。这里只说"返还了什么"，不猜落在哪。
#
# 为什么单独一个文件：这是宏函数，任何一个 $(var) 拼出来的非法命令都会让**整次调用被静默放弃**。
#   提示只是观感问题，绝不能让它有机会连累 do_depleted 里的 give —— 两者分开，互不影响。
$tellraw @s [{"text":"[dc] 已耗尽，返还 ","color":"gray"},{"text":"$(remainder)","color":"gold"},{"text":" ×1","color":"gray"}]
