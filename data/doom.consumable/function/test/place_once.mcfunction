# 判定"放下去到底回不回来"的干净夹具
#
# 与 items/infinite_glowstone 同组件，只额外加 max_stack_size=1：
#   单件 ⇒ 放置后主手**立刻空** ⇒ 回没回来一眼可判。
#   （一叠多件时放置只是原版扣数 3→2，肉眼分不清是"没返回"还是"本来就该扣"。）
#
# 用法：
#   /function doom.consumable:test/place_once        ← 把单件荧石钉进主手
#   对着地面右键放一块                                ← 观察主手
#   /function doom.consumable:test/probe_place_state  ← 放完后立刻跑，看缓存与计时器
item replace entity @s weapon.mainhand with minecraft:glowstone[minecraft:max_stack_size=1,minecraft:item_name={text:"Infinite Glowstone"},minecraft:use_cooldown={seconds:5,cooldown_group:"dc.infinite"},minecraft:custom_data={dc:{detect:"place",type:"infinite"}}]
tellraw @s [{"text":"[PLC] 主手已放好一件单件 place 荧石。右键放一块，看主手是空的还是回来了。","color":"gold"}]
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

# 开局自检快照：双手 + 重同步开关（计数已在上方清零）
tellraw @s [{"text":"开局：主手 = ","color":"gray"},{"nbt":"SelectedItem.id","entity":"@s","color":"white"},{"text":" ×","color":"gray"},{"nbt":"SelectedItem.count","entity":"@s","color":"white"},{"text":"   副手 = ","color":"gray"},{"nbt":"equipment.offhand.id","entity":"@s","color":"white"},{"text":"   重同步 #resync = ","color":"gray"},{"score":{"name":"#resync","objective":"dc.cfg"},"color":"white"},{"text":"   （1 = 开着）","color":"yellow"}]
