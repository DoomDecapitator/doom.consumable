# doom.consumable · A unified "item use" framework

中文: `README.md`

> ⚠️ **Beta notice (read this first)**
>
> This datapack is currently in a **mid-development Beta stage**: both features and formats
> **may keep changing**, and the documentation **is for reference only** — no stability and no
> backward compatibility are guaranteed.
> **Back up your world** before installing or upgrading. If it breaks something, we make no
> promises during the Beta.
>
> You are welcome to try it and give feedback, but please treat it as "something being built",
> not as "a finished product".

---

## What is this?

In one sentence: **give it an item, and it manages the whole process of that item being "used with right-click".**

In the Minecraft you normally play, right-clicking an item just eats it, places it, or shoots it.
Doing that in a datapack yourself means writing a pile of detection logic, and it is easy to miss
edge cases.

This pack turns that into **a ready-made framework**. You don't need to touch this pack's code —
just write a short declaration on your own item (a marker called `dc`) and you automatically get
the whole behavior set: "how many uses are left, when it runs out, what it turns into when it runs out".

These are the actions it manages:

**Eat / drink · place a block · throw · lose one notch of durability per use and repair itself
over time · fishing rod right-click · bow/crossbow/trident shooting · snowball, egg, ender pearl
and XP bottle throwing**

---

## What you can do once it's installed (feature overview)

Below it is described the way a normal player would say it, with no technical terms. Every example
item can be found under `data/doom.consumable/loot_table/items/`.

| What you want to do | What actually happens | Example item file |
|---|---|---|
| **A limited-use consumable** | Say an apple can be eaten 5 times, then turns into a golden apple. The inventory shows a durability bar representing the uses left | `limited_apple.json` |
| **An unlimited-use consumable** | Eat as much as you like, it never runs out. You can set a cost such as "each use deals a bit of damage to yourself" | `infinite_apple.json` |
| **Gone when used up / broken when used up** | Running out has three endings: it simply disappears, it stays in your hand but is locked and can no longer be touched, or it turns back into an ordinary item | `vanish_apple.json` · `disable_apple.json` · `normal_bow.json` |
| **Return something when used up** | When it runs out, you end up holding a different item (say an apple leaves a core) | `remainder_apple.json` |
| **A limited-placement block** | Place it 5 times like a block, and when it runs out it turns back into a pinch of dust. Holding right-click to place repeatedly won't miscount | `limited_glowstone.json` |
| **Something you can throw away** | Dropping the item gets a response, and carries a drop cooldown (60 ticks by default) | `discard_glowstone.json` |
| **A durability bar that repairs itself** | One use costs a notch, and **when you stop and do nothing it fills back up one notch at a time**, like breathing | `recover_heart.json` |
| **Fishing rod right-click interface** | Wire casting / reeling / catching events onto a fishing rod, disable it by player state, or make a button-type item that "reels back in immediately on press" | `test_rod.json` |
| **Charges per shot** | A bow / crossbow / trident only spends a charge when it **actually fires**. It can top up arrows as a side effect (equivalent to infinite arrows), and offers three depletion endings | `limited_bow.json` · `infinite_bow.json` |
| **Crossbow · repeating magazine** | Add a marker to a crossbow and it **reloads automatically** after firing; combined with arrow refunding that is semi-automatic infinite fire | `repeating_crossbow.json` |
| **Charges per throw** | Snowball / egg / ender pearl / XP bottle, one charge per throw | `limited_snowball.json` · `limited_ender_pearl.json` |
| **Block use cooldown** | Add a cooldown to **a block**: while the cooldown is running, right-clicking is turned away, and the block can automatically switch between a "ready / cooling" appearance (using native blocks such as levers and copper bulbs as the carrier) | `api/block_cd_demo` sets it up with one command |

> Some items are inherently consumables that "lose a bit with each use", others are keys that
> "never run out". These two kinds are the most basic branches of this framework, and almost every
> example is made by adding to or changing them.

---

## Who uses this pack

- **Map makers**: give custom items rules like "eaten N times / placed N times / fired N times" without rewriting the detection logic.
- **Other datapack authors**: use this pack as a **library** and just write declarations on your own items.
- **Players who just want to play**: you can also drop it into a world as a gameplay pack and try the example items.

---

## Installation

