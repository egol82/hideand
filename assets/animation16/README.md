# Native animation preview

The shared native AnimationLibrary is generated from scripts/animation16/clips.gd at runtime, once.
Run tools/export_animation16.gd in Godot to write generated/toy_motion.tres and generated/buddy_motion.scn for editor inspection. The tool reloads and tests the native library against the original18-bone rig. Normal game startup needs no export.

Only in-place bone tracks are exported. The live game combines them with actual weapon/floor IK, contact clocks and hiding visibility. The preview does not simulate those gameplay systems. Generator source is authoritative; manual edits to an exported copy are not automatically imported into gameplay.
