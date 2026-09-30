# doom.consumable:api/rod_reel_impl [MACRO] —— 真正的收回动作
#
# 调用：function doom.consumable:api/rod_reel_impl with storage doom.consumable:ctx rod
# 前置：rod.uid = 目标玩家的 UUID[0] int 分量（由 api/rod_reel 从 @s dc.rod_uid 分数读入）
# 单独拆一个文件的原因：**选择器里要插宏参数**，宏只能在被调用函数体内展开。
# B1：旧版 `nbt={Owner:[I;…]}` 在 1.21.6 匹配不到任何实体（浮标存档无 Owner 字段）；
#   归属标签 dc_rod_own_<uid> 由 rod/bind_impl 在抛竿那一刻打上——这才是可匹配的归属事实。
$kill @e[type=minecraft:fishing_bobber, tag=dc_rod_own_$(uid)]
