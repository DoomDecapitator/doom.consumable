# Recovery Heart "durability recovery" implementation chain

中文: `docs/实现链路-RecoveryHeart-20260928.md`

> Pack: `packs/doom.consumable` (namespace `doom.consumable`)
> Target environment: Minecraft Java 1.21.6+ Fabric (project positioning in `AGENTS.local.md:11`)
> Pack metadata: `pack.mcmeta` says `pack_format: 81`, `supported_formats: 48–82`, description `§6Doom Consumable §eC1 8.5§r - §fMarker Proxy`
> Directory layout: `data/doom.consumable/{advancement,function,loot_table,tags}` + `data/minecraft/tags/{function}`. **This pack has no `predicate/` directory** (confirmed by a whole-repo `find`).
> Method: **purely static reading** (file-by-file `grep`/`read`, no game started, `doom.test` not run). Everything inferred/unverified is explicitly marked.
> Date: 2026-09-28

---

## ① Conclusion in one sentence

**Recovery Heart is not a consumable that "repairs the durability of other items in the player's hand/inventory"**; what it implements is **"the recovery of the pseudo-durability bar on the item itself"** —— using the vanilla `minecraft:damage` component as a 10-notch bar; after a right-click eats it, the datapack puts **it itself** back into the same slot and empties the bar (`damage = 10`), then `recover/*` decrements `damage` by one notch every 10 ticks, filling it in 5 seconds; the rate limiting is handled by the vanilla `minecraft:use_cooldown` (5 seconds).

Four key points (all directly verifiable in the source):

1. **The entry point is a vanilla advancement, not polling**: right-click consumes the item → `minecraft:consume_item` advancement → `core/mark_consumed` sets a 1-tick timer → the next tick `core/process_usage_wrapper` recognizes the eaten item by the "snapshot count difference" (`advancement/consume.json:4`, `core/mark_consumed.mcfunction:2-3`, `tick.mcfunction:8-10`, `core/process_usage_wrapper.mcfunction:11-25`).
2. **"Whether this can be used" is entirely handled by vanilla components**: `minecraft:consumable` (`consume_seconds: 0.05`) + `minecraft:use_cooldown` (`seconds: 5.0`, `cooldown_group: "dc.recover_heart"`); there is **no** cooldown/use check on the pack side (`loot_table/items/recover_heart.json:13-27`).
3. **"Recovery" only recognizes the item's own declared `dc.recover:1b`**: the per-slot guard in `recover/scan` only matches entries carrying `dc{recover:1b}`; for other items **not even the macro call happens** (`recover/scan.mcfunction:22`, `recover/tick_one.mcfunction:25`). There is **no** code path in the pack that "scans the whole inventory for damaged items to repair".
4. **The timing state lives on the item** (`dc.rb_cd` = ticks left until the next notch), not in a player score ⇒ main hand/offhand/inventory, hand swaps, slot swaps, and several items carried at once each count separately (`recover/hit.mcfunction:7-19`, `recover/tick_one.mcfunction:14-18`).

> Exclusions (to avoid misreading): a whole-repo search for `dc.recover` / `recover_ticks` / `on_use_damage` puts **all** hits in this one chain of `doom.consumable` and its probes/suites, with no second consumer; this pack also has no "repair other items' durability" feature.

---

## ② The complete chain from trigger to effect

### 2.1 Real-machine timing (one use)

| Moment          | Who acts    | What happened                                                                                                                                | Evidence                                                                        |
| ----------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------- |
| T (player right-clicks)     | vanilla     | starts "using" (`consumable.consume_seconds = 0.05` ≈ 1 tick), the `using_item` advancement fires                                                               | `loot_table/items/recover_heart.json:17`, `advancement/using.json:4-17`    |
| T           | pack      | `core/pre_save`: stores the current `SelectedItem` / offhand / `SelectedItemSlot` into `CACHE.usage`                                                        | `core/pre_save.mcfunction:7-12`                                           |
| T           | vanilla + pack | use completes → vanilla eats the item → `consume_item` advancement → `core/mark_consumed`: `dc.consume_timer = 1`                                      | `core/mark_consumed.mcfunction:2-3`                                       |
| T+1         | pack      | `tick.mcfunction:8` timer 1→0; `:9` runs `core/process_usage_wrapper`                                                                      | `tick.mcfunction:8-10`                                                    |
| T+1         | pack      | uses "snapshot count − current count ≥ 1" to decide **which hand** was consumed; the cache must also carry `dc{detect:"consume"}`                                                               | `core/process_usage_wrapper.mcfunction:11-22`                             |
| T+1         | pack      | `core/process_type` → `core/finalize_slot` (sets `slot_cmd = hotbar.N`, `id`) → `schedule/infinite`                                        | `core/process_type.mcfunction:2-7`, `core/finalize_slot.mcfunction:21-32`  |
| T+1         | pack      | `schedule/infinite` writes the whole item + landing spot into `CACHE.consumable`, `args.uses=1`, `args.damage=on_use_damage=10`, then `dc.restore_timer = 1`           | `schedule/infinite.mcfunction:16-27`                                      |
| T+2         | pack      | `tick.mcfunction:6` restore_timer 1→0 → `:7` `restore/do_check_timer`                                                                | `tick.mcfunction:6-7`                                                     |
| T+2         | pack      | `restore/do_restore`: create an `item_display` relay entity → write `damage = 10` → stamp `resync` → `restore/guard` decides the landing spot → write back to `hotbar.N`                     | `restore/do_restore.mcfunction:28-53`                                     |
| every tick from T+2 | pack      | `recover/tick` → per player `recover/tick_one` → per slot `recover/scan`→`slot`→`hit`: `damage ≥ 1` and no `rb_cd` ⇒ start the timer `rb_cd = 10`, already decremented by 1 this tick (reads back 9) | `tick.mcfunction:17`, `recover/hit.mcfunction:43-54`                       |
| then every 10 ticks | pack      | the tick `rb_cd` hits 0: `damage − 1`, `rb_cd` resets to `recover_ticks`                                                                       | `recover/hit.mcfunction:49-54`                                            |
| at tick 100  | pack      | `damage` reaches 0 ⇒ delete `dc.rb_cd` (stop the timer); by then the vanilla 5-second cooldown has also expired and it can be used again                                                                                 | `recover/hit.mcfunction:63-65`, `test/give_recover_heart.mcfunction:13-16` |

