# Live manor GI assets

The branch-scoped bake workflow builds the fixed manor from the original gameplay geometry,
unwraps UV2 and invokes Godot's actual editor Bake Lightmaps action. The `.scn`, `.lmbake`,
EXR and import metadata are native assets, not screenshots. `manifest.json` records their provenance.

The runtime only replaces matching fixed VISUALS. Original collision/navigation remains.
RoundFurniture, characters, runtime drawings and traces are excluded; they receive probes and
real-time direct shadows. Missing/mismatched data falls back to direct lighting with a visible status.
No engine executable, font, .godot cache or player save belongs here.
