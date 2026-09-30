# Crafted manor art — Phase17

Source recipes: scripts/environment17/kit.gd, geometry.gd. All geometry is project-authored.
Normal F5 builds a bounded shared kit once; no network, paid asset, tool installation or rebake.
Run tools/export_environment17.gd to save sixteen native .scn scenes into generated/ for Godot editing.
The tool reopens every scene and verifies the mesh/material/GI receiver structure.
These are art-only inspection assets, not new collision/interactable objects. Editing an exported
copy does not silently replace the runtime recipe. The sofa/bed/kitchen models are detail shells
for the existing fixed cores; they are not standalone replacement lightmap receivers. New art
uses existing lightmap probes, not a newly baked indirect map. Original fixed cores remain.
