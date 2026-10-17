# Changelog · doom.consumable

中文: `CHANGELOG.md`

> **Scope**: namespace `doom.consumable` (a unified "item use" framework: consume / place / discard / pseudo-durability recovery / fishing rod right-click / shooting / throwing).
> `pack_format` 81, `supported_formats` 48–82, with `min_format` / `max_format` written out explicitly (mandatory fields since 1.21.11).
> Depends on `doom.library` (optionally `doom.log`).
> Automated regression = `doom.test:consumable` (**9 suites / 175 assertions**, reported suite by suite);
> the verdict **must** be read by reading the scoreboards `#pass/#fail/#calls dt.test` directly over RCON (the suites report with `tellraw`, which **does not go into the server log**).
>
> ✅ **175/175 green as of 2026-10-12**. The one failure that had been hanging around for a long time was **a fixture defect**, now fixed (see B3).

---

## 2026-10-16 · v0.1.0-beta.3 — attribution and link tidy-up (repack, no behaviour change)

**No behaviour change in this release**: all 212 files under `data/`, all 9 suites and 175 assertions are untouched.

### 🧹 Dependency link in the packaged `README.md` now uses the new account

**Symptom**: the line pointing at `doom.library` inside the packaged `README.md` still carried the old username
(after the GitHub rename, bare repo links 301-redirect, but `github.com/<old-name>` profile URLs 404).

**Fix**: that link now points at `Doom-Flare/doom.library`.

### 📦 Repack

`doom.consumable-v0.1.0-beta.3.zip` rebuilt per the release rules (216 entries, 216/216 byte-identical to the pack body),
sha256 recomputed. The copyright line in `LICENSE` stays as-is by convention.

---

## 2026-10-13 · v0.1.0-beta.2 —— new offline static gate + fix for a macro-line defect

### 🟢 B5 —— the last tellraw in `api/block_cd_config` is missing the `$` prefix

**Symptom**: after running `function doom.consumable:api/block_cd_config {tag:"…",seconds:30,…}`,
the `$(tag)` / `$(seconds)` in the receipt are **printed literally as-is**, not showing the actual parameters.

**Root cause**: that line is a macro line (L18–L22 of the same function all use the `$` prefix), but the
last `tellraw` alone is missing the `$` ⇒ Brigadier does no macro substitution. **Does not affect loading**
(it is not a load-time error), only the receipt text is wrong.

**Fix**: add the `$` prefix to that line.

### 🟢 New `.github/` offline static gate (CI)

Three Node scripts + one GitHub Actions workflow, under 2s locally, no Minecraft needed:

| Script | What it checks |
|---|---|
| `check_leak.mjs` | Leak scan (local absolute paths / dev-artifact markers) + repository top-level whitelist |
| `check_pack.mjs` | every `.json` parses + every `.mcfunction` is line-wise legal + function reference closure |
| `check_dist.mjs` | the `dist/` zip is **byte-for-byte identical** to the working tree + sha256 matches `SHA256SUMS.txt` + the manifest covers everything |

The gate rules are calibrated against **real-machine measurements** (not copied from a template):

- `~-N` / `~-0.5` are **legal**; only `~+N` is rejected by Brigadier (`Expected double`) ⇒ the rule narrows to `/~\+\d/`
- the **leading indentation** of a `\` end-of-line continuation is layout, and legal ⇒ the two-space rule now tests `line.trim()`
- `#$(tag)` is a macro tag selector, not an end-of-line comment ⇒ the `#` stripping character class gains `$`
- cross-pack references (`doom.library` / `doom.log`) cannot be resolved in this repo ⇒ add an `EXTERNAL` allowlist

### 🟢 Repository hygiene

- added `.gitignore` (local artifact whitelist) and `.gitattributes` (`* -text`: the pack body contains 2 CRLF files,
  which must be preserved as-is, otherwise the zip is no longer byte-for-byte identical)
- corrected `pack.mcmeta`'s description from `8.5` to `8.6`

---

## 2026-10-12 · bobber fixture fix + mcmeta field completion (regression all green)

### 🔴 B3 —— case G's fixture changed to a real cast (it had been reporting a false failure all along)