1. **Prepare two packs.** This pack depends on `doom.library` (required); it is the shared base
   library that provides data reads and writes, and without it this pack cannot run:
   - `doom.consumable` (this pack)
   - `doom.library` (<https://github.com/DoomDecapitator/doom.library>)
   - Optional: `doom.log`. With it installed, the framework's **concurrency self-check sentinel**
     reports an `E201` upwards when it finds a problem; you can play fine without it, those
     notices just have nowhere to go.

2. **Put them in the world's `datapacks` directory.** Both (or all three) packs must be in the **same** directory:

   ```
   <your world>/datapacks/doom.consumable/
   <your world>/datapacks/doom.library/
   ```

   That is, you should see `pack.mcmeta` and `data/` directly inside each pack directory.

3. **Load them in the game.** Enter the world and run `/reload`. `/datapack list` should show these two packs as enabled.

4. **Version requirements.** The declaration in this pack's `pack.mcmeta` is authoritative; currently:

   - `pack_format` = **81**
   - `supported_formats` = **48 ~ 82** (inclusive at both ends)
   - Also `min_format` = `[48, 0]`, `max_format` = `[82, 0]`

   This pack has passed the full regression suite on **Minecraft 1.21.11** (see the next section).
   Before installing on another version, check that your game version falls inside the range above.

---

## Run the tests

This pack ships with an automated regression suite. With `doom.test` installed, run in game:

```
/function doom.test:consumable
```

It reports results suite by suite. Currently that is **9 suites / 175 assertions**, and
**you must read the verdicts by reading the scoreboards `#pass` / `#fail` / `#calls dt.test` directly over RCON** —
the suites report with `tellraw`, which **does not go into the server log**, so watching the log
alone will make you think nothing happened.

> Status: **175/175 green as of 2026-10-12** (measured on 1.21.11).
> The one failure that had been hanging around for a long time was **a defect in the test fixture
> itself** (it tried to create a fishing bobber with a command, and the bobber is an entity that
> currently cannot be `summon`ed), **not a product problem**; the fixture has been changed.

---

## For datapack authors (advanced)

The real technical details **are not in this README** — they have been moved down in full to
**[`docs/技术手册-物品契约与实现.md`](docs/技术手册-物品契约与实现.md)**.

That manual contains: the complete `dc` field contract table, the fishing rod interface's four APIs
and four callback tags, the block cooldown device's fields and hooks, the scoreboards of the shot
chain and the throw chain, and engine facts and pitfalls recorded one by one with their sources.
**If you want to change behavior, that document is authoritative.**

Only the most common few are kept here, so you can get started:

- **Where the declaration goes**: in the item component `minecraft:custom_data.dc`.
- **Two required fields**: `detect` (which detection chain to use: `"consume"` eat / `"place"` place / `"shot"` shoot / `"throw"` throw)
  and `type` (`"limited"` limited uses / `"infinite"` infinite).
- **Uses**: `max_uses` and `current_uses`; together with `max_damage` they display as a durability bar.
- **Depletion handling**: `depleted` takes `"disable"` (lock) / `"vanish"` (disappear) / `"normal"` (turn into an ordinary item); the default is `disable`.
- **Pseudo-durability recovery**: switch on with `recover: 1b`; `recover_ticks` controls how many ticks each notch takes to recover (10 by default).
- **Droppable**: `discardable: 1b`, with the cooldown set by `discard_cooldown` (60 by default).

The fastest way to learn is **to copy an example**: open any `limited_*` / `infinite_*` file under
`data/doom.consumable/loot_table/items/`, change the ids and numbers inside, and you have an item of
your own.

Two more ready-made tools:

- `/function doom.consumable:test/give_rod` —— get a test fishing rod;
- `/function doom.consumable:test/probe_rod` —— print the rod-related scoreboards and bobber state, for checking things on the spot.

---

## What's in the repository

```
pack.mcmeta                     version declaration (authoritative for version support)
README.md                       the one you are reading (newbie-facing)
CHANGELOG.md                    changelog —— the authoritative source for features and versions
docs/
  技术手册-物品契约与实现.md      full technical manual (dc contract / API / engine facts)
  技术档案-方块冷却闸门-20261001.md
  实现链路-RecoveryHeart-20260928.md
data/doom.consumable/
  advancement/                  advancement triggers (entry points of each detection chain)
  function/                     the framework itself
    api/                        public API: fishing rod, block cooldown, drop callbacks…
    block/                      block cooldown device
    core/                       snapshot and dispatch trunk
    recover/                    pseudo-durability recovery
    restore/                    restore landing-spot guard
    rod/                        fishing rod interface
    schedule/                   limited uses and scheduling
    shot/                       shot chain (bow / crossbow / trident)
    throw/                      throw chain (snowball / egg / ender pearl / XP bottle)
    test/                       debug and test-item handout functions
  item_modifier/                item modification (repeating magazine etc.)
  loot_table/items/             all example item definitions
  tags/                         callback tags (third-party mount points) and item/block tags
```

---

## Known limits (an honest account)

- **Beta stage, the format will change.** The `dc` field table above may be adjusted at any time; treat `docs/技术手册-物品契约与实现.md` as authoritative.
- **Block interaction has no "before use" hook.** The block cooldown gate can only do "cooldown check + callback";
  the block's own behavior (chest opened, button pressed) has already happened. To make it "not respond at all"
  is not possible at the datapack level.
- **Arrow refunding fails silently when the inventory is full** — it does not raise an error.
- The fishing rod has one edge case: when the bobber is cast into an **unloaded chunk**, the ownership
  tag lands on nothing, which may produce a one-off phantom "reel in immediately after casting"
  (a real player at normal view distance won't encounter it).

---

## License

See `LICENSE` in the repository root.