Timing check: `10 notches × 10 ticks = 100 ticks = 5 seconds`, aligned with `use_cooldown.seconds = 5.0` (the comment in `test/give_recover_heart.mcfunction:13` says the same: *"bar fills up == cooldown ends, the rhythm lines up exactly"*).

### 2.2 Call graph (on use + return + recovery)

```text
【A. use and recognition】driven by vanilla advancements, not polling
player right-clicks (vanilla consumable 0.05s)
├─ advancement doom.consumable:using     trigger=minecraft:using_item, item.dc present
│    └─ core/pre_save                    → CACHE.usage{main_snap, off_snap, sel}
└─ advancement doom.consumable:consume   trigger=minecraft:consume_item (unconditional)
     └─ core/mark_consumed               → advancement revoke + dc.consume_timer = 1

【B. per-tick main chain】data/minecraft/tags/function/tick.json → doom.consumable:tick
doom.consumable:tick  (tick.mcfunction)
├─ 6-7   restore_timer decrements; at 0 →  restore/do_check_timer
│                                    └─ restore/do_restore（when not depleted）
│                                       ├─ relay entity item_display[tag=dc_restore_tmp]
│                                       ├─ restore/mark_sync       ← stamp resync, force a slot-sync packet
│                                       ├─ restore/guard {slot_cmd,id} → #can
│                                       │    ├─ 1 → restore/write_at {slot_cmd}     （back to the original slot）
│                                       │    └─ 0 → restore/put_anywhere → put_slot（first empty slot）／drop at the feet
│                                       └─ kill the relay entity
├─ 8-10  consume_timer decrements; at 0 → core/process_usage_wrapper   （see the recognition logic in 【A】）
│                                       └─ core/process_type
│                                            ├─ core/finalize_slot   → slot_cmd / id
│                                            └─ schedule/infinite    → CACHE.consumable + restore_timer=1
├─ 12-13 discard_timer decrements → restore/do_discard_restore        （discard chain, isomorphic）
├─ 15    core/detect_drop                                      （scan the just-dropped item）
├─ 17    recover/tick            ← ★ the driving entry point of durability-bar recovery
│        └─ as @a at @s → recover/tick_one        （must "run a whole player in one breath"）
│             ├─ 31  core/report_ctx_dirty（rb.item residue ⇒ report E201, self-check only）
│             ├─ 37-39 offhand: rb.item ← equipment.offhand → recover/hit {name:"weapon.offhand"}
│             ├─ 44   #rb_bag=1 → recover/scan        （36 slots, per-slot guard）
│             │         └─ per slot → recover/slot {i,name,slot}
│             │              └─ rb.item ← Inventory[{Slot:ib}] → recover/hit {name}
│             │                   └─ change damage / rb_cd → item_display[tag=dc_rb] → item replace … $(name)
│             └─ 47-50 #rb_bag=0 → main hand only（SelectedItem → weapon.mainhand）
├─ 21    core/refresh_hand_cache（refresh the hand cache for players not in a detection window）
├─ 26    rod/tick（fishing rod interface, before the end of this file）
└─ 37    core/snapshot_hand（hand snapshot, **must be the last step of the tick**）
    38  core/watch_offhand（offhand watchdog）
```

> The directory name `schedule/*` **has nothing to do with the `/schedule` command**: a whole-pack `grep` finds no `schedule function/clear` command at all (`grep -rn "^schedule" .` has zero hits); it is just the name of the dispatch layer that "registers this use in the cache and sets a timer".

### 2.3 The division of labor among the advancement files (why these are the entry points)

| Advancement                             | Trigger                            | Conditions                                     | Reward function                 |
| ------------------------------ | ------------------------------ | -------------------------------------- | -------------------- |
| `advancement/using.json`       | `minecraft:using_item`         | `item.predicates.custom_data.dc` (presence is enough) | `core/pre_save`      |
| `advancement/consume.json`     | `minecraft:consume_item`       | **unconditional**                                | `core/mark_consumed` |
| `advancement/item_used.json`   | `minecraft:item_used_on_block` | excludes 7 blocks + `dc{detect:"place"}`        | `core/mark_placed`   |
| `advancement/inv_change.json`  | `minecraft:inventory_changed`  | none                                      | `core/save_inv`      |
| `advancement/fishing_rod.json` | `minecraft:fishing_rod_hooked` | the `rod` predicate requires `dc{rod:true}`              | `rod/catch`          |

Recovery Heart takes the first two: `using_item` provides "the item as it was before being eaten" (the snapshot), and `consume_item` provides the event that "it really was eaten". This is also why `consume_seconds > 0` is a hard requirement —— at 0 seconds the `using_item` state never appears, the snapshot is always missing, the count difference is always 0, and vanilla eats the item while the datapack notices nothing (lint rule C5; the measured notes in `tools/doomtest/lint.mjs:76` and `:1200-1208`).

---

## ③ Key data structures and fields

### 3.1 The item side: Recovery Heart's components and `dc` contract

Source `loot_table/items/recover_heart.json:5-31` (item body `minecraft:heart_of_the_sea`):

| Component / field                    | Value                                                                       | Effect                                                                                                    | Lines                         |
| -------------------------- | ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | -------------------------- |
| `minecraft:item_name`      | `{"text":"Recover Heart"}`                                              | display name                                                                                                   | `:13`                      |
| `minecraft:max_stack_size` | `1`                                                                     | unstackable (a hard requirement for damageable items)                                                                                       | `:14`                      |
| `minecraft:max_damage`     | `10`                                                                    | **pseudo-durability bar = 10 notches**                                                                                       | `:15`                      |
| `minecraft:damage`         | `0`                                                                     | starts full                                                                                                  | `:16`                      |
| `minecraft:consumable`     | `{consume_seconds:0.05, animation:"none", has_consume_particles:false}` | eaten in 1 tick of right-click (0 seconds would not be detected, rule C5)                                                                          | `:17`                      |
| `minecraft:use_cooldown`   | `{seconds:5.0, cooldown_group:"dc.recover_heart"}`                      | vanilla cooldown: cannot be clicked again for 5 seconds, hotbar grey overlay                                                                                   | `:18`                      |
| `dc.detect`                | `"consume"`                                                             | take the "eating" detection chain                                                                                             | `:21`                      |
| `dc.type`                  | `"infinite"`                                                            | unlimited uses (**not a one-shot consumable**)                                                                                    | `:22`                      |
| `dc.on_use_damage`         | `10`                                                                    | empty its own bar after each use                                                                                          | `:23`                      |
| `dc.recover`               | `1` (written to disk as `1b`)                                                           | **the only switch that participates in pseudo-durability recovery**                                                                                     | `:24`                      |
| (easily confused) the `dc.recover` scoreboard objective     | deprecated                                                                     | **shares the name but is a different thing** from the item field: `scoreboard objectives add dc.recover` (`__load__.mcfunction:13`) is only a residual objective for old-save compatibility; this chain does not read it on any line | `__load__.mcfunction:8-15` |
| `dc.recover_ticks`         | `10`                                                                    | ticks needed per notch (default 10)                                                                                    | `:25`                      |

