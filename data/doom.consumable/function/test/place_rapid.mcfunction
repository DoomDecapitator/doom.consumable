# 无冷却夹具：专门验证"无限放置"
#
# 与 items/infinite_glowstone 的唯一区别：**没有 use_cooldown**。
#   官方那件带 5 秒冷却（作者设计），连续放置会被原版挡下，
#   于是"无限次"和"放不快"两件事混在一起，肉眼分不清是哪个在起作用。
#   这个夹具把冷却这个变量排除掉：按住右键连续放，物品应当**永远不掉**。
#
# 判读：连续放十几次后主手仍是那件荧石 ⇒ 次数确实无限；
#       若中途消失了 ⇒ 那是真的掉数，回来找数据包。
item replace entity @s weapon.mainhand with minecraft:glowstone[minecraft:max_stack_size=1,minecraft:item_name={text:"Rapid Glowstone"},minecraft:custom_data={dc:{detect:"place",type:"infinite"}}]

# 清零上一轮的诊断计数
scoreboard players set @s dc.trigger 0
scoreboard players set @s dc.placed 0
scoreboard players set @s dc.lastcount 0
scoreboard players set @s dc.placed_main 0
scoreboard players set @s dc.placed_off 0

tellraw @s [{"text":"[PLC] 主手一件**无冷却** place 荧石（单件）。按住右键连续放，它应当永远不掉；放完跑 probe_place_state 看三个计数。","color":"gold"}]

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
