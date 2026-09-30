# doom.consumable:rod/catch —— 「成功钩取」事件（进度触发器 minecraft:fishing_rod_hooked 的奖励函数）
#
# 触发时机（官方 mcdoc 原文：Player successfully caught an item with a fishing rod or pulled an entity）
#   = 玩家**钓上物品**或**把实体拉回来**的那一刻。
#
# 【谓词闸门与函数内守卫的关系】
#   主闸门在进度里：fishing_rod.json 的 rod 谓词 =
#       {"items":["minecraft:fishing_rod"],
#        "predicates":{"minecraft:custom_data":{"dc":{"rod":1b}}}}
#   ⚠ 注意 predicates 是**与 items 同级**的键（源码：ItemPredicate.CODEC 里 DataComponentMatchers.CODEC
#   是 forGetter 直接嵌套 ⇒ 它的 components/predicates 两个字段被"摊平"到 ItemPredicate 这一层），
#   值写裸 NBT、语义是**子集匹配**（dc 里多别的键也命中）。写成 {"components":{"predicates":…}} 会报
#   "Unknown registry key … data_component_type: minecraft:predicates"（精确匹配 codec 吃掉了这一层）。
#   函数内这条守卫是**双保险**：谓词一旦被改错（本项目在 1.21.5→1.21.6 迁移时就被静默改错过一次，
#   表现为"功能整体失效但没有任何报错"），这里还能兜住，不至于把"别人的杆钓到鱼"也算进来。
#
# 这里做四件事：
#   ⓪ 闸门：主手/副手必须握着带 dc{rod:1b} 的鱼竿，否则直接返回
#   ① 计数 dc.rod_catch（每玩家累计成功次数，可直接做成就/统计）
#   ② 外部回调 #doom.consumable:on_rod_catch
#   ③ 物品自带效果：dc.rod_clear_durability:1b ⇒ 成功钩取后把耐久清空（满格）
#      —— 这就是"使用后耐久清空"这类需求的接口位置：写在物品上，不用改包

# ⚠ 重新上膛放在最前（2026-10-01 加固）：本函数后面有 return 守卫，
#   若 revoke 写在守卫之后，任何一次「守卫命中」的触发都会消耗掉成就却不重新上膛 ⇒ 之后永久失效。
advancement revoke @s only doom.consumable:fishing_rod
execute unless data entity @s SelectedItem.components."minecraft:custom_data"."dc"{rod:1b} unless data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{rod:1b} run return 0

scoreboard players add @s dc.rod_catch 1
function #doom.consumable:on_rod_catch

execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{rod_clear_durability:1b} run function doom.consumable:api/rod_durability {value:0}
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{rod_clear_durability:1b} run function doom.consumable:api/rod_durability {value:0}

# B2 修复（2026-09-30 审计发现）：奖励函数末尾**必须回收本进度**，否则触发器型进度一旦授予
#   就永久 done、再也不会发火——catch 事件每玩家只能响一次（其余四个触发器进度
#   [consume/using/inv_change/item_used] 都有同样的 revoke 行，唯独这条漏了）。
