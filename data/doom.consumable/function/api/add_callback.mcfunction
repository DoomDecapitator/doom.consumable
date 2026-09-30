# doom.consumable:api/add_callback [MACRO]
# $(function) — function path to call when a discardable item is dropped
# Usage: function doom.consumable:api/add_callback {function:"mypack:my_handler"}
$data modify storage doom.consumable:data drop_callbacks append value '$(function)'
$tellraw @s [{"text":"[dc] Drop callback registered: ","color":"green"},{"text":"$(function)","color":"yellow"}]
