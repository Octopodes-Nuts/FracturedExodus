# FracturedExodus — Design Doc

Status: draft, first pass. Sections marked **[NEEDS INPUT]** are things only Isaiah knows and aren't inferable from the code — everything else here was pulled from what's actually implemented, so it may not match the original intent. Correct anything that's wrong rather than working around it.

## 1. Premise & Setting

Alt-history WWI, 1914. Three factions:

- **Entente** — Rifleman, Chasseur, Medic, Lieutenant
- **Empire** — Fusilier, Jaeger, Sanitäter, Leutnant
- **Free Agents** — Recruit, Sharpshooter, Bulwark, Captain

**The story:** An alien species, **the Fractured** — technologically and geopolitically similar to modern humanity — is fleeing their dying homeworld (cause deliberately left unclear). They're called the Fractured for three reasons, all true at once: their world was fractured (whatever destroyed it), their society was politically fractured (mirroring humanity's own great-power rivalries — part of why they read as a dark mirror of the humans fighting over their wreckage), and they arrive in fractured ships — the exodus fleet reaches Earth already broken up, which is *why* scout ships are landing and crash-landing all over the world individually rather than arriving as one force. They arrive without knowledge of humanity, and don't initially recognize humans as necessarily intelligent. The warring human powers (Entente, Empire) become interested in the recovered alien technology — hypothesized to be fission-cell power tech — purely for wartime advantage over each other, not first-contact reasons. The US, not yet in the war in 1914 (accurate to real history — it joined in 1917), wants the tech too but won't commit to a war it isn't part of, so — in a very on-brand piece of US foreign-policy history — it hires mercenaries to retrieve it covertly instead of acting militarily. **Those mercenaries are the Free Agents faction.**

**Likely but unconfirmed connection:** "chips" (the extraction objective, §2) are probably the recovered alien tech/fission-cell salvage itself, given this story — but that wasn't stated explicitly, so treat it as a strong inference to confirm rather than settled.

**Still open:**
- Confirm/deny the chips = alien tech salvage connection above.
- Given this story, is PvE (bots) meant to include hostile aliens (scout-ship security, wildlife, whatever) alongside human NPCs? The story makes that a natural fit, but it hasn't been decided (§2 already had this as open independent of the story reveal).

