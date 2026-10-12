# ⚠ 2026-10-05 修复（由新增的 consumable_shot 套件用例 K1 抓到）：
#   原写法 `if data storage doom.consumable:ctx shot.main` 是**存在性**测试，
#   而 shot.main 恒为 **1b 或 0b 二者之一** ⇒ 该条件**永远为真** ⇒
#   「副手」那一支（unless …）**永远不执行**。
#   后果：主手不是 shot 武器、只有副手是时，process_one 会去读**主手**（读到石头 ⇒
#   dc 复核不过 ⇒ 整次扣次被丢弃），writeback / depleted 也会往**主手**写。
#   ⇒ 副手射击链在真机上**完全不工作**（静默无效果，不报错）。
#   ⇒ 改为**值判定** `shot{main:1b}`（1b=主手走 if，0b=副手走 unless）。
# doom.consumable:shot/depleted —— 耗尽分派：vanish（默认）/ disable / normal
# 显式 disable / normal 命中则走专门处理；否则一律 vanish（与 consumable 家族默认一致）。
execute if data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc{depleted:"disable"} run function doom.consumable:shot/depleted_disable
execute if data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc{depleted:"normal"} run function doom.consumable:shot/depleted_normal
execute unless data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc{depleted:"disable"} unless data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc{depleted:"normal"} if data storage doom.consumable:ctx shot{main:1b} run item replace entity @s weapon.mainhand with air
execute unless data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc{depleted:"disable"} unless data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc{depleted:"normal"} unless data storage doom.consumable:ctx shot{main:1b} run item replace entity @s weapon.offhand with air
