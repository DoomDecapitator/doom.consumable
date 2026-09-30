tellraw @s [{"text":"[dc] infinite glowstone x3","color":"green"}]
loot give @s loot doom.consumable:items/infinite_glowstone
loot give @s loot doom.consumable:items/infinite_glowstone
loot give @s loot doom.consumable:items/infinite_glowstone

# 清零上一次测试留下的计数（否则 触发/识别/叠数 会跨轮累计，读数会骗人）
scoreboard players set @s dc.trigger 0
scoreboard players set @s dc.placed 0
scoreboard players set @s dc.lastcount 0
scoreboard players set @s dc.placed_main 0
scoreboard players set @s dc.placed_off 0

# 放置节奏取证清零（跨轮对比必须清，否则只能拿累计值做差）
function doom.consumable:test/diag_reset

# ⚠ 2026-09-26 模式守卫：**创造模式下放方块不消耗物品**（instabuild），
#   "原版消耗 → 数据包塞回"这条链根本不会被真正跑过 ⇒ 幽灵/返还类测试在创造下全部无效。
#   （真机取证：玩家 Doom_Flare 的 playerdata 里 playerGameType=1、abilities.instabuild=1，
#    一晚上三次 place_rapid 的 109 次计数其实都是"没消耗的放置"。）
execute if entity @s[gamemode=creative] run tellraw @s [{"text":"⚠ 创造模式：放方块不消耗物品，「消耗→返还」链没跑过 —— 本测试无效。请先 /gamemode survival 再重跑本夹具。","color":"red"}]
execute unless entity @s[gamemode=creative] run tellraw @s [{"text":"模式 ✓ 生存：物品会被原版消耗，本夹具有意义。","color":"green"}]
