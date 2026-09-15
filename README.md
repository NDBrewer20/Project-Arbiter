# Project Arbiter

A co-op PvE action game prototype built in Godot 4.7. Players connect to a dedicated server, run around a test level in third person, and fight server controlled enemies together with melee and ranged weapons. Everything is built on a custom low level ENet networking layer instead of Godot's high level multiplayer API.

This README covers what exists right now and how the pieces fit together. See [Status and what's next](#status-and-whats-next) before building on it, because the networking model is due for a ground up rewrite.

## Why raw ENet

Godot ships a high level `MultiplayerAPI` with RPCs, `MultiplayerSpawner`, and `MultiplayerSynchronizer`. This project skips all of that on purpose for two reasons.

- **Learning.** Hand packing packets and routing them yourself makes it obvious what the high level API is doing under the hood, what a byte costs, and where reliability actually matters.
- **Strict server authority.** A dedicated server with no host mode and a clear line between server code and client code is easier to keep honest when every packet is something you wrote and can inspect. Nothing gets synced by magic.

The trade off is that every feature needs its own packet, handler, and spawn path, which is most of the code in `Scripts/Networking/`.

## Tech

| Thing | Value |
| --- | --- |
| Engine | Godot 4.7, Forward+ renderer |
| Physics | Jolt, running on a separate thread |
| Networking | ENet via `ENetConnection` / `ENetPacketPeer` (no `MultiplayerAPI`, no RPCs) |
| Export presets | Windows Desktop, Linux |
| Addons | External Editor Helper (editor shortcuts), Kenney prototype textures |

## Running it

Open the project in Godot 4.7 and run the main scene, which is `Scenes/Levels/Base.tscn`. Every instance boots into the same scene with a small network panel in the corner.

1. In one instance type an IP and port (blank defaults to `127.0.0.1:27015`) and press **Server**. That instance becomes the dedicated server. It does not spawn a player of its own.
2. In other instances (or other machines) enter the same address and press **Client**. Each client gets an ID from the server and spawns a player. Players already connected show up too.
3. On the server, the **Spawn Enemy** and **Remove Enemy** buttons with their amount boxes add and remove enemies. Those get mirrored to every client.
4. **Disconnect** cleanly tears down the client or the server.

There is no host mode. The game is dedicated server only, and that is a permanent decision. The **Host** button in the panel is left over from before host mode was removed and calls a function that no longer exists, so it will error if pressed.

### Controls

| Action | Input |
| --- | --- |
| Move | W A S D |
| Jump | Space |
| Primary fire (tap = light melee, hold = charged heavy melee, hold = ranged fire) | Left mouse |
| Alternative fire (shove, ranged weapons only right now) | Right mouse |
| Toggle cursor / pause input | Escape |
| Quit (debug) | `DEBUG_Quit` action |

A `Player_Swap_Weapon` action exists on **V** but nothing reads it yet. The weapon is set on the player scene's weapon holder.

## How it works

### Authority model

- The **server** owns every enemy. Enemy AI, pathfinding, and death only run where `is_server` is true.
- Each **client** owns its own player. Movement, input, attack states, and hit detection for that player run only on the owning client (`is_authority`).
- Everything else is a dumb replica that gets its transform, velocity, and stats pushed to it.

Every entity carries a `NetworkManager` node. It stores the entity's `assigned_id` and exposes `is_server` and `is_authority` so scripts can early out when they are not in charge.

**This is a trust the client model.** The owning client simulates its own player and tells the server where it is, how fast it is moving, and who it hit for how much. The server takes that at face value, applies it to its own copy, and rebroadcasts it. The only check the server does is that a damage packet's attacker is a connected player. That is fine for a prototype between friends and unacceptable for anything public, which is why the rewrite described at the bottom exists.

### Networking layer

Four autoloads make up the network stack.

| Autoload | Job |
| --- | --- |
| `LowLevelNetworkHandler` | Owns the `ENetConnection`. Polls it every frame, turns ENet events into signals, starts/stops the server or client, tracks connected peers. |
| `ServerNetworkGlobals` | Server only. Keeps the list of peer IDs and broadcasts ID assignment / unassignment when peers come and go. |
| `ClientNetworkGlobals` | Client only. Holds this client's ID and the IDs of every remote player, and emits local/remote assignment signals that the player spawner listens to. |
| `EntityNetworkGlobals` | Shared. Owns the entity ID pool and routes entity related packets (transform, spawn, despawn, stats, damage, stagger) to signals or handlers. |

Packets are plain `PackedByteArray`s. Byte 0 is always the packet type and the rest is hand packed with `encode_u16` / `encode_float` and friends. Each packet class under `Scripts/Networking/Packet_Info/` has a `create(...)` factory, a `create_from_data(...)` decoder, and picks its own ENet flag.

| Packet | Direction | Reliability | Payload |
| --- | --- | --- | --- |
| `ID_ASSIGNMENT` | server -> all | reliable | new peer ID plus the full list of connected peer IDs |
| `ID_UNASSIGNMENT` | server -> all | reliable | peer ID that left |
| `ENTITY_ID_ASSIGNMENT` | server -> all / one | reliable | entity ID, spawn type, spawn position |
| `ENTITY_ID_UNASSIGNMENT` | server -> all | reliable | entity ID to free |
| `ENTITY_TRANSFORM` | authority -> server -> all | unsequenced | position, Y rotation, velocity |
| `ENTITY_STATS` | server -> one | unsequenced | health and power for an entity (sent to late joiners) |
| `ENTITY_DAMAGED` | client -> server -> all | reliable | attacker ID, defender ID, raw damage |
| `STAGGER_ATTEMPT` | client -> server | reliable | attacker ID, defender ID |
| `ENTITY_STATE` | defined, not handled yet | reliable | entity ID plus state name |

### Entity IDs

Players and enemies share one 16 bit ID space managed by `EntityNetworkGlobals`. A peer's ID is also its player entity's ID. The pool exposes a few flavours of claiming an ID because the entity is not always ready when the ID is needed:

- `provision_entity_id(entity)` pops a fresh ID and binds it immediately (server spawning an enemy).
- `preprovision_entity_id()` pops an ID with no entity yet (server reserving an ID for a connecting peer).
- `assign_entity_id(id, entity)` fills in a preprovisioned slot (player spawner).
- `claim_entity_id(id, entity)` / `preclaim_entity_id(id)` force a specific ID out of the pool (clients mirroring what the server told them).
- `reclaim_entity_id(id)` puts an ID back.

If a peer connects and the pool is empty, the server picks a random non player entity, removes it, and hands that ID to the peer.

### Connection flow

1. Peer connects. The server preprovisions an ID, tags the `ENetPacketPeer` with it, and emits `on_peer_connected`.
2. `ServerNetworkGlobals` broadcasts `ID_ASSIGNMENT` with the new ID and the full peer list.
3. Every client receives it. If the client has no ID yet it takes this one as its own and spawns players for every ID in the list. If it already has an ID it just spawns the one new remote player.
4. `LowLevelEntitySpawner` on the server snapshots its active enemies and, on a worker thread, sends the new peer an `ENTITY_ID_ASSIGNMENT` for each one.
5. Every `StatManager` on the server sends the new peer an `ENTITY_STATS` packet so health and power line up.
6. On disconnect the server reclaims the ID and broadcasts `ID_UNASSIGNMENT`. Clients free that player. If it was the local client's own ID, every player gets cleared and the client resets to no ID.

### Spawning

- `LowLevelPlayerSpawner` spawns a player scene whenever an ID is assigned (local or remote) and frees it on unassignment. Non authority players strip their camera gimbal and cursor controller in `_ready`.
- `LowLevelEntitySpawner` is a singleton with a `SPAWNABLE` enum mapping to packed scenes. `server_spawn_entity` instantiates on the server and broadcasts the spawn. Clients instantiate the same scene on receipt and claim the ID. There is currently one spawnable, `ENEMY_DEBUG`.

### Transform sync

`EntityTransformSync` sits on every entity. After each physics frame:

- On the server, the entity's position, Y rotation, and velocity get broadcast to all clients.
- On a client that owns the entity, the same data is sent to the server. The server applies it to its own copy and rebroadcasts.
- Non authority copies apply the rotation and velocity directly, push the velocity into their `VelocityComponent` as an override, and lerp position halfway toward the packet position each update to hide jitter. For players, the horizontal velocity is also written back as the input direction so movement states behave sensibly on replicas.

### Stats and damage

`Stats` is a `Resource` on every entity (through a `StatManager` node). It has base max health, max power, defense, and attack, a `level` from 1 to 7, and per stat `Curve`s that scale the base values by level. `StatBuff` resources can be added and removed to multiply or add to a stat, and recalculation is deferred to the end of the frame so many buffs in one frame only cost one recalculation.

Damage formula:

```
damage_taken = incoming_damage * (attacker.current_attack / max(defender.current_defense, 1))
```

Damage flow when an attack lands:

1. The attacker's hitbox or hitscan finds a `HurtboxComponent` and calls `receive_hit`.
2. The hurtbox applies the damage locally right away, then sends `ENTITY_DAMAGED` to the server (or broadcasts it if it is the server).
3. The server applies the damage to its copy only if the attacker is a connected player, then broadcasts `ENTITY_DAMAGED` to everyone.
4. Every other client applies the damage. The attacker and defender clients skip it because they already did.

When an enemy's health hits zero the server removes it through the entity spawner and everyone despawns it.

### Hitbox system

Physics layers 29 through 32 are reserved: enemy hurtbox, player hurtbox, enemy, player. Hitboxes and hurtboxes set their masks from the owner's `faction` so a player attack only ever collides with enemy hurtboxes and the other way around.

- `HitboxComponent` is an `Area3D` built in code with a damage payload, attacker stats, a lifetime timer, and a shape. Used by melee and shove.
- `HitscanComponent` is a `ShapeCast3D` built in code that lives for one physics frame, casts from the camera toward the crosshair with random spread, then frees itself. Used by ranged attacks and the heavy melee attack.
- `HurtboxComponent` is an `Area3D` on the entity that takes hits and pushes damage into the owner's stats.
- `Hitlog` is a small list so one swing cannot hit the same entity twice.

### State machines

`StateMachine` is a generic node that takes its `State` children by name. States emit `transitioned(self, new_state_name)` to switch. A machine can flag some states as `anim_locked_states`, which the player checks before letting itself rotate toward the camera.

The player runs two machines side by side so it can attack while moving.

**Player movement:** `PlayerIdle` -> `PlayerFloor` -> `PlayerJump` -> `PlayerFalling`.
Jumping has coyote time, a jump buffer, and air control that fades from full to partial over the length of the jump. Gravity is applied as a force inside the jump and falling states.

**Player attacking:** `PlayerAttackIdle` branches on the equipped weapon type.

- Melee, tap: `PlayerMeleeAttack`. Spawns a short lived hitbox at the attack origin partway through a recovery window and bumps the combo counter (the combo position exists but nothing consumes it yet).
- Melee, hold past 0.2 s: `PlayerHeavyMeleeAttack`. Charges the weapon each physics frame. Release or a full charge sends a hitscan from the camera, snaps the player to face the camera, and resets the charge after the frame.
- Ranged, hold: `PlayerRangedAttack`. Fires a hitscan on a timer derived from the weapon's fire rate in rounds per minute, with spread from its accuracy stat.
- Ranged, right click: `PlayerShove`. Spawns a zero damage hitbox centred on the player and sends a `STAGGER_ATTEMPT` to the server for every entity it touched.

Attack states apply a named speed modifier on the `VelocityComponent` while active so the player slows or stops.

**Enemy movement:** `EnemyIdle` -> `EnemyFollow` -> `EnemyFalling` -> `EnemyStagger`.

- `EnemyIdle` picks a random point within its detection radius of where it started and wanders there on a random timer. Any body entering the detection area kicks it into follow.
- `EnemyFollow` chases its target through the nav mesh. If the target leaves the detection area an interest timer starts. When it runs out the enemy picks another nearby body or goes idle.
- `EnemyStagger` is entered by the server when a shove lands. The server adds a force away from the attacker and the enemy sits in stagger until its recovery timer ends.

### Components

- `VelocityComponent` owns a velocity, an acceleration coefficient, a max speed, and a dictionary of named percent modifiers. Movement code asks it to accelerate toward a direction or velocity and then calls `Move(body)`, which hands the velocity to `move_and_slide`. A `velocityOverride` lets the network sync take over.
- `PathfindComponent` wraps a `NavigationAgent3D`. It rate limits target updates with a timer, feeds the agent's next path point into the velocity component, hooks up obstacle avoidance, and teleports the body across nav links after a short delay.
- `CameraBehavior` is on the camera gimbal. It follows the player with an exponential lerp so the camera trails slightly. A pivot under it handles pitch, clamped between looking down and looking up, and a `SpringArm3D` keeps the camera out of walls. The player itself is excluded from the spring arm.
- `PlayerCursor` has three states: default (mouse captured, full control), interacting (mouse free, movement allowed), and pause all (mouse free, no movement). Escape toggles between default and pause all.

### Weapons

Weapons are `Weapon` resources with a type (melee or ranged), a mesh with position and rotation offsets, and a `WeaponStats` resource. `WeaponHolder` on the player loads the mesh and offsets when the weapon is set. `WeaponStats` mirrors the entity stats system with base and current values, a buff list, and a charge meter with `charge_filled` and `charge_changed` signals.

Current weapons under `Resources/Player/Weapons/`:

| Weapon | Type | Attack | Fire rate (RPM) | Range |
| --- | --- | --- | --- | --- |
| Shortsword | melee | 7.5 | 360 | 2.2 |
| Greatsword | melee | 14 | 240 | 3.5 |
| Crossbow | ranged | 10 | 300 | 200 |

### Test level

`Base.tscn` is a flat floor inside a `NavigationRegion3D` with a jump puzzle, a raised platform with a wall and ramp, and a set of slopes at different angles. `NavigationLink3D`s connect the platforms so enemies can chase players up and across them. The level also holds the network UI, the player spawner, and the entity spawner.

## Project layout

```
Assets/         materials and icons
Resources/      stat curves, enemy stats, player stats, weapons and weapon stats
Scenes/
  Levels/       Base.tscn (main scene)
  Prefabs/      player, enemy, weapon, components, network nodes
  UI/           network connect panel
Scripts/
  Entity/       Entity base, components, player, enemy, state machines
  Networking/   ENet handler, autoload globals, packet classes, spawners, network UI
  UI/           crosshair
  Utility/      debug logger, node helpers, physics layer enum
```

## Known gaps

- The **Host** UI button calls `start_host`, which was removed with the rest of host mode. The button should be deleted.
- `Player_Swap_Weapon` is mapped but unused.
- `ENTITY_STATE` packets are defined but neither side handles them, so state machines are not networked yet. Replicas move purely from transform sync.
- Melee `comboPosition` is tracked but no attack reads it.
- There are no animations. Attack timing is driven by timers standing in for animation length.
- Stats only sync on join. Health changes after that come through the damage packets, so anything else that changes stats will drift.
- Enemies have no attack of their own yet.

## Status and what's next

The project has hit a standstill. The systems above work, but the networking model underneath them trusts clients wholesale, and bolting anti-cheat onto that after the fact is not realistic. The plan is a rewrite from the ground up around a server authoritative loop:

1. Clients send **inputs**, not results. Movement input, look direction, attack presses.
2. The server runs the simulation on those inputs and is the only thing that decides positions, hits, and damage.
3. The server sends the **results** back to every client.
4. The owning client runs its own **local prediction** so input still feels instant, then **reconciles** against the server's result and snaps or corrects when it has drifted too far.

Most of the entity, stats, hitbox, state machine, and weapon code is reusable under that model. The packet layer, transform sync, and the damage / stagger flow are the parts that get replaced, since they are all built around the client reporting what it did.

Before the rewrite became the priority, the next steps were finishing the weapon system (swapping, making the combo counter matter, the charge meter in the UI) and getting state machines networked so replicas play the right states instead of inferring everything from velocity.
