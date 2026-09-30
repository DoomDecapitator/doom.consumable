# doom.consumable:restore/put_slot [MACRO] —— 把中转体那件写进 $(name)，并在同一个调用里记下 #done
#
# 调用：execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:ib}] \
#           run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
# 宏参数：$(name) 目标槽位名（hotbar.N / inventory.N）
#
# ⚠⚠ 2026-09-27 真机事故（由探针 test/probe_put_anywhere 当场抓出，值得刻在墙上）：
#   原来梯子是"每槽两行、两行同一个判据"：
#     ① execute if #done==0 unless <该槽是空的> run item replace …   ← 把东西写进去
#     ② execute if #done==0 unless <该槽是空的> run scoreboard players set #done 1
#   ① 写完那一槽，就**把 ② 的判据自己改掉了**（空 → 占用）⇒ ② 永不执行 ⇒ #done 永远停在 0 ⇒
#     · 梯子一路写下去：**每一格空槽都被塞进同一件**（真机实测：barrier 0 → 26，一格里一件）
#     · 写完全部空槽后 #done 仍是 0 ⇒ 还走掉落兜底，再丢一件出去
#   这正是易错点 §2.4.2「**拿既要读又要写的判据当守卫**」的同族（那次是 recover/locate 的槽位游标）：
#   **守卫判据不能依赖自己即将写入的状态**。
#   现在：判据留在调用方（调用前求值一次，之后不可能被改写），"写"与"记标记"在同一个函数调用内完成。
#
# 内层判据用"中转体还在不在"—— 它不会被写入动作改变（写入只改玩家槽位），所以是稳定的守卫。
$execute if entity @e[type=item_display,tag=dc_restore_tmp,limit=1] run item replace entity @s $(name) from entity @e[type=item_display,tag=dc_restore_tmp,limit=1] contents
execute if entity @e[type=item_display,tag=dc_restore_tmp,limit=1] run scoreboard players set #done dc.temp 1