**Symptom**: assertion 1 of `consumable_rod` case G, "precondition: bobber has spawned", **always fails**;
the suite of 16 assertions permanently carries 1 red; the other 8 suites are all green.

**Root cause**: the fixture created the bobber with `summon minecraft:fishing_bobber`. But in this version the bobber is a **`noSummon` entity**,
and **no summon path exists at all**:

| Approach | Result |
|---|---|
| `summon minecraft:fishing_bobber` | `Can't summon entity of type minecraft:fishing_bobber` |
| `execute summon minecraft:fishing_bobber` | same as above |
| Scarpet `spawn('fishing_bobber', …)` | `= null` |
| control `minecraft:arrow` / snowball / ender pearl / egg | all succeed |

⇒ it is not a parameter problem, not a position problem, not a venue problem — **it is a rejection at the entity-type level**.
(The earlier documentation wrote the cause as "an entity summoned standalone on a headless server disappears after the same tick" —
that is a different known behavior, not the reason here. The 1.21.6 "fix" was a coincidence; the 2-seconds-then-vanish rule only applies to summonable entities.)

**Fix**: the fixture now uses **the only legal source —— a real cast**, and splits the G section into two beats:

- beat one `doom.test:suite/consumable_rod_cast`: `player <name> use` really casts, then `schedule … 2t`
- beat two `doom.test:suite/consumable_rod_deny[_at]`: three assertions + suite teardown

**Why split into two beats**: the bobber produced by a real cast **only becomes readable on the 2nd tick** (measured: it does not exist at t+1t, exists from t+2t),
while the existing suite convention of `doom.test` is **synchronous execution, no waiting for ticks**.

**Two measured constraints**:

- Carpet's `/player` **only accepts name literals**; `@s` / `@p` / `@e[…]` all give `Expected whitespace to end one argument`.
  It **can** be called inside a function body, provided that line itself is in an `execute as <player>` context.
- `rod/tick` tops up `dc_rod_seen` on every bobber every tick, so "cast this tick" can only be simulated by **first `tag … remove dc_rod_seen`**.

**Result**: `consumable_rod` **16/16**, whole suite **175/175**.

### 🔴 B4 —— `pack.mcmeta` gains `min_format` / `max_format` (mandatory fields since 1.21.11)

**Symptom**: on `/reload` every pack spams an ERROR, while **the pack still loads and the functions still run**:

```
Couldn't load file/doom.consumable pack metadata: Pack declares support for version
newer than 81, but is missing mandatory fields min_format and max_format
```

**Root cause**: this pack (and a batch of doom packs from the same period) wrote `supported_formats: {min_inclusive: 48, max_inclusive: 82}`.
`max_inclusive` declares up to **82**, which is newer than 1.21.11's **81**, so the game requires the two new fields
`min_format` / `max_format` to be written **as well**.

**Fix**: add `"min_format": [48, 0]` and `"max_format": [82, 0]`, **without changing a single character of the declared range**.

**Real-machine evidence** (same 1.21.11 machine, `reload` each variant then read the log):

| Form | Result |
|---|---|
| `pack_format` only | no error |
| `supported_formats{48,82}` (no min/max) | **ERROR** |
| `supported_formats{48,82}` + `min_format[48,0]` + `max_format[82,0]` | no error |
| `supported_formats{48,81}` (no overflow) | no error |
| only `min_format[48,0]` / `max_format[81,0]`, no `supported_formats` | **a different ERROR**: `Pack declares support for format 48, but game versions supporting formats 17 to 81 require a supported_formats field` |

⇒ **both field groups must be present**: the old fields (`supported_formats`) for old versions to read, the new fields (`min_format` / `max_format`) for new versions to read.
**Writing only the new fields leaves old versions unable to read the supported range.**

### 🟡 Two regression-tool blind spots fixed along the way (not inside the pack, in `_work/consumable-work/`)

1. **The load-error criterion missed class 9.** The old regex had only 8 classes and did not include `Couldn't load … pack metadata`,
   so B4-style cases ("pack runs but errors") **always scored 0 hits in the verdict**; previous "8 classes of load errors = 0" were **false negatives**.