**Real gap: this story currently has no delivery vehicle in the actual game.** There's no lore text, mission briefing, dialogue, or environmental storytelling anywhere in the codebase (confirmed by search), and gameplay today is pure human-vs-human PvP over an unlabeled "chip" objective — a player experiencing the shipped game wouldn't encounter any of this. The premise is strong on paper (the mechanics-narrative unity around scattered crash sites, the nobody's-the-hero framing), but it needs *some* in-game vessel — chip flavor text, alien wreckage/environmental storytelling at chipsites, hostile alien AI, a mission-select blurb, anything — or it stays something only the designer knows. Not urgent for alpha, but worth deciding intentionally rather than letting it default to "the fiction lives outside the game."

## 2. Core Loop

As implemented today:

1. Players queue via matchmaking, get placed into a match on a dedicated game server instance (docker-hosted, spun up per match).
2. Match runs on a timer (`TimeRemaining`, currently 25 min) — **not currently enforced**, see [alpha_roadmap.md](alpha/alpha_roadmap.md).
3. Players fight each other and AI (`BasicEnemy`, `Wounded`), and interact with the map: `Chipsite` (channel ~10s to extract a "chip"), `res_sphere` (resource node), `ScannerSite`.
4. Players reach an `Extract` zone to leave the match with what they've obtained.
5. When all players have left (`player_count == 0`), `end_match()` fires, kill/death stats convert to XP, and it's broadcast to clients — then currently dropped, see roadmap.

**Permadeath is the core stakes mechanic, and extraction is per-character, not per-match.** Being downed mid-match has no penalty by itself — it's revivable (`down_count`/`res_sphere` already implemented, with a medic required after the first down). The real consequence is failing to extract: if a character doesn't make it out of the match — whether killed and never revived, or the player simply leaves/disconnects before extracting — that character is permanently deleted, forfeiting whatever Level/Devotion progress it had. This explains why extraction is tracked per-character rather than the whole match having a single end state.

This already has real implementation in `Map.gd`: `extracted_character_ids` / `early_leave_character_ids` track each character's status, `notify_player_extracted()` marks a character safe, and `_on_player_left()` calls `matchmaking_api.delete_character_forfeit(character_id)` for anyone who leaves without having extracted. **The gap:** this only fires when a player actually leaves/disconnects — the match timer expiring doesn't currently force anyone out or trigger forfeiture, so a character who's still in the map (dead or alive) when time runs out isn't currently punished. Closing that gap is what "enforce the timer" (alpha roadmap item 1) now specifically means: on timeout, any character that hasn't extracted needs to go through the same forfeit path.

**[NEEDS INPUT]**
- Is a 25-minute match length right, independent of the permadeath question above?
- What do chips *do* mechanically — are they currency, crafting material, or something extraction-related beyond the objective-count they already drive? (Narratively they're likely the alien tech itself, per §1 — unconfirmed.)
- Is PvE (bots) meant to be a core part of the loop, or filler/atmosphere around PvP? (§1's story makes hostile aliens a natural PvE option alongside/instead of human NPCs — still undecided.)

## 3. Factions & Classes

Confirmed in code: 3 factions × 4 classes each (Infantry, Medic, Special, Officer), 12 total playable characters, each with its own movement controller extending a shared `DefaultController`.

**Faction/class identity is meant to come from three things: base class role, weapon/equipment access, and per-level traits.**

**Base class role** (applies across all three factions — Rifleman/Fusilier/Recruit are all "Infantry", etc.):

| Class | Role |
|---|---|
| Medic | Healing (already implemented via `MedPack`/`apply_authoritative_heal`). Deliberately not combat-focused: restricted to `DEFAULT`-tier weapons only (carbines, revolvers) — no full rifles, no shotgun/sword. Meant to be the strongest class ability-wise but at a genuine combat disadvantage against the others, by design, not an oversight. |
| Infantry | All-rounder; carries full-length rifles; specialized for midrange combat |
| Officer | Encourages the team to push — gives a speed buff to nearby allies; carries shotguns and swords; longest-range option is a carbine (deliberately capped below Infantry's full rifles) |
| Special | Long-range specialist; buffed ironsight zoom, but moves slower while aiming down sights as the tradeoff; can equip scoped weapons |

**Corrected — most of this is already implemented**, contrary to what an earlier pass of this doc claimed:

- **Officer speed-buff aura**: `OfficerController.gd` — `speed_buff = 1.1`, `speed_buff_radius = 10.0`, ticks every 0.15s, applies to same-faction allies in range via `officer_speed_buff` on `DefaultController`, consumed in `DefaultControllerMovement.gd`. The officer also matches the fastest nearby ally's effective sprint speed rather than just applying a flat multiplier.
- **Special ADS zoom + movement penalty**: `SpecialController.gd` — `ads_zoom_buff = 1.2` (divides `ads_fov`, i.e. zooms in further) and `ads_movement_penalty = 1.5` (divides movement speed while ADS), both implemented and wired into `DefaultControllerMovement.gd`.
- **Infantry stowed-weapon speed buff**: `InfantryController.gd` — `stowed_speed_buff = 1.15`, applied when the tertiary (melee/light) weapon is the active one. Not mentioned when the role table above was described, but it's there and fits "all-rounder."
- **Medic healing**: implemented via `MedPack`/`apply_authoritative_heal`.

**Still a real gap: scoped weapons specifically.** The zoom *buff* is implemented at the controller level (any weapon Special ADS's with gets the zoom bonus), but there is no "scoped weapon" as a distinct item anywhere — no scope model, no scope-specific `WeaponDefinition` flag, nothing found searching for "scope" across the codebase. Whether that's meant to be a visibly different weapon variant (with a scope attachment/model) or just this existing zoom-on-ADS mechanic applied to specific weapons is still open.

Weapon *category* access per class is enforced via `WeaponDefinition.slots` (a dict keyed by `ClassRegister.Classes`, including a `DEFAULT` key that means "every class," not "no class in particular"). Checked all 11 faction weapons with resource data directly (headless load, not guessing from filenames): full rifles (Lee-Enfield, Gewehr 98, M1873 Repeating Rifle) are slotted to `INFANTRY`+`SPECIAL`; carbines, revolvers/pistols, and the trench knife are all slotted to `DEFAULT` (universal). **No weapon currently has a `MEDIC` or `OFFICER`-specific slot at all.** For Medic that's exactly the intended design above — confirmed, not a gap. For Officer it's a real content gap: the design calls for shotgun + sword access, and neither exists as class-restricted content yet (no shotgun `WeaponDefinition` has an `OFFICER` slot; the sword groundwork in §4 has no data at all).

**Weapon/equipment access** by faction also exists (the `faction` tag on `WeaponDefinition`) — implemented, modulo the roster gaps in §4.

**Per-level traits** per specific class/faction combo (i.e. each of the 12 characters has its own progression of unlockable traits) is **designed but not implemented** — there's a list of what each combo gets at each level, currently living outside the repo. No trait/perk system or data structure for it exists anywhere in code.

**[NEEDS INPUT]**
- The actual trait list (what each of the 12 class/faction combos unlocks at each level) — needed before that system can be scoped or built at all. Bringing it into the repo (even as a rough table) would let this doc stop saying "exists somewhere."
- Numeric targets for the two new class mechanics above: Officer's speed buff (%, radius, duration?) and Special's ADS zoom bonus / movement penalty (%s).
- Which specific weapons in the current/planned roster count as "scoped" for Special, versus the standard sights everyone else uses.

## 4. Weapons

Slot types: `slots` on `WeaponDefinition` map to class (Default/Infantry/Medic/Special/Officer). Weapon categories seen in the file layout: longarms, sidearms, melee.

Current roster (13 faction weapons + 3 faction-agnostic defaults):

| Faction | Longarms | Sidearms | Melee |
|---|---|---|---|
| Entente | Lee-Enfield, Lebel Carbine, Berthier | Webley | Trench Knife |
| Empire | Gewehr 98, Kar98k, Mannlicher M1895* | Reichsrevolver, Mauser* | *(none)* |
| Free Agents | Carbine Repeater, M1873 Repeater | Gusson Sheriff | *(none)* |

\* Mannlicher M1895 and Mauser have 3D models but no `WeaponDefinition` resource — not usable in-game yet.

**Melee, as designed:** every character is standard-issue a knife (free, no Devotion cost, per §5), and Empire/Free Agents will each get more than one melee option beyond that baseline — not just parity with Entente's trench knife. Officers specifically get access to swords, and can affix a bayonet onto their primary weapon instead.

Current code state, now that this is the target:
- No faction has a truly universal free knife yet — Entente's `trenchknife` is faction-specific, not the shared standard-issue item.
- `behavior/player/weapons/melee/default_sword/DefaultSword.gd` already exists and is already scoped to `classes = [ClassRegister.Classes.OFFICER]` — this groundwork predates this conversation. It has no scene (`.tscn`), no `WeaponDefinition` resource, and isn't referenced anywhere else, so it isn't usable yet. `Melee._use()` itself (the shared swing/stab base) is also just an empty stub (`pass` in both branches) — the actual melee-attack mechanic isn't implemented at all yet, independent of content.
- Bayonet-affixed-to-primary-weapon is a new mechanic, not a new weapon slot — nothing like a weapon attachment/modification system exists in `WeaponDefinition` or `Gun.gd` today.

**[NEEDS INPUT]**
- What are the actual Empire and Free Agents melee weapons (names/models), beyond "more than one option each"?
- Damage/recoil/muzzle-velocity balancing — is there a target TTK (time-to-kill) or reference weapon you're balancing around?

## 5. Progression & Economy

Fields exist on `CharacterDef`: `XP`, `Devotion`.

- **XP → Level → Devotion + traits.** XP is earned per match (`XP_PER_KILL=100`, `XP_PER_AI_KILL=25`, `XP_PER_DEATH=10`, computed and delivered to the client already — see roadmap). Leveling up grants Devotion points *and* unlocks that level's trait for the character's specific class/faction combo (see §3 — trait content isn't in the repo yet). `CharacterDef` currently has no `Level` field; it needs one, plus an XP-to-level curve.
- **Devotion is a per-character loadout budget, not a permanent unlock currency.** Each recruited character starts with 10 Devotion points (exact starting number TBD/tunable). Equipping a gun or piece of equipment costs points out of that character's pool; unequipping it refunds the points. Loadouts can be freely rearranged — nothing is "owned" separately from the budget. Leveling up raises the character's total pool (more points to spend across a loadout), it does not unlock specific items.
- **Standard issue is free.** A basic knife and a basic medkit cost 0 Devotion and are always available to every character, regardless of remaining budget. All other guns and equipment cost points.
- No shop, store, or crafting system beyond this loadout-budget mechanic — Devotion is the entire economy for now.

Implementation implications (tracked in [alpha_roadmap.md](alpha/alpha_roadmap.md)):
- `WeaponDefinition` / equipment definitions need a Devotion cost field (0 for standard-issue items).
- `CharacterDef` needs a `Level` field and an XP→level curve; leveling needs to raise `Devotion` (the character's max pool, not a spendable balance that only goes down).
- Loadout selection UI (`WeaponSelect`, `PaperDoll`) needs to enforce the budget: show remaining points, block selections that exceed it, refund on unequip.

**[NEEDS INPUT]** The XP→level curve/thresholds, and how many Devotion points a level-up grants. (Devotion going down on death is moot — per §2, death/failure-to-extract removes the whole character, not a stat on a surviving one.)

## 6. Social & Meta

Implemented: friends list, friend requests, party (leader + members), matchmaking queue with heartbeat. Account system: login, character CRUD (up to 3 character slots inferred from `Weapon1/2/3`), session tokens.

Cross-faction parties are **not allowed** — a party queues as a single faction. Party size cap is **4** — this is the team size (i.e. a full party is a full team, not a subset of a larger team).

**Faction assignment is an open design question, not just an open input.** Today faction is picked freely in the main menu per character (`Local.set_state("selected_faction", ...)`). Under consideration: forcing faction assignment at match load (picked on a prematch/character-select screen) instead of the main menu, so matchmaking can balance factions across the population rather than letting free choice skew it. Deliberately not decided yet — the concern is that with a small player base, anything that constrains or reshuffles who ends up on which side risks starving one faction of players entirely rather than balancing it. Revisit once there's real matchmaking volume data to judge by; don't build alpha in a way that makes this harder to change later.

## 7. Server Architecture (as built)

- Go backend (`FracturedExodusServer`): HTTP + WebSocket transport, single process serving Account API, Matchmaking API, and a `GameServerManager` that builds a docker image and spins up a container per match via `docker run`.
- Postgres-backed account DB and matchmaking DB.
- Game server itself is the same Godot binary running headless (`--headless`, `dedicated_server` feature), registering itself with the matchmaking service via a registration token passed through env vars.
- Client talks to matchmaking/account over WebSocket + HTTP; talks to the per-match game server over ENet (UDP).

**[NEEDS INPUT]** Deployment target — is production meant to run on a single host (current `docker run` model) or should this scale to multiple hosts / a real orchestrator eventually? Not needed for alpha, but worth knowing so the server requirements doc doesn't paint into a corner.

## 8. Open Design Questions (rollup)

Everything marked **[NEEDS INPUT]** above, collected:

1. ~~Setting/fiction~~ — **answered**, see §1: alt-history 1914, an alien species (the Fractured — fractured world, fractured politics, fractured exodus fleet) crash-lands scout ships worldwide mid-WWI; human powers want the tech for the war, the still-neutral US hires the Free Agents as deniable mercenaries to get it covertly. Still open: whether "chips" narratively are the alien tech itself (likely, unconfirmed).
2. ~~Match structure / why individual extraction~~ — **answered**, see §2: permadeath on failure to extract is the stakes mechanic, extraction is per-character for that reason. Still open: whether 25 min is the right match length, and whether there's a win condition beyond extracting successfully.
3. ~~Faction mechanical identity beyond skins~~ — **answered**, see §3: weapon/equipment access (implemented) + per-level traits per class/faction combo (designed, not implemented, list not yet in repo). Still open: whether there's also meant to be a baseline stat difference (health/speed/etc.) between factions/classes, separate from traits.
4. ~~Class mechanical role~~ — **answered and already implemented**: Officer's speed-buff aura (`OfficerController.gd`), Special's ADS zoom/movement-penalty tradeoff (`SpecialController.gd`), Infantry's stowed-weapon speed buff, and Medic's healing all exist in code with real tuning numbers already set (not placeholders — see §3 for the actual values). The one real remaining gap is scoped weapons specifically: the zoom mechanic exists, but no weapon is marked/modeled as "scoped."
5. ~~Empire/Free Agents melee weapons~~ — **answered**, see §4: every character gets a free standard-issue knife, Empire/Free Agents each get more than one melee option beyond that, and Officers get swords or a bayonet affixed to their primary weapon. Still open: the specific weapon names/models, and (new) bayonet attachment is a mechanic that doesn't exist in code yet.
6. Weapon balancing targets.
7. ~~What XP and Devotion are actually for~~ — **answered**, see §5: XP levels a character up, leveling grants Devotion, Devotion is a per-character loadout budget (standard issue free, everything else costs points, freely respent). Still open: the XP→level curve and Devotion-per-level amount.
8. ~~Cross-faction party rules / party size~~ — **answered**: cross-faction not allowed, party queues as one faction; cap is 4, which is also the team size.
9. Long-term deployment target for the server.
10. Whether faction is chosen freely (current behavior) or assigned at match load via a prematch screen (§6) — open on purpose, pending real matchmaking volume to judge the small-playerbase tradeoff.
11. Class balance philosophy — **answered**, see §3: Medic is meant to be the strongest class ability-wise (healing/revival) but deliberately weakest in a straight fight, restricted to carbine/revolver-tier weapons only — confirmed in the actual weapon data, not just intent. The general shape: utility classes trade combat strength for their ability, fun without being strictly worse to play. Officer's current identical weapon restriction is *not* this — it's an unfinished content gap (see roadmap).

Once these are answered this doc should get a rewrite pass rather than staying a patchwork of confirmed/unconfirmed sections.
