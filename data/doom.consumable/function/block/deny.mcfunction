# doom.consumable:block/deny —— 否决：把剩余 tick 与 key 交给外部回调；可选设备自带反馈
#
# ⚠ 能力边界（诚实说明）：方块交互没有「使用前钩子」，所以**方块自己的行为已经发生了**
#   （箱子开了、按钮按了、门开了…）。本模块只负责「冷却判定 + 回调」，
#   要不要撤销 / 惩罚 / 改方块状态由回调决定；原版层面做不到「根本按不动」。
scoreboard players add @s dc.block_denied 1
scoreboard players operation #blk_left dc.temp = #blk_ready dc.temp
scoreboard players operation #blk_left dc.temp -= #blk_now dc.temp

# 冷却态外观（可选）：否决时把方块**重新按回**冷却中形态。
#   为什么必须重按：方块自己的交互可能改动状态（例：拉杆被点一下就翻面）⇒
#   不重按的话外观会说谎（显示「就绪」而逻辑仍在冷却）—— 2026-10-01 实测踩到。
execute if data entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] data.dc.cd_block_cooling run data modify storage doom.consumable:ctx blk.state set from entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] data.dc.cd_block_cooling
execute if data storage doom.consumable:ctx blk.state run function doom.consumable:block/set_device_state with storage doom.consumable:ctx blk
data remove storage doom.consumable:ctx blk.state
data remove storage doom.consumable:ctx block
execute store result storage doom.consumable:ctx block.left int 1 run scoreboard players get #blk_left dc.temp
data modify storage doom.consumable:ctx block.key set from entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] data.dc.cd_key
function #doom.consumable:on_block_denied

execute if data entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] data.dc.cd_deny_msg run data modify storage doom.consumable:ctx block.msg set from entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] data.dc.cd_deny_msg
execute if data entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] data.dc.cd_deny_sound run data modify storage doom.consumable:ctx block.sound set from entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] data.dc.cd_deny_sound
execute if data storage doom.consumable:ctx block.msg run function doom.consumable:block/deny_msg with storage doom.consumable:ctx block
execute if data storage doom.consumable:ctx block.sound run function doom.consumable:block/deny_sound with storage doom.consumable:ctx block
data remove storage doom.consumable:ctx block