2. **The log slice used the wrong unit.** The offset came from `statSync().size` (**bytes**), but the slice used the
   **code-unit index** of `readFileSync(f,'utf8')`; when the log contains Chinese the two differ by the order of 1.3 KB, so the slice position was entirely off — that is the **other half of the reason** the above class of errors could not be read.
   Correct form: `readFileSync(f).subarray(offset).toString('utf8')`.

### Suite case count correction

`consumable_shot` measures **55** (the docs previously said 51), whole suite totals **175** (previously written 171).

---

## 2026-10-05 · P0-1 throw chain + P0-2 repeating magazine + regression suite

### 🔴 B1 —— user-visible behavior fix (**the offhand shot chain was completely broken**)

**Symptom**: when the main hand does not hold a `detect:"shot"` weapon and only the **offhand** does, shooting has **no reaction at all** ——
no charge spent, no write-back, no error, **silent failure** (from the player's view "this bow is broken / does nothing").

**Root cause**: `ctx.shot.main` is a boolean payload (`1b` = main hand / `0b` = offhand), but **15 places across 5 files** wrote
`if data storage doom.consumable:ctx shot.main` —— that is an **existence** test, and that key **is always one of 1b or 0b**
⇒ the condition **is always true** ⇒ the `unless` (offhand) branch is **dead code**.

| File | Places |
|---|---|
| `shot/process_one.mcfunction` | 2 |
| `shot/writeback.mcfunction` | 4 |
| `shot/depleted.mcfunction` | 2 |
| `shot/depleted_disable.mcfunction` | 4 |
| `shot/depleted_normal.mcfunction` | 4 |

**Fix**: switch to a **value test** `shot{main:1b}` (`1b` takes `if`, `0b` takes `unless`).
**Real-machine evidence**: before the fix offhand `current_uses = 5` (unchanged) → after the fix `= 4` (correctly spending a charge and writing it back to the offhand).
**Found by**: case **K1** of the newly added `consumable_shot` suite.
⇒ **this bug had zero assertion coverage before; without a suite it could never be found** (and it is silent, so only an assertion can catch it).

### 🟡 B2 —— `ctx.shot` residue cleanup (hygiene, not functional)

A tick with no shot taken leaves `doom.consumable:ctx.shot = {main:1b}` resident in the shared storage.
**No functional impact currently** (`tick_one` rewrites it before dispatch every tick), but `ctx` is a **cross-pack shared** namespace,
and the residue misleads other people's diagnostics; and once another entry point is added to `process_one` it would become a real bug.
**Fix**: `shot/tick_one` unconditionally runs `data remove … shot` at the end (idempotent).
**Found by**: suite cases A2 / B2 / D2.

### 🟢 New feature A —— `detect:"throw"`: throwable consumption chain (P0-1)

Supports the four vanilla throwables **snowball / egg / ender pearl / XP bottle**, with field semantics **exactly the same** as `detect:"shot"`.

- **Event source = vanilla statistic criteria** `minecraft.used:minecraft.{snowball,egg,ender_pearl,experience_bottle}`.
  > ★ **A measurement correction to a circulating belief**: it was thought that "vanilla **has no** `used:snowball` and an event source must be built by hand" —— **that does not hold**.
  > Three real-machine proofs: ① `scoreboard objectives add … minecraft.used:minecraft.snowball` **creates successfully**;
  > ② a fake player holding a snowball pressing 5 times ⇒ scoreboard **5**, inventory 16→11 (**it really counts**);
  > ③ control group `minecraft:stick` pressed 3 times ⇒ **0** (proving it is **specific to throw semantics**, not a generalized right-click counter).
  > ⇒ throwables can **reuse the structure of the shot chain directly**, with no entity detection / advancement variant needed.
  > (Ragecraft IV's `@e[type=snowball]` + tag dispatch is for **projectiles the map summons itself** ——
  > those snowballs do not pass through a player throw and naturally have no stat; it is a different problem from "charging a player's throw".)
- **Cross-version check (measured 2026-10-05)**: all four criteria are **all creatable** on **1.21.5 / 1.21.9 / 1.21.11 / 26.3** ✓
- Added: `function/throw/` (11 files) · callback tag `#doom.consumable:on_throw`
  · examples `loot_table/items/{limited,infinite}_snowball.json` · `limited_ender_pearl.json`
- ⚠️ a throwable **is removed from the hand by vanilla as soon as it is thrown** (the last one simply disappears) ⇒ `depleted_disable`/`depleted_normal`
  gained a guard at the top for "the dc item is still in hand", preventing the relay entity from **conjuring a throwable out of thin air**.

### 🟢 New feature B —— `dc.mag`: repeating magazine / infinite crossbow (P0-2)

Add `mag:1b` to a crossbow ⇒ it **auto-reloads** after firing; combined with `arrow_refund` topping up inventory arrows = semi-automatic infinite fire.

- **Implementation**: `item modify` + `item_modifier/shot_recharge.json`.
  Because the written value is a **constant** (`charged_projectiles:[1 arrow]`), it can **modify the player's held item directly**,
  with **no** `item_display` relay entity needed (unlike `writeback`: the value must be computed at runtime, so it can only go through a relay entity).
- ⚠️ **Pitfall reminder (already written into the code comments)**: `item modify entity @s $(slot) …` **does not load**
  (`Unknown slot '$(slot)'`) —— the slot parameter is a **parse-time literal**, and macro substitution happens after it.
  **It is not analogous to `item replace`** (the latter can take macros). The slot is now hardcoded per main/off branch.
- **Boundaries (asserted)**: a crossbow without `mag` **is not** reloaded; a `limited` crossbow's **depleting shot** is not reloaded.
- Example: `loot_table/items/repeating_crossbow.json` (with its own `cooldown_group`, to avoid cooling down every crossbow together).

### 🟢 New feature C —— `consumable_shot` regression suite (55 assertions, previously **zero coverage**)

Covers: each of the three weapons spending a charge and writing back · a same-tick stat jump spending only one charge · the three depletion modes ·
`infinite`/`limited` × `arrow_refund` · **reverse gates** (the bow's stat does not drive the crossbow, the egg's stat does not drive the snowball) ·
offhand fallback · the repeating magazine (including two reverse gates) · each of the four throwables' event sources · two callback mount points · `ctx` residue hygiene.

### 🟢 Other

- `README.md` gains §5 (shot chain and throw chain); the contract table gains `detect:"shot"/"throw"`, `arrow_refund`, `mag`.
- `__load__.mcfunction` gains 8 objectives (4 criteria + 4 prev); `tick.mcfunction` mounts `throw/tick`.

---

## 2026-10-01 · block cooldown gate

- Block-level use cooldown (`api/block_cd_*`): a marker device attached to the block, with its configuration and expiry tick stored on it (survives reload / restart).
- appearance swap in the cooling state: switch between native blocks that have a boolean state (lever `powered` / copper bulb `lit` …).
- 41 assertions all green (core 14 + extension 12 + visual 15). Technical dossier: `docs/技术档案-方块冷却闸门-20261001.md`.

## 2026-09-30 ~ 10-01 · fishing rod interface redesign + bow extension

- Fishing rod right-click interface (`dc.rod`): four APIs + gate + state machine + button mode + borrow/return chain redone.
  Real-machine E2E **11/11**; three-rod catch matrix **3/3**; 5 fake players casting at the same tick isolation **21/21**.
- Bow/crossbow/trident shot chain (`dc.detect:"shot"`): stat-difference event source + charge spending/write-back/three depletion modes + `arrow_refund`.
  **No assertion coverage at the time** (this round's `consumable_shot` added it, and caught B1 through it).

## 2026-09-27 · restore landing-spot guard + recovery bar state following the item

- `restore/guard` + `put_anywhere`: check occupancy before the restore write —— fixes "**frequently switching item use swallows items**".
- The pseudo-durability bar's timing state moved from **player score** to **following the item itself** (`dc.rb_cd`) ——
  fixes "when two are carried at once the bars cross-talk / jump".
- First version of the fishing rod interface (`dc.rod`).

## 2026-09-20 ~ 09-26 · place chain timing + disable semantics

- `core/snapshot_hand` snapshot priority: fixes "**holding right-click to place continuously loses one item each time**" (it read the hand after consumption rather than before).
- Corrected the **order** of clearing the hand and writing the cache in the depletion branch: fixes "**after depletion the item does not disappear, the durability bar is stuck at 1/5, and it can be eaten infinitely**".
- The "as dead as possible" semantics of the three `disable` item classes (consume / place / other) each finalized.
