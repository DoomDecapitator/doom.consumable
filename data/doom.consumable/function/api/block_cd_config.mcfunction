# doom.consumable:api/block_cd_config [MACRO] —— 追加一条「方块类型冷却」配置（≈ 给这类方块装一个 use_cooldown）
#
# 调用（5 个参数都要写，不想要的写 "-"）：
#   function doom.consumable:api/block_cd_config {tag:"doom.consumable:cd_example",seconds:30,key:"example",ready:"-",cooling:"-"}
#   · tag     = **方块标签** id（作者在 data/<ns>/tags/block/xxx.json 里列出要冷却的方块）
#   · seconds = 冷却秒数
#   · key     = 设备名（回调里读 storage doom.consumable:ctx block.key）；写 "-" 则自动用标签名
#   · ready / cooling = 可选外观：就绪/冷却时把方块换成什么状态串（"-" = 不改方块外观）
# 上限 8 条（判定是展开的）；超限请先 api/block_cd_config_clear。
#
# ⚠ 两条实测纪律（都在这里踩过）：
#   ① 数值宏占位符**不能塞进 NBT 复合**（`{seconds:$(seconds)}` 加载期校验不过 ⇒ 整函数 "Unknown function"）
#      ⇒ 先建一个占位条目，再逐字段"裸写"占位符（同 api/rod_durability 手法）；
#   ② `data modify` **不接受负下标**（`entries[-1]` 报 Invalid NBT path element）⇒ 先写到临时 storage，再 `append from`。
execute if data storage doom.consumable:block_cd entries[8] run tellraw @s {"text":"[dc] 配置已达上限 8 条，请先清空或删条目","color":"red"}
execute if data storage doom.consumable:block_cd entries[8] run return 0
data modify storage doom.consumable:ctx cfg set value {tag:"-",seconds:0,key:"-",ready:"-",cooling:"-"}
$data modify storage doom.consumable:ctx cfg.tag set value "$(tag)"
$data modify storage doom.consumable:ctx cfg.seconds set value $(seconds)
$data modify storage doom.consumable:ctx cfg.key set value "$(key)"
$data modify storage doom.consumable:ctx cfg.ready set value "$(ready)"
$data modify storage doom.consumable:ctx cfg.cooling set value "$(cooling)"
execute if data storage doom.consumable:ctx cfg{key:"-"} run data modify storage doom.consumable:ctx cfg.key set from storage doom.consumable:ctx cfg.tag
data modify storage doom.consumable:block_cd entries append from storage doom.consumable:ctx cfg
data remove storage doom.consumable:ctx cfg
tellraw @s [{"text":"[dc] 已加方块冷却配置 ","color":"green"},{"text":"$(tag)","color":"white"},{"text":" · 每 ","color":"gray"},{"text":"$(seconds)","color":"white"},{"text":" 秒","color":"gray"}]
