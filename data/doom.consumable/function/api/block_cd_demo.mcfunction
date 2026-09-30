# doom.consumable:api/block_cd_demo —— 原型：一条命令搭好「看得见冷却」的示范设备
#
# 做在【执行者脚下的方块】上：就绪=拉杆放下(powered=false)，冷却中=拉杆抬起(powered=true)，到期自动放下。
# 5 秒冷却 · cd_key=demo · 带否决提示（actionbar 由测试包钩子给出；正式包里显示与否由使用者的回调决定）。
# 用法：站在想做示范的方块上执行；拆掉用 api/block_cd_remove（方块会先换回就绪形态再删设备）。
execute at @s align xyz run kill @e[type=minecraft:marker,tag=dc.block_cd,distance=..1]
execute at @s align xyz run setblock ~ ~-1 ~ minecraft:lever[face=floor,powered=false] destroy
execute at @s align xyz run summon minecraft:marker ~0.5 ~-0.5 ~0.5 {Tags:["dc.block_cd"],data:{dc:{cd_seconds:5,cd_ready:0,cd_key:"demo",cd_count:0,cd_block_ready:"minecraft:lever[face=floor,powered=false]",cd_block_cooling:"minecraft:lever[face=floor,powered=true]",cd_deny_msg:"这台机器还在冷却"}}}
tellraw @s [{"text":"[dc] 示范设备已就位","color":"green"},{"text":"（脚下方块已换成拉杆）","color":"gray"}]
tellraw @s [{"text":"  ① 右键它 ⇒ 拉杆抬起、开始 5 秒冷却   ② 冷却中再右键 ⇒ 被否决（拉杆不动）","color":"gray"}]
tellraw @s [{"text":"  ③ 5 秒后自动放下（回到就绪）   ④ /function doom.consumable:api/block_cd_debug 看粒子","color":"gray"}]
