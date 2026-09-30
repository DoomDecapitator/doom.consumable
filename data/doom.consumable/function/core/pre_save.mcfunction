# doom.consumable:core/pre_save — save usage snapshot to per-player CACHE.usage
#
# ⚠ 2026-10-01：守卫必须在 revoke 之后、且在**无条件写入之前**。
#   进度 using.json 已按"带 dc 的物品"过滤（predicates 子集匹配，见该文件），
#   但这里的守卫是双保险：谓词被改错时（本包在 1.21.5→1.21.6 迁移时就被静默改错过一次，
#   表现为功能整体失效且无任何报错）仍能拦住"用普通物品也写快照"。
#   没有它的后果很具体：第 5 行的 cache_data={} 与第 11 行的 sel 是**无条件写入**，
#   会把上一次的真正快照冲成 {sel:N}，恢复链随后按这份垃圾快照行动 = 吞/复制物品。
#   revoke 必须在最前：触发器型进度不回收就再也发不了火。
advancement revoke @s only doom.consumable:using
execute unless data entity @s SelectedItem.components."minecraft:custom_data"."dc" unless data entity @s equipment.offhand.components."minecraft:custom_data"."dc" run return 0

function doom.library:api/open
data modify storage doom.library:ctx _.cache_key set value "usage"
data modify storage doom.library:ctx _.cache_data set value {}
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc" run data modify storage doom.library:ctx _.cache_data.main_snap set from entity @s SelectedItem
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc" run data modify storage doom.library:ctx _.cache_data.off_snap set from entity @s equipment.offhand
# 2026-09-27：顺手记下"那一刻选中的热键槽"（SelectedItemSlot）。
#   恢复要按它回**原槽**，而不是按"当前选中槽"—— 玩家换槽后恢复会写进新槽、把新槽里的东西抹掉。
#   见 core/finalize_slot 与 restore/guard 的注释（玩家报障：频繁切换物品使用会吞物品）。
execute if data entity @s SelectedItemSlot store result storage doom.library:ctx _.cache_data.sel int 1 run data get entity @s SelectedItemSlot
# 时间戳：给"使用快照"打上游戏刻 —— process_usage_wrapper 靠它校验新鲜度。
#   为什么需要：只比"快照count − 当前count"认物品，会把**上一次起手却没消耗**留下的旧快照
#   当成这次被消耗的物品（2026-10-01 实测：先起手吃金苹果再松手 → 立刻用 0 秒物品，
#   结果金苹果被记账并被写回手里 = 凭空造物 + 偷换手持）。
execute store result storage doom.library:ctx _.cache_data.time int 1 run time query gametime
function doom.library:api/cache with storage doom.library:ctx _
data remove storage doom.library:ctx _.cache_key
data remove storage doom.library:ctx _.cache_data