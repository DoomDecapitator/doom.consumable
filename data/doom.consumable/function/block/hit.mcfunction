# doom.consumable:block/hit —— 射线命中设备：判定「到期放行 / 冷却否决」
#
# 判据全在设备实体自己身上：
#   data.dc.cd_ready   = 下次可用的游戏刻（0 = 随时可用）
#   data.dc.cd_seconds = 冷却秒数
# 外部闸门 #doom.consumable:block_gate 可在里面「scoreboard players set #block_deny dc.temp 1」强制否决。
scoreboard players set #blk_hit dc.temp 1
execute store result score #blk_now dc.temp run time query gametime
scoreboard players set #blk_ready dc.temp 0
execute store result score #blk_ready dc.temp run data get entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] data.dc.cd_ready

scoreboard players set #block_deny dc.temp 0
function #doom.consumable:block_gate

execute if score #block_deny dc.temp matches 1 run function doom.consumable:block/deny
execute if score #block_deny dc.temp matches 0 if score #blk_now dc.temp >= #blk_ready dc.temp run function doom.consumable:block/allow
execute if score #block_deny dc.temp matches 0 if score #blk_now dc.temp < #blk_ready dc.temp run function doom.consumable:block/deny
