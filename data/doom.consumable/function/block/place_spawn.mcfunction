# doom.consumable:block/place_spawn [MACRO] —— 真正 summon（把 ready 预算好再进来，避免在 macro 里算分）
# 参数：plc.seconds / plc.ready
$summon minecraft:marker ~0.5 ~0.5 ~0.5 {Tags:["dc.block_cd","dc.block_cd_auto"],data:{dc:{cd_seconds:$(seconds),cd_ready:$(ready),cd_key:"placed",cd_count:0}}}
