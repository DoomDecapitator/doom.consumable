# doom.consumable:rod/reel —— 一次「收杆」事件（rod/watch_impl 判定：自己的浮标消亡 + 玩家仍持杆）
#
# B1 根治（2026-09-30）：收竿的引擎事实（javap + 真机双证）= 零统计 + hurtAndBreak
#   + ITEM_INTERACT_FINISH + 浮标实体消亡。旧版靠"统计上涨 + 状态 1"判定收杆——
#   引擎从不给收竿涨统计 ⇒ 永远不触发（死代码）。新版事件源 = watch_impl 的
#   浮标死亡监听（tag=dc_rod_own_<uid> 归属标签）。
# 玩家右键收杆（含钓获取杆：on_rod_catch 在 retrieve 内同刻先行，之后这里再发通用 reel）；
#   换手/丢杆/死亡/断线等外力由 watch_impl 的静默分支处理（无回调）。
scoreboard players set @s dc.rod_state 0
function #doom.consumable:on_rod_reel
