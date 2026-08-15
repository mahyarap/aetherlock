# Aetherlock Course Handoff

Last updated: 2026-08-13

## Purpose

This repository is being built through an interactive Godot teaching course for two experienced software engineers who are new to game development. The target is a small, polished, 10-15 minute top-down action-adventure in a ruined magical laboratory.

The user asked for gradual lessons, not a complete implementation. Each lesson must:

1. State its goal and explain the relevant Godot/game-development concepts.
2. Give explicit editor instructions, including node names, parents, Inspector values, layers, masks, signals, and script attachment points.
3. Provide only the code required for that lesson, normally as a complete updated script.
4. Explain the important code and scene decisions.
5. Include an exercise, verification checklist, common mistakes, and debugging advice.
6. Stop and wait for the user before continuing.

When the user reports an error, debug their implementation rather than replacing the architecture. Introduce abstractions only after a concrete need appears. Use typed Godot 4 GDScript and composition over inheritance.

## Interaction Pattern

The user normally completes a lesson and says, "check the code and go to the next lesson." At that point:

1. Inspect the Git state and all files changed by the lesson.
2. Validate scene node names, exported references, collision bits, masks, signal connections, and behavior contracts.
3. Run the project headlessly.
4. Correct only verified issues, preserving intentional tuning choices and unrelated user edits.
5. Explain any fixes and then provide exactly one next lesson.

The user asks focused conceptual questions between lessons. Answer those using simple examples before returning to course progression. Recent concepts that needed extra clarification were collision layers/masks, timers, tweens, pivots, death-time processing, navigation polygons, and polygon winding.

## Toolchain and Validation

- Godot version: `4.7.1.stable.official.a13da4feb`
- Renderer: GL Compatibility
- Project: `1280x720`, `canvas_items` stretch
- Main scene: `res://scenes/world/bootstrap.tscn`
- Branch: `master`
- Last committed course state: commit `5e3b7f9`; Lesson 11 is complete.

Use a temporary HOME because the sandbox cannot write the normal Godot editor settings directory:

```bash
HOME=/tmp/aetherlock-godot godot --headless --path . \
  --log-file /tmp/aetherlock-validation.log --quit-after 5
rg -n 'ERROR|WARNING|SCRIPT ERROR|Parser Error|navigation' \
  /tmp/aetherlock-validation.log
git diff --check
```

The latest validation on 2026-08-13 loaded successfully and printed `Bootstrap scene ready` with no logged diagnostics. This proves parsing and initial scene loading, not interactive gameplay behavior.

## Completed Lessons

1. Project setup, Git, Input Map, and Bootstrap scene.
2. Nodes, reusable scenes, exported values, timers, and beacon signals.
3. Eight-direction `CharacterBody2D` movement.
4. Physics collision, layers/masks, and gray-box room.
5. `Camera2D`, CanvasLayer debug UI, and world-space mouse aiming.
6. Player projectile, muzzle, lifetime, and fire cooldown.
7. `HealthComponent`, `Hitbox`, `Hurtbox`, and training dummy.
8. Damage feedback, tweens, pivot-based squash/recoil, and death feedback.
9. Chaser enemy with detection, contact damage, and cooldown.
10. `NavigationRegion2D`, a baked bench hole, and `NavigationAgent2D` path following.
11. Explicit Chaser states: `IDLE`, `CHASE`, `ATTACK`, and `DEAD`.

Lesson 12, Shooter Enemy, is currently in progress and uncommitted.

## Current Architecture

Important scenes:

```text
res://scenes/world/bootstrap.tscn
res://scenes/world/graybox_room.tscn
res://scenes/player/player.tscn
res://scenes/enemies/chaser.tscn
res://scenes/enemies/shooter.tscn          # Lesson 12, uncommitted
res://scenes/combat/projectile.tscn
res://scenes/combat/enemy_projectile.tscn  # Lesson 12, uncommitted
res://scenes/combat/training_dummy.tscn
```

Reusable typed scripts:

```text
HealthComponent.take_damage(amount) -> bool
Hurtbox.receive_damage(amount, hit_direction) -> bool
Hitbox detects Hurtbox areas and emits hit_confirmed
Projectile.initialize(spawn_position, travel_direction)
```

Damage direction is propagated from Hitbox through Hurtbox for visual feedback. Health rejects nonpositive damage and damage after death. Projectiles have separate root collision for World bodies and a child Hitbox for damageable Areas.

The Chaser uses an enum and centralized `_change_state()` rather than a generic state-machine framework. Preserve this concrete approach for now.

## Physics Layers

```text
1: World
2: Player
3: PlayerProjectile
4: EnemyHurtbox
5: PlayerHurtbox
6: Enemy
7: EnemyHitbox
8: EnemyProjectile  # added by uncommitted Lesson 12 work
```

Remember that the numeric serialized bit value differs from the human layer number. For example, layer 8 serializes as `128`.

Key relationships:

```text
Player body:             layer Player, mask World + Enemy
Player Hurtbox:          layer PlayerHurtbox, mask none
Player projectile root:  layer none, mask World
Player projectile Hitbox: layer PlayerProjectile, mask EnemyHurtbox
Enemy body:              layer Enemy, mask World + Player
Enemy Hurtbox:           layer EnemyHurtbox, mask none
Chaser ContactHitbox:    layer EnemyHitbox, mask PlayerHurtbox
Enemy projectile root:   layer none, mask World
Enemy projectile Hitbox: layer EnemyProjectile, mask PlayerHurtbox
```

