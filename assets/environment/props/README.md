# Industrial environment atlases

These transparent atlases bring the small environment objects and bridge
modules up to the detail level of `assets/station/structures_atlas.png`.

## `industrial_props_atlas.png`

Four columns by two rows, in this order:

1. closed crate
2. open crate
3. stacked crates
4. barrel
5. pallets
6. electrical cabinet
7. security barricade
8. cable spool

The atlas is consumed by `scripts/environment_props.gd`. Every cell is kept
isolated on transparent RGBA so props can participate in the game's Y sorting.

## `industrial_bridge_atlas.png`

Two-by-two composition containing a vertical footbridge, horizontal
footbridge, maintenance pier and closed security gate. Tight source regions
are declared in `scripts/world.gd`, which leaves the original generated file
untouched.

Both atlases were generated from `assets/station/structures_atlas.png` as the
strict visual reference: detailed retro pixel art, weathered teal steel, warm
brass trim, hard pixels, moss and localized shadows. No terrain, UI, text or
opaque canvas is part of either asset.
