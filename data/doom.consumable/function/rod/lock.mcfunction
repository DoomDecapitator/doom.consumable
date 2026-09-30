# doom.consumable:rod/lock —— 给「当前手持的锁定鱼竿」挂上长冷却（use_cooldown）
#
# 为什么用 use_cooldown 做"不能使用"：
#   原版拦住"使用物品"的唯一数据驱动手段就是冷却 —— 挂着冷却的物品右键无效，
#   并且热键栏会画灰条（玩家**看得见**"现在不能用"，比静默失败友好）。
#   钓鱼竿确实受它影响（MC-275882 报的就是鱼竿的冷却行为）。
#   ⚠ 2026-10-01 源码更正：本行旧注释曾写"冷却不拦方块交互（MC-275796）"—— **在 1.21.6 不成立**。
#      ServerPlayerGameMode.useItemOn 第 345 行确有冷却门：
#        if (!stack.isEmpty() && !player.getCooldowns().isOnCooldown(stack)) stack.useOn(...)
#      ⇒ 物品自己的 useOn（锄/锹/桶/骨粉/放置方块）会被冷却拦住，连 item_used_on_block 触发器都不发火；
#      但**方块自身交互**（行 330 BlockState.useItemOn：箱子/按钮/拉杆/门…）与**空手交互**（行 337 useWithoutItem）
#      在冷却门之外 ⇒ 冷却对它们无效（要给方块做冷却只能自己造位置键计时器）。
# 时长：#rod_lock dc.cfg（秒，__load__ 默认 10）。冷却到期后由 rod/tick_one 续期 ⇒ 锁定期内始终不可用。
#
# 本函数自带条件判定（未锁 ⇒ 直接 return），所以调用方可以无条件调用：
#   · rod/tick_one —— 手里是锁定的鱼竿且没挂冷却时调用（续期）
#   · rod/deny     —— 被否决时顺手挂上（把"软否决"升级成"硬禁用"）
execute unless items entity @s weapon.mainhand #doom.consumable:rod_locked unless data entity @s SelectedItem.components."minecraft:custom_data"."dc"{rod_locked:1b} unless items entity @s weapon.offhand #doom.consumable:rod_locked unless data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{rod_locked:1b} run return 0

function doom.consumable:rod/pick
execute unless data storage doom.consumable:ctx rod.item run return 0

# 冷却秒数：默认 10，可用 #rod_lock dc.cfg 覆盖
scoreboard players set #rod_cd dc.temp 10
execute if score #rod_lock dc.cfg matches 1.. store result score #rod_cd dc.temp run scoreboard players get #rod_lock dc.cfg

# ⚠ 必须带 cooldown_group（2026-10-01 修复）：
#   源码 ItemCooldowns.getCooldownGroup = `uc.cooldownGroup().orElse(物品 id)` ⇒ 不写 group 时冷却键退化成
#   `minecraft:fishing_rod`，导致 ① 锁一把杆会顺带锁住**所有**鱼竿；② api/rod_enable 清掉组件后，
#   检查键仍是物品 id，玩家身上的旧冷却还在 ⇒ 解除后仍抛不出去（实测踩到）。
#   给"锁定冷却"一个专属 group 后：锁定期按键仍拦得住；解除后按键变回物品 id（无计时）⇒ 立刻可用；别的杆不受影响。
data modify storage doom.consumable:ctx rod.item.components."minecraft:use_cooldown" set value {seconds:0f,cooldown_group:"doom.consumable:rod_lock"}
execute store result storage doom.consumable:ctx rod.item.components."minecraft:use_cooldown".seconds float 1 run scoreboard players get #rod_cd dc.temp
function doom.consumable:rod/writeback with storage doom.consumable:ctx rod
