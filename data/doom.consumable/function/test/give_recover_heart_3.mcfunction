# doom.consumable:test/give_recover_heart_3 —— 一次给 3 个"恢复之心"
# 用法：/function doom.consumable:test/give_recover_heart_3
#
# 为什么单独一个函数：loot give 一次只给一份（max_stack_size=1），
#   想一次拿 3 个就得连调 3 次 —— 玩家在真机上测"多件同时回复"时正好要这个。
# 落点：loot give 走原版的"第一个空位"，背包满了会掉在脚下（不会覆盖任何东西）。
tellraw @s [{"text":"[dc] recover heart ×3（无限次 · 用完空条 · 5 秒回满 · 5 秒冷却）","color":"green"}]
loot give @s loot doom.consumable:items/recover_heart
loot give @s loot doom.consumable:items/recover_heart
loot give @s loot doom.consumable:items/recover_heart