Fields written by the pack itself at runtime (`README.md:27-28` explicitly says "don't fill them in by hand"):

| Field                | Type  | Writer                                | Semantics                                       |
| ----------------- | --- | ---------------------------------- | ---------------------------------------- |
| `dc.rb_cd`        | int | `recover/hit.mcfunction:64`        | ticks left until the next notch; **its presence means "recovering"**; deleted when full (`:65`) |
| `dc.resync`       | int | `restore/mark_sync.mcfunction:16`  | a per-tick-unique timestamp, only to force the server to send a slot-sync packet (curing "ghost items")          |
| `dc.current_uses` | int | `restore/do_restore.mcfunction:31` | written on return (default `1` for the infinite class); this chain does not use it            |

### 3.2 Scoreboards (created by `__load__`, `__load__.mcfunction`)

| Objective                                                                          | Who writes / who reads                                                                 | Purpose                                                                 | Lines                     |
| --------------------------------------------------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------------ | ---------------------- |
| `dc.consume_timer`                                                          | write: `core/mark_consumed:3`, `tick.mcfunction:8,10`                         | a 1-tick delay window after consumption                                                   | `__load__:6`           |
| `dc.restore_timer`                                                          | write: `schedule/infinite:27`, `tick.mcfunction:6`, `restore/do_check_timer:2` | a 1-tick delay window before the return                                                   | `__load__:5`           |
| `dc.rb_slot`                                                                | write: `recover/slot:17`                                                     | **diagnostic cursor**: 0 main hand / 1 offhand / 100+N hotbar.N / 200+N inventory.N; no longer decides the write-back target | `__load__:18-19`       |
| `dc.cfg`                                                                    | `#resync` (default 1), `#rb_bag` (default 1), `#rod_lock` (default 10)                      | three switches                                                               | `__load__:42-50,61`    |
| `dc.temp`                                                                   | whole-pack temporary scores                                                                  | `#D/#iv/#cd/#write/#can/#done/…` all live here                                        | `__load__:20`          |
| `dc.recover` / `dc.recover_interval` / `dc.recover_step`                    | **deprecated** (only the objective definitions are kept, to avoid "unknown scoreboard" on old saves)                                          | old player-level timers                                                           | `__load__:8-15`        |
| `dc.trigger`/`dc.placed*`/`dc.off_*`/`dc.diag*`/`dc.u.glowstone`/`dc.rod_*` | for diagnostics and the fishing rod chain                                                                 | unrelated to this chain                                                              | `__load__:21-41,51-61` |

### 3.3 storage

| Location                                                         | Content                                                    | Note                                                                    |
| ---------------------------------------------------------- | ----------------------------------------------------- | --------------------------------------------------------------------- |
| `doom.consumable:ctx rb.item`                              | the complete NBT of the item currently being processed                                     | a **globally shared temporary key**, so it must "run a whole player in one breath" and be cleared each round (`recover/tick_one.mcfunction:27-34`) |
| `doom.consumable:ctx args`                                 | `{i,name,slot}` macro parameters (flattened)                               | laid out per slot by `recover/scan` (`recover/scan.mcfunction:21`)                 |
| `doom.consumable:ctx task_data`                            | `{item, hand, sel, slot_path, slot_cmd, id}`          | the task packet after a use has been recognized (`core/process_usage_wrapper.mcfunction:19-25`)             |
| `doom.library:io players.data.<idx>.CACHE.usage`           | `{main_snap, off_snap, sel}`                          | hand snapshot (`core/pre_save.mcfunction:7-12`)                                 |
| `doom.library:io players.data.<idx>.CACHE.consumable`      | `{item, slot_path, slot_cmd, id, args:{uses,damage}}` | everything needed for the return (`schedule/infinite.mcfunction:6-27`)                        |
| `doom.library:io output[-1].data`                          | the result bits of a cache read                                               | `doom.library:api/read.mcfunction:6-7`                                |
| `doom.library:io players.data.<idx>.CACHE.<key>.timestamp` | the cache write moment                                                | `doom.library:api/cache.mcfunction:8`                                 |

---

## ④ Core functions explained line by line

### 4.1 `recover/tick`: only "dispatch per player"

```mcfunction
# recover/tick.mcfunction:17
execute as @a at @s run function doom.consumable:recover/tick_one
```

The file header lays out the discipline: the shared temporaries (`rb.item` + the relay entity tag) are **a single global copy**, and splitting them into several `as @a` lines makes multiple players overwrite each other (`recover/tick.mcfunction:11-16`). `at @s` is needed —— the landing spot of `summon ~ ~ ~` in `recover/hit` is the player's feet.

### 4.2 `recover/tick_one`: gate + offhand + inventory

```mcfunction
# recover/tick_one.mcfunction:25 —— threshold (zero cost for the vast majority of players)
execute unless data entity @s Inventory[{components:{"minecraft:custom_data":{dc:{recover:1b}}}}] unless data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{recover:1b} run return 0
```

