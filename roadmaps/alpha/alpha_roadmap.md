# Alpha Roadmap

Goal: **a playable loop for internal testing.** Match start → fight/extract → match end → XP awarded and persisted, on one map. Not aiming for external-tester polish yet — see [design_doc.md](../design_doc.md) for the open design questions this roadmap doesn't try to answer.

Ordered roughly by what blocks what.

## 0. Design inputs needed before or during this work
Blocks item 3 below in particular.
- [ ] Answer the "Open Design Questions" in [design_doc.md](../design_doc.md#8-open-design-questions-rollup), at minimum #2 (match structure) and #7 (what XP/Devotion are for).

## 1. Close the match loop
Currently the match timer counts to zero and does nothing (`Game.gd:32`); the only thing that actually ends a match is every player leaving (`Map.gd: player_count == 0`).

Now that permadeath is confirmed as the design intent (design doc §2): failing to extract is what forfeits a character, and that path is already implemented (`Map.gd`: `extracted_character_ids`, `early_leave_character_ids`, `_on_player_left` → `matchmaking_api.delete_character_forfeit`). It only fires on player leave/disconnect today — timeout doesn't trigger it.
- [ ] On `TimeRemaining` hitting 0, force every still-connected, non-extracted character through the same forfeit path (kick to menu + `delete_character_forfeit`), instead of doing nothing.
- [ ] Confirm `end_match()` / `_broadcast_match_xp()` path is the intended one, now that we know it exists (`Map.gd:303-331`).
- [ ] End-to-end test: get downed and revived (no penalty), get downed and NOT revived before match end (character forfeited), and extract successfully (character survives, keeps XP) — confirm all three produce the right outcome.

## 2. Finish XP persistence
Kill/death tracking already works end-to-end (bullet → shooter_id → `record_kill`/`record_ai_kill` → `kill_stats` → `_compute_xp` → `Local.pending_xp`). It stops there.
- [ ] Add a way to submit earned XP for a character (HTTP or WS message to the account server).
- [ ] Call it once the client is back in the main menu with `pending_xp` set.
- [ ] Persist XP on `characters` table, clear `pending_xp` after ack.
- [ ] Add `CharacterDef.Level` and an XP→level curve (needs the threshold numbers, currently undecided — see design doc §5/§8).
- [ ] On level-up, raise `Devotion` (the character's max loadout budget) by whatever per-level amount gets decided.

## 3. Devotion loadout budget + equipment register
`equipment_register.gd` is an empty dictionary; `CharacterDef.Equipment1/2` have nothing to point at. Devotion is a per-character point pool (10 to start, exact number tunable) spent on guns/equipment for a loadout, refunded on unequip; a basic knife and medkit are always free. See design doc §5.
- [ ] Add a Devotion cost field to `WeaponDefinition` and to equipment definitions (0 for the free standard-issue knife/medkit).
- [ ] Define the minimum viable equipment set for alpha (at minimum whatever `MedPack` already assumes exists, since `DefaultControllerHealth.apply_authoritative_heal` already expects `active_equipable is MedPack`).
- [ ] Wire equipment into the register.
- [ ] Loadout UI (`WeaponSelect`, `PaperDoll`) needs to track remaining Devotion, block over-budget selections, and refund on unequip.

## 4. Weapon roster gaps
- [ ] Add `WeaponDefinition` resources for Mannlicher M1895 and Mauser (models already exist, just missing data — remember to set their Devotion cost too).
- [ ] Implement the actual melee swing/stab mechanic in `Melee._use()` — it's currently an empty stub (`pass` in both branches), independent of any content gap.
- [ ] Ship a universal free knife (standard issue for everyone, 0 Devotion cost) — nothing like this exists yet; Entente's `trenchknife` is faction-specific, not shared.

Everything else in design doc §4/#5 (Empire/Free Agents' additional melee weapons, Officer swords via `DefaultSword.gd` — exists but has no scene/resource/references yet, and bayonet-as-attachment, a mechanic that doesn't exist in code at all) needs actual weapon names/models before it's buildable, and is heavier than the "playable loop" bar requires. Treating as **out of scope for alpha** (added to the list below) unless it turns out to be needed to make any single faction functional at all.

## 5. Server/docker registration fix
Already fixed on `main` (PR #167): dedicated server reads `HOST_GATEWAY_IP` so the containerized game server can reach the matchmaking service on the host instead of resolving to itself. Confirm this still works end-to-end after the XP/equipment changes above, since match-end now needs the game server to report back to matchmaking (`matchmaking_api.match_ended()`).
- [ ] Re-verify server registration + match-ended reporting together in one full match, now that end_match/XP submission are being touched.

## Explicitly out of scope for alpha
(Tracked here so they don't get scope-crept in, not forgotten — revisit post-alpha.)
- Second real map (only `test_map_2` is a real match map today).
- AI variety (only `BasicEnemy` + `Wounded` exist).
- Shop/store/crafting for XP or any other currency.
- Sound pass (only ~21 audio files in the whole project).
- Faction/class level-up trait system (design doc §3 — list not yet in repo).
- Empire/Free Agents' additional melee weapons, Officer swords, bayonet-as-attachment mechanic (design doc §4/#5 — needs actual weapon names/models, and bayonet attachment is an unbuilt mechanic).
- Scoped-weapon variants for Special (design doc §3) — the zoom mechanic itself is already implemented (`SpecialController.gd`); Officer's speed-buff aura and Infantry's stowed-weapon buff are likewise already implemented, so none of those need alpha work.
- Giving Officer its own weapons (shotgun + sword `OFFICER` slots) — verified directly (all 11 faction weapons checked headless): no weapon has an `OFFICER` slot today, so Officer is currently just as `DEFAULT`-restricted as Medic. Unlike Medic, that's a content gap, not the design — Officer's confined-to-carbines state today is only correct by coincidence. Not required for alpha's minimal loop, but don't mistake it for intentional if picked up later.
- Naming-convention cleanup (`WeaponDefinitions.Definitions`, `CharacterDef` PascalCase fields) and other pure code-quality items from earlier review — not blocking, do opportunistically.