Use the mental model: layer is what an object advertises itself as; mask is what the detector searches for.

## Navigation Details

`graybox_room.tscn` contains a valid baked `NavigationPolygon` with four polygons around the bench hole. The saved outlines are:

```text
Outer: (180,140) -> (180,580) -> (1100,580) -> (1100,140)
Hole:  (710,340) -> (890,340) -> (890,380) -> (710,380)
```

The hole must have the opposite winding from the outer outline. Earlier course instructions omitted this and initially gave both outlines the same winding. The user correctly raised this problem. Future navigation-polygon instructions must explicitly explain winding before asking the user to draw a hole.

The baked vertices currently use additional clearance, producing a hole approximately from `(700,330)` to `(900,390)` and outer traversable bounds from `(190,150)` to `(1090,570)`.

## Uncommitted Lesson 12 Work

Do not discard or overwrite these edits:

```text
M  project.godot
M  scenes/world/bootstrap.tscn
?? scenes/combat/enemy_projectile.tscn
?? scenes/enemies/shooter.tscn
?? scripts/shooter.gd
?? scripts/shooter.gd.uid
```

The user has implemented most of Lesson 12:

- Added physics layer 8, `EnemyProjectile`.
- Duplicated the projectile scene with speed `325`, orange visual, Hitbox layer 8, and mask `PlayerHurtbox`.
- Created Shooter with body, barrel/muzzle, health, Hurtbox, detection, navigation, cooldown, and state label.
- Implemented `IDLE`, `REPOSITION`, `ATTACK`, and `DEAD` states.
- Instantiated Shooter in Bootstrap at `(300, 200)`.

The next agent should review Lesson 12 interactively before declaring it complete. Static loading currently succeeds, but check these points:

1. Verify approach, retreat, and attack behavior on both sides of the bench.
2. Verify enemy projectiles hit Player, not enemies, and disappear against World.
3. Verify Player projectiles damage Shooter and its death tween completes.
4. Confirm Shooter's `NavigationAgent2D` radius property in the Inspector. The saved scene has `path_return_max_radius = 13.0`, whereas Chaser has `radius = 13.0`; this may mean the wrong Inspector field was edited and needs live/editor verification.
5. In `shooter.gd`, the detection callback contains a commented `#has_navigation_target = false`. `_change_state(State.REPOSITION)` already clears it when entering from Idle, so it is not currently a functional failure, but remove the stale comment or restore the explicit assignment if review shows re-entry issues.
6. Shooter and Chaser are placed close together at `(300,200)` and `(320,240)`. They ignore the Enemy layer, so visual overlap is possible. Move Shooter for clear testing if needed.
7. Code indentation and blank-line formatting in `shooter.gd` and `chaser.gd` are uneven. Do not do a broad refactor, but formatting the touched script after functional validation is reasonable.

Also note that `project.godot` currently contains both `doge` and `dodge` actions bound to Space. `doge` was an old typo that had previously been corrected, but it is present again in the committed project. Nothing currently reads `doge`; remove it through the Input Map during the next appropriate cleanup, preserving `dodge`.

## Next Course Step

First finish and verify Lesson 12. If defects are found, debug the existing Shooter implementation instead of replacing it.

After the user confirms Lesson 12 completion, Lesson 13 should introduce the Patroller:

- Predefined waypoint children or marker references
- `PATROL`, `PURSUE`/`ATTACK`, and `DEAD` behavior
- Detection range plus line-of-sight ray query
- Navigation path following between waypoints and toward Player
- A clear return-to-patrol rule after losing Player
- Existing HealthComponent/Hurtbox damage composition

Explain the concrete need for line of sight: range-only sensing detects Player through the bench/walls, while a ray tests whether World geometry blocks sight. Keep the implementation specific to Patroller; do not build a general AI framework.

## Remaining Roadmap

After Patroller, continue gradually through:

```text
Dodge and invulnerability
Animation
Reusable rooms
Doors and transitions
Hazard
Interaction system
Puzzle
Energy key / locked progression
Boss
HUD
Pause and settings
Checkpoint and saving
Complete title-to-ending loop
Audio
Particles and game-feel polish
Controller support
Debugging/profiling
Export and external playtesting
```

Strict scope remains one player, one projectile weapon, one dodge, three normal enemy types, one boss, four-to-six handcrafted rooms, one hazard, one locked door, one key/upgrade, one puzzle, one checkpoint, basic save data, full keyboard/controller support, menus/HUD, audio, and one packaged desktop build. Do not expand into inventory frameworks, procedural generation, multiplayer, additional weapons, or generic boss/quest systems.

## Git Collaboration

There are two developers. Continue reminding them to:

- Work on separate branches.
- Avoid simultaneous edits to the same `.tscn` file.
- Give scene ownership to one developer per change.
- Commit small runnable increments.
- Merge and test gameplay together.
- Never commit `.godot/` generated cache data.

Do not commit the current Lesson 12 work on the user's behalf unless explicitly asked. Preserve all uncommitted files while reviewing.