```mcfunction
# recover/tick_one.mcfunction:31 —— concurrency self-check sentinel (must come before the data remove below)
execute if data storage doom.consumable:ctx rb.item run function doom.consumable:core/report_ctx_dirty
# :34
data remove storage doom.consumable:ctx rb.item
# :37-39 —— offhand: not in the Inventory list, so a separate step
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{recover:1b} run data modify storage doom.consumable:ctx rb.item set from entity @s equipment.offhand
data modify storage doom.consumable:ctx args set value {name:"weapon.offhand",slot:1}
execute if data storage doom.consumable:ctx rb.item run function doom.consumable:recover/hit with storage doom.consumable:ctx args
# :44 —— inventory + main hand (the main hand is the selected hotbar slot, handled uniformly by the scan, **no longer handled separately**)
execute if score #rb_bag dc.cfg matches 1 run function doom.consumable:recover/scan
```

When `#rb_bag dc.cfg = 0` it falls back to "hands only" (main hand + offhand), see `:47-50`; both branches clear `rb.item` once at the end (`:53`).

### 4.3 `recover/scan` + `recover/slot`: a per-slot scan of 36 slots

`scan` is **script-generated** (generator `tools/gen_recover_slots.py`, slot naming rules in `:60-66`), two lines per slot:

```mcfunction
# recover/scan.mcfunction:41-42（example: Inventory.Slot 9 → inventory.0）
data modify storage doom.consumable:ctx args set value {i:9,name:"inventory.0",slot:200}
execute if data entity @s Inventory[{Slot:9b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
```

- Coverage: `Inventory.Slot 0-8 → hotbar.0-8` (`:20-38`), `Inventory.Slot 9-35 → inventory.0-26` (`:40-94`).
- **Only slots carrying `dc{recover:1b}` enter the macro call**; other items cost nothing.
- Clears `rb.item` when done: `:96-97`.

`recover/slot`'s three lines each do their part (`recover/slot.mcfunction:1-19`):

```mcfunction
# recover/slot.mcfunction:17-19
$scoreboard players set @s dc.rb_slot $(slot)                                  # ① diagnostic cursor
$data modify storage doom.consumable:ctx rb.item set from entity @s Inventory[{Slot:$(i)b}]   # ② pick the item
function doom.consumable:recover/hit with storage doom.consumable:ctx args     # ③ hand it to hit
```

> An `Inventory` entry carries its own `Slot` field, so an NBT filter can pick out the matched item in one go —— but you **cannot** append a `[0]` index after the filter (pinned by the project, `recover/slot.mcfunction:12-16`).

### 4.4 `recover/hit`: **where the durability is really changed**

State machine (header comment at `recover/hit.mcfunction:7-10` + implementation at `:43-54`):

```mcfunction
# :25-26 read damage (**missing means 0 = full bar**)
scoreboard players set #D dc.temp 0
execute if data storage doom.consumable:ctx rb.item.components."minecraft:damage" store result score #D dc.temp run data get storage doom.consumable:ctx rb.item.components."minecraft:damage"

# :31-33 read the interval: the item reports dc.recover_ticks itself, default 10; ≤0 also falls back to 10
scoreboard players set #iv dc.temp 10
execute if data storage doom.consumable:ctx rb.item.components."minecraft:custom_data"."dc".recover_ticks store result score #iv dc.temp run data get storage doom.consumable:ctx rb.item.components."minecraft:custom_data"."dc".recover_ticks
execute if score #iv dc.temp matches ..0 run scoreboard players set #iv dc.temp 10

# :36-37 read the countdown (-1 = this one is not recovering)
scoreboard players set #cd dc.temp -1
execute if data storage doom.consumable:ctx rb.item.components."minecraft:custom_data"."dc".rb_cd store result score #cd dc.temp run data get storage doom.consumable:ctx rb.item.components."minecraft:custom_data"."dc".rb_cd

# :43  full bar: write once only when "rb_cd is still left over" (self-heal, prevents a timer that cannot stop)
execute if score #D dc.temp matches ..0 if score #cd dc.temp matches 0.. run scoreboard players set #write dc.temp 1
# :46-47 not full + not recovering → start the timer
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches ..-1 run scoreboard players set #write dc.temp 1
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches ..-1 run scoreboard players operation #cd dc.temp = #iv dc.temp
# :50-54 not full + recovering → decrement first, then test (otherwise the last notch is always one short)
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches 1.. run scoreboard players set #write dc.temp 1
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches 1.. run scoreboard players remove #cd dc.temp 1
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches 0 run scoreboard players set #write dc.temp 1
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches 0 run scoreboard players remove #D dc.temp 1
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches 0 run scoreboard players operation #cd dc.temp = #iv dc.temp
# :56 nothing needs changing ⇒ return directly (no relay entity created)
execute if score #write dc.temp matches 0 run return 0
```

Write-back path (`recover/hit.mcfunction:59-68`):

```mcfunction
kill @e[type=item_display,tag=dc_rb]                                     # clear residue first (tag dedicated to this pack)
summon minecraft:item_display ~ ~ ~ {Tags:["dc_item","dc_rb"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_rb,limit=1] item set from storage doom.consumable:ctx rb.item
execute store result entity @e[type=item_display,tag=dc_rb,limit=1] item.components."minecraft:damage" int 1 run scoreboard players get #D dc.temp
execute if score #D dc.temp matches 1.. store result entity @e[type=item_display,tag=dc_rb,limit=1] item.components."minecraft:custom_data"."dc".rb_cd int 1 run scoreboard players get #cd dc.temp
execute if score #D dc.temp matches 0 if data entity @e[type=item_display,tag=dc_rb,limit=1] item.components."minecraft:custom_data"."dc".rb_cd run data remove entity @e[type=item_display,tag=dc_rb,limit=1] item.components."minecraft:custom_data"."dc".rb_cd
$item replace entity @s $(name) from entity @e[type=item_display,tag=dc_rb,limit=1] contents
kill @e[type=item_display,tag=dc_rb,limit=1]
data remove storage doom.consumable:ctx rb.item
```

**Answering "how much is repaired at a time / is other data preserved"**:

