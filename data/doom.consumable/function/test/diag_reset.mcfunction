# doom.consumable:test/diag_reset —— 清零"放置节奏"取证计数
#
# 为什么要单独一条：dc.diag 只在 `/reload`（__load__）时归零，而 A/B 两轮对比之间不会 reload
#   ⇒ 不清零就得拿"累计值"做差，读数会骗人。
# 三个夹具（place_rapid / place_once / give_infinite_glowstone）末尾都会自动调一次，
# 需要单独清零时也可手动跑。
scoreboard players set #n dc.diag 0
scoreboard players set #last dc.diag 0
scoreboard players set #now dc.diag 0
scoreboard players set #gap dc.diag 0
scoreboard players set #maxgap dc.diag 0
scoreboard players set #sumgap dc.diag 0
scoreboard players set #sumslow dc.diag 0
scoreboard players set #slow dc.diag 0
scoreboard players set #bursts dc.diag 0
