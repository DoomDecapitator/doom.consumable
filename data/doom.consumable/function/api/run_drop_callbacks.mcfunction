# doom.consumable:api/run_drop_callbacks — iterate through drop callback list
# Pops last item from storage list and calls it, recurses until empty
data modify storage doom.consumable:ctx _callback set from storage doom.consumable:data drop_callbacks[0]
data remove storage doom.consumable:data drop_callbacks[0]
execute if data storage doom.consumable:ctx _callback run function doom.consumable:api/exec_drop_callback with storage doom.consumable:ctx _
execute if data storage doom.consumable:data drop_callbacks[0] run function doom.consumable:api/run_drop_callbacks