- It changes only **1 notch** at a time (`damage − 1`), and only on the tick `rb_cd` reaches zero; there is **no** path that fills it in one go, and no batch loop.
- The item is taken **whole** from the target slot (`rb.item` is that slot's Inventory entry), and the write-back **overwrites only two places**: `components."minecraft:damage"` and `components."minecraft:custom_data"."dc".rb_cd`. Enchantments, `item_name`, other NBT/components and `count` are all preserved as-is.
- Each item is handled at most once per tick (`hit` handles one item per call).

### 4.5 The return chain (`restore/*`): putting the eaten item back into **the very slot it came from**

1. `restore/do_check_timer.mcfunction:2-18`: clear `restore_timer` → read `CACHE.consumable` → only with `depleted` go to `do_depleted` (returning `remainder`) → otherwise `do_restore`; clear the cache at the end.
2. `restore/do_restore.mcfunction:28-36`: create `item_display[tag=dc_restore_tmp]`, `item` ← the item from the cache, write `current_uses` (`:31`), and **write `damage` only when the item has `max_damage`** (`:36`, this is the line that writes `damage = 10` for Recovery Heart).
3. `restore/mark_sync.mcfunction:16`: `store result entity … "dc".resync int 1 run time query gametime` —— a per-tick-unique stamp, curing "ghost items" (consumption + return in the same tick, byte-identical content ⇒ the server decides "the slot did not change" and sends no packet ⇒ the client stays on the "consumed" screen).
4. The landing spot, one of three (`restore/do_restore.mcfunction:48-50`):
   - `restore/guard`: `#can = 1` if and only if **the target slot is empty** or **it still holds the same item** (`restore/guard.mcfunction:18-20`, using 1.21.5+'s `execute if items entity @s <slot> <pred>`);
   - `#can = 1` → `restore/write_at`: `$item replace entity @s $(slot_cmd) from entity … contents` (`restore/write_at.mcfunction:6`);
   - `#can = 0` → `restore/put_anywhere`: find the first empty slot in `hotbar.0-8 → inventory.0-26` order and write it via `restore/put_slot` (`restore/put_anywhere.mcfunction:21-91`, `restore/put_slot.mcfunction:19-20`); only when all 36 slots are full does it `summon minecraft:item` at the feet (`:93-99`). **No path destroys or overwrites anything.**
5. `restore/do_restore.mcfunction:53` kills the relay entity.

Where `slot_cmd` comes from (`core/finalize_slot.mcfunction:21-32`): the main hand can be precise to `hotbar.N` (using the `SelectedItemSlot` at the moment of consumption, with the macro in `core/sel_slot_cmd.mcfunction:13` turning the number into a slot name), the offhand is fixed at `weapon.offhand`, and when the reading cannot be taken it degrades to `slot_path` (the old behavior).

### 4.6 The recognition section (`process_usage_wrapper` / `process_type` / `schedule/infinite`)

```mcfunction
# core/process_usage_wrapper.mcfunction:12-22（excerpt）
execute store result score #now_main dc.temp run data get entity @s SelectedItem.count
scoreboard players operation #main_diff dc.temp = #snap_main dc.temp
scoreboard players operation #main_diff dc.temp -= #now_main dc.temp
execute if score #main_diff dc.temp matches 1.. if data storage doom.library:io output[-1].data.CACHE.usage.data.main_snap.components."minecraft:custom_data"."dc"{detect:"consume"} run data modify storage doom.consumable:ctx task_data.item set from storage doom.library:io output[-1].data.CACHE.usage.data.main_snap
```

```mcfunction
# core/process_type.mcfunction:5-7
execute if data storage doom.consumable:ctx task_data.hand run function doom.consumable:core/finalize_slot
execute if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{type:"limited"} run function doom.consumable:schedule/limited with storage doom.consumable:ctx task_data
execute if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{type:"infinite"} run function doom.consumable:schedule/infinite with storage doom.consumable:ctx task_data
```

```mcfunction
# schedule/infinite.mcfunction:16-27（Recovery Heart takes this one）
data modify storage doom.library:ctx _.cache_data.args.uses set value 1
data modify storage doom.library:ctx _.cache_data.args.damage set value 0
execute if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc".on_use_damage run data modify storage doom.library:ctx _.cache_data.args.damage set from storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc".on_use_damage
function doom.library:api/cache with storage doom.library:ctx _
scoreboard players set @s dc.restore_timer 1
```

- `args.damage` defaults to 0 (the old behavior); Recovery Heart becomes "empty the bar on use" through `dc.on_use_damage = 10` (the comment in `:19-22` names `items/recover_heart` directly).
- `args.uses` defaults to 1, and is overridden only when the item has `current_uses` (the hardening comment in `:12-17`: an unconditional `set from` would **abort the whole function** when the source is missing, causing "the item is used up and can never come back").
- `schedule/limited` (the limited-uses class) treats `max_damage` as the scale and computes `damage = maxbar − uses` (`schedule/limited.mcfunction:39-42`); on depletion it follows `depleted` and goes to `disable/vanish/remainder`, clearing only "the slot it originally was in, and only if it is still the same item" (`schedule/limited.mcfunction:106-113,137`, `schedule/clear_slot.mcfunction:17`). Recovery Heart is `infinite` and **does not go through this at all**.

### 4.7 The correct way to "read and write item NBT" in 1.21.6 (this pack's actual usage)

| Purpose                    | Form                                                                                                                                | Source                                                                                        |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **read** a held item's component          | `data get entity @s SelectedItem.components."minecraft:damage"` (`components."<component id>"`, with quotes)                                        | `test/probe_recover_all.mcfunction:10`                                                    |
| **read** a whole item from a slot           | `data modify storage <s> <k> set from entity @s Inventory[{Slot:12b}]`                                                            | `recover/slot.mcfunction:18`                                                              |
| **match** an item in a slot          | `Inventory[{Slot:12b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}]`                                                    | `recover/scan.mcfunction:22`                                                              |
| **write** a component of an entity's item         | `data modify entity <e> item.components."minecraft:damage" set value <n>`                                                         | `api/rod_durability.mcfunction:11`                                                        |
| **write** (from a score)            | `execute store result entity <e> item.components."minecraft:custom_data"."dc".rb_cd int 1 run scoreboard players get #cd dc.temp` | `recover/hit.mcfunction:64`                                                               |
| **delete** a key inside a component            | `data remove entity <e> item.components."minecraft:custom_data"."dc".rb_cd`                                                       | `recover/hit.mcfunction:65`                                                               |
| **write** a player slot             | only `item replace entity @s <slot> from entity <item_display> contents` (a player inventory **cannot** be written with `data modify`, pinned by the project)                         | `recover/hit.mcfunction:66`, `restore/write_at.mcfunction:6`, `rod/writeback.mcfunction:8`  |
| slot names                   | `hotbar.N` / `inventory.N` / `weapon.mainhand` / `weapon.offhand`; `N` can only be a literal ⇒ substitute with a macro                                               | `core/sel_slot_cmd.mcfunction:13`; `tools/gen_recover_slots.py:6-7` (`container.N` is illegal for a player entity) |
| **test occupancy / same item** (1.21.5+) | `execute if items entity @s <slot> *` / `execute if items entity @s <slot> <item_id>`                                             | `restore/guard.mcfunction:19-20`                                                          |
| number width                  | loot_table JSON numbers are written to disk at **minimum width** (`10` → `10b`): criteria must be written `1b`/`12b`, and use `data get` to compare values (**do not** compare width with an NBT number criterion)                                | `recover/hit.mcfunction:29-30`, `tools/doomtest/lint.mjs:82` (C12)                          |
| **remove a vanilla component**            | write `"!minecraft:consumable": {}` (the 1.21.5+ "explicit removal" form; `data remove` cannot delete a component the prototype carries)                                                       | `schedule/limited.mcfunction:72-79,108`                                                   |

---

## ⑤ Boundaries and known pitfalls

### 5.1 Explicitly handled by the design

| Boundary                     | Behavior                                                                                                                  | Evidence                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| the bar is full (`damage` missing or 0)   | **write nothing** (`#write=0`, return 0 directly); only when "`rb_cd` is still left over" does it clear the timer once                                                          | `recover/hit.mcfunction:25-26,43,56`                                                                                  |
| non-participating items                  | slots without `dc{recover:1b}` **do not even call `recover/slot`**; even if forced into `hit`, a missing `damage` ⇒ treated as full ⇒ `damage` is not written and no `damage` component is added to it | `recover/scan.mcfunction:22`, `recover/hit.mcfunction:26`, `doom.test:suite/consumable_recover.mcfunction:201-207` (assertion ⑩) |
| swapping hands / slots / moving into the inventory          | the advancement does not lose step (the state is on the item), write-back uses each item's slot name                                                                                             | `recover/tick_one.mcfunction:14-18`, `recover/scan.mcfunction:12-13`                                                   |
| several carried at once                | scanned per slot ⇒ each counts separately, no cross-talk (the disease of the old player-level timer)                                                                                        | `recover/scan.mcfunction:6-13`, `recover/hit.mcfunction:12-19`, suite ⑥~⑧ assertions                                               |
| full bar stops the timer                   | `damage = 0` ⇒ delete `rb_cd`; further driving cannot make it negative                                                                                   | `recover/hit.mcfunction:63-65`, suite ⑨ assertion                                                                                |
| the item is repaired by other means              | full bar + leftover `rb_cd` ⇒ just clear the timer (self-heal)                                                                                           | `recover/hit.mcfunction:42-43`                                                                                        |
| the target slot is taken by someone else on return            | **never overwrites**: find the first empty slot; only when all 36 slots are full does it drop at the feet (`PickupDelay: 0`, immediately pickable) with a yellow line                                                            | `restore/guard.mcfunction:8-17`, `restore/put_anywhere.mcfunction:93-99`                                               |
| consumption + return in the same tick causing a "ghost item" | `restore/mark_sync` stamps a per-tick-unique value to force a packet; switch `#resync dc.cfg` (default 1)                                                            | `restore/mark_sync.mcfunction:6-16`, `__load__.mcfunction:42-46`                                                       |
| the player switching slots between "consumption → return"         | the landing spot is precise to `hotbar.N` (the `SelectedItemSlot` at the moment of consumption), no longer writes "the currently selected slot"                                                              | `core/finalize_slot.mcfunction:6-19`                                                                                  |
| leftover relay entities                  | every flow "kills before summoning" and kills immediately when done                                                                                    | `recover/hit.mcfunction:59`, `restore/do_restore.mcfunction:28`                                                        |
| multiple players + a shared temporary key            | the per-player body must "run in one breath"; when `rb.item` is left over it reports E201 (`doom.log`)                                                                       | `recover/tick_one.mcfunction:4-12,27-31`, `core/report_ctx_dirty.mcfunction:13`                                        |

### 5.2 Not implemented / worth noting

| Item                                    | Fact                                                                                                                | Evidence / note                                                                                                  |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **it does not repair other items' durability**                         | the whole chain only processes items carrying `dc.recover:1b` themselves; there is no "scan for damaged items" code in the pack                                                                       | a whole-repo `grep dc.recover` hits only this chain                                                                               |
| armor slots / ender chest / containers / crafting grid                 | **do not participate** in recovery: the scan range is only `Inventory`'s 36 slots + `equipment.offhand`; no other slot paths appear anywhere in the pack                                          | `recover/scan.mcfunction:20-94`, `recover/tick_one.mcfunction:37`                                         |
| durability cap                                 | **does not read `max_damage`**: `hit` just decrements `damage` to 0 and stops, without checking the cap or clamping                                                           | `recover/hit.mcfunction:25-26,53`                                                                        |
| the default `damage` is not read                     | missing means `0` = full bar (so an item "without a durability bar + carrying `recover:1b`" is **spinning idle**, not corrupted)                                                          | `recover/hit.mcfunction:25-26`; suite ⑩ asserts "no damage component is added"                                                    |
| stackable items                                 | no special handling: the whole stack is read and written back together; `damage` is a stack-level component ⇒ a stack counts as one item's progress. Recovery Heart itself has `max_stack_size: 1`                              | `recover/hit.mcfunction:61,66`, `loot_table/items/recover_heart.json:14`                                  |
| unbreakable items (`unbreakable`/no `max_damage`) | no dedicated criterion (a whole-pack `grep unbreakable` has zero hits); safety is indirect, through "`damage` unreadable ⇒ full bar ⇒ no write"                                                    | `recover/hit.mcfunction:26` (inferred, not verified on a real machine)                                                                    |
| creative mode                                 | **no gamemode check at all** (whole-pack gamemode criteria appear only in warnings of place-class test fixtures). If vanilla does not consume the item in that mode, `consume_item` does not fire ⇒ the whole chain does not start (the result is "nothing happens") | `test/place_once.mcfunction:27-28` etc.; the consume side's creative-mode behavior is **unverified**                                             |
| the vanilla 5-second cooldown                             | the pack **neither reads nor writes** `use_cooldown` (whole-pack `use_cooldown` appears only in the rod chain and probes); the 5-second grey overlay is the item component + vanilla behavior, the pack only manages the bar                                   | `grep use_cooldown` (hits only `rod/*`, `api/rod_*`, `test/*`); `test/give_recover_heart.mcfunction:14-15` is the author's expectation |
| offline players                                 | not handled: `recover/tick` only runs `@a` (online). Because the state is on the item, "the timer does not advance while offline" is to be expected; but it is **unverified** (especially the return path when "consumed then immediately logging out → logging back in"; the timers are player scores and whether they catch up across sessions is unverified)       | `recover/tick.mcfunction:17`                                                                             |
| `ghost_wipe`                         | merely the **test fixture**'s cleanup function (kills leftover `dc_restore_tmp`/`dc_tmp` relay entities, clears both hands, resets the diagnostics and the three timers); not part of the production chain                                        | `test/ghost_wipe.mcfunction:8-20`                                                                        |
| `rb.item` carries the `Slot` field              | `set from entity @s Inventory[{Slot:ib}]` takes the **whole entry** (including `Slot:Nb`), so the relay entity's `item` carries this key too; the pack does not clean it up, and there is no comment saying it was verified        | `recover/slot.mcfunction:18`, `recover/hit.mcfunction:61` (**an observation, whether it has side effects on the item is unverified**)                           |
| test fixture comment drift                            | the `doom.test` pump function's header comment still says "timer = damage × interval" (the old player-level timer model), inconsistent with the item-level `rb_cd` after the 09-27 revision; although the conclusion "does not read real time, can be driven synchronously" still holds     | `packs/doom.test/.../lib/recover_pump.mcfunction:4-6`                                                    |
| performance                                   | only players carrying an item with `dc{recover:1b}` pay the cost of "36 guard lines + 1 offhand guard per tick"; other players are blocked by the threshold at `:25`                                   | `recover/tick_one.mcfunction:20-22,25`                                                                   |
| lower bound on the recovery rate                               | at most 1 notch per item per tick (no inner loop) ⇒ with `recover_ticks = 1` even 10 notches take 10 ticks to fill                                                  | `recover/hit.mcfunction:50-54`                                                                           |

---

## ⑥ If I want to replicate this in my own pack: minimal checklist

1. **The item side (loot table / item parameters)**
   - `minecraft:max_damage: <notches>` + `minecraft:damage: 0` + `minecraft:max_stack_size: 1` (damageable and unstackable is a hard requirement, otherwise a load-time error: `Item cannot be both damageable and stackable`, rule C6).
   - `minecraft:consumable: {consume_seconds: 0.05, ...}`: **must be > 0** (at 0 seconds `using_item` does not appear and the whole chain does not start, rule C5).
   - To make it "recover only when used up": add `dc.on_use_damage: <notches>`; to make it "lose a notch per use and slowly recover": change it to `on_use_damage: 1`.
   - For rate limiting you can add `minecraft:use_cooldown: {seconds: <notches × recover_ticks / 20>, cooldown_group: "<your group name>"}`.
   - Contract: `dc.detect:"consume"`, `dc.type:"infinite"`, `dc.recover:1b` (**a byte; the criterion must be written `1b`**), `dc.recover_ticks:<int, default 10>`.
2. **The trigger side**: two advancements (`using_item` → store a hand snapshot; `consume_item` → set a 1-tick timer) + one `#minecraft:tick`, all three indispensable (the `using_item` snapshot is "the item as it was before being eaten").
3. **The return side** (optional but strongly recommended, otherwise the item is gone after one eat): cache "the whole item + slot name + item id", and the next tick write it back with `item replace entity @s <slot> from entity <item_display> contents`; before writing, check "empty or the same item", and if not, move to an empty slot / drop at the feet, **never overwriting**. The main hand must be precise to `hotbar.N` (otherwise a player changing slots swallows items).
4. **The recovery side**: every tick `execute as @a at @s run function <your>:recover_tick_one`, with the gate `unless data entity @s Inventory[{…dc:{recover:1b}}] … run return 0`, then per slot the `Inventory[{Slot:Nb,components:{…}}]` guard → pick the item → state machine (`rb_cd` present / start the timer / decrement first then test / `damage − 1` at zero) → relay entity write-back.
5. **One discipline**: in the per-player body do **not** split "pick the item" and "write back" into several `as @a` lines (the shared `rb.item` + `limit=1` relay entity would be overwritten by the next player); always keep the state on the item (`dc.rb_cd`), not in a player score.
6. **Regression tests**: cover at least these 8 classes: "start the timer / only advance a notch after 10 ticks / swap to the offhand / move into the inventory / three items each independent / a full bar does not block others / full bar stops the timer / no field, no participation" (you can copy the assertion list of `packs/doom.test/data/doom.test/function/suite/consumable_recover.mcfunction` directly).

---

## ⑦ Evidence index (`file:line`)

**Item and contract**

- `loot_table/items/recover_heart.json:5-31` (components and the whole `dc` table), `:13-18` (consumable / use_cooldown), `:19-27` (dc fields)
- `README.md:12-28` (the `dc` contract table; `recover`/`recover_ticks`, runtime fields `rb_cd`/`resync`)
- `pack.mcmeta:1-9` (pack_format 81 / supported 48–82 / description C1 8.5)

**Entry / recognition**

- `advancement/using.json:4-17`, `advancement/consume.json:4-8`, `advancement/item_used.json:4-37`, `advancement/inv_change.json:4-9`
- `core/pre_save.mcfunction:2-15`, `core/mark_consumed.mcfunction:2-3`, `core/save_inv.mcfunction:16-35`
- `tick.mcfunction:6-10` (the two timers), `:17` (the recover driver), `:26,37-38` (rod/snapshot/watchdog)
- `core/process_usage_wrapper.mcfunction:11-25`, `core/process_type.mcfunction:2-7`
- `core/finalize_slot.mcfunction:21-32`, `core/sel_slot_cmd.mcfunction:3-13`

**Recovery (the durability recovery proper)**

- `recover/tick.mcfunction:1-17`, `recover/tick_one.mcfunction:4-53`
- `recover/scan.mcfunction:1-19` (design notes), `:20-38` (hotbar), `:40-94` (inventory), `:96-97` (cleanup)
- `recover/slot.mcfunction:1-19`
- `recover/hit.mcfunction:1-22` (state model and lessons), `:24-37` (read damage/interval/countdown), `:39-56` (state machine), `:59-68` (write-back), `:70-71` ("production code does not spam the chat")
- `tools/gen_recover_slots.py:1-24` (generator notes and cursor encoding), `:60-66` (slot name/encoding rules), `:74-78` (two lines per slot)

**Return / landing-spot guard**

- `schedule/infinite.mcfunction:12-27` (the infinite-class cache contract), `schedule/limited.mcfunction:14-50,106-113,116-142`
- `schedule/clear_slot.mcfunction:1-17`
- `restore/do_check_timer.mcfunction:2-18`, `restore/do_restore.mcfunction:6-53`
- `restore/guard.mcfunction:5-20`, `restore/write_at.mcfunction:1-6`, `restore/put_anywhere.mcfunction:1-20,93-99`, `restore/put_slot.mcfunction:1-20`
- `restore/mark_sync.mcfunction:1-16`, `restore/do_depleted.mcfunction:1-2`, `restore/notify_depleted.mcfunction:1-9`
- `restore/do_discard_restore.mcfunction:1-38` (the discard chain reuses the same set of landing-spot rules)

**Configuration / self-check / dependencies**

- `__load__.mcfunction:4-50,61` (scoreboards, `#resync`, `#rb_bag`, `#rod_lock`; `:8-15` explains the old player-level timer is deprecated)
- `data/minecraft/tags/function/load.json`, `data/minecraft/tags/function/tick.json`
- `core/report_ctx_dirty.mcfunction:1-13` (the E201 sentinel; wired to `doom.log:error`)
- `packs/doom.library/data/doom.library/function/api/ensure.mcfunction:1-13`, `api/read.mcfunction:1-7`, `api/cache.mcfunction:1-8`
- `packs/doom.log/README.md:11-15,64-74` (`doom.log:error {code,message}` and the E2xx section; `:74` states it is wired into `recover/tick_one`)

**Tests and tools (not run, source read only)**

- `packs/doom.test/data/doom.test/function/suite/consumable_recover.mcfunction:21-207` (the assertion body: start the timer / rb_cd=9 / a notch per 10 ticks / offhand / inventory / cursor / multiple independent / full bar does not block / full bar stops the timer / no field, no participation)
- `packs/doom.test/data/doom.test/function/lib/recover_pump.mcfunction:1-11` (the synchronous pump), `run_one.mcfunction:30` (the mount point)
- `test/give_recover_heart.mcfunction:1-27`, `test/give_recover_heart_3.mcfunction:1-10` (the timeline expectation the author wrote)
- `test/probe_recover_all.mcfunction:1-35`, `test/probe_recover_state.mcfunction:1-17`, `test/probe_multi_recover*.mcfunction` (the reading criteria)
- `test/ghost_wipe.mcfunction:1-20` (the cleanup fixture)
- `tools/doomtest/lint.mjs:75-90` (the rule table: C4/C5/C6/C12/E2), `:1170-1210` (the measured basis for C4/C5)

**API (unrelated to this chain, for reference)**

- `api/rod_durability.mcfunction:1-12`, `api/rod_durability_add.mcfunction:1-19`, `api/rod_disable.mcfunction:1-13`, `api/rod_enable.mcfunction:1-11`, `api/rod_reel.mcfunction:1-16`, `api/rod_reel_impl.mcfunction:1-7`, `api/rod_casting.mcfunction:1-6`
- `rod/pick.mcfunction:1-20`, `rod/writeback.mcfunction:1-16`, `rod/catch.mcfunction:1-17`, `rod/lock.mcfunction:1-24`, `rod/tick.mcfunction:1-25`, `rod/tick_one.mcfunction:1-26`, `rod/gate.mcfunction:1-22`, `rod/cast.mcfunction:1-7`, `rod/cast_ok.mcfunction:1-6`, `rod/deny.mcfunction:1-27`, `rod/reel.mcfunction:1-7`

**External references (docs in the same repo, background only)**

- `doom.consumable检视报告.md:4` (pack size: 80 functions / 2239 lines), `:81-85` (the health checklist)
- `AGENTS.local.md:11` (the 1.21.6+ vanilla datapack series), `:56-74` (fishing rod interface task status)
- `数据包易错点总结.md` §2.4 (storage pollution / "using a criterion that both reads and writes as a guard", referenced in several places by `recover/*` and `restore/put_slot`)

---

## ⑧ This round's unverified / unimplemented list (an honest declaration)

**Unverified (this round was purely static reading; the game was not started and `doom.test` was not run)**

1. The real-machine timeline ("bar fills up == cooldown ends", the grey overlay duration) comes from the author's comments and probe criteria; not measured this round.
2. Whether `minecraft:use_cooldown`'s cooldown state is preserved when the item is "rebuilt after being eaten" —— the pack neither reads nor writes the cooldown state, so it cannot be judged from the source; **unverified**.
3. Creative-mode behavior (whether vanilla consumes it, whether `consume_item` fires), as well as offline players / death / dimension change, are **unverified**.
4. The actual impact of `rb.item` carrying the `Slot` field into the relay entity is **unverified** (an observation).
5. Whether the two relay entities tag `dc_rb` (`recover/hit`) and `dc_restore_tmp` (`restore/*`) truly never interfere when multiple players run concurrently in the same tick —— it holds by code discipline ("kill before creating, kill when done, executed in tick order"), but it is **not measured**.

**Unimplemented**

1. Armor slots / ender chest / containers / crafting grid do not participate in recovery (there is no related code path at all).
2. There is no "repair the durability of the player's other items" feature —— different semantics from this chain; if that is needed it must be written separately.
3. There is no durability cap check (does not read `max_damage`), no special handling of stacks, no creative-mode split, and no generic filter for "any damaged item".
4. The only user-visible feedback is vanilla's two: the durability bar itself and the `use_cooldown` grey overlay; the pack side **does not spam the chat** (the only exception is the yellow line for the return fallback when "both hand and inventory are occupied", `restore/put_anywhere.mcfunction:96`).
