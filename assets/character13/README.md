# Native character assets

Project-authored connected weighted body and editable rest rig, built by `tools/build_character13.gd`. No downloaded model, font or proprietary asset is used. `buddy_body.res` is a real ArrayMesh with bones/weights; `buddy_rig.scn` contains Skeleton3D/Skin and face/socket attachments. Inspect it in Godot. Runtime adapters remain under scripts/character13.

Regenerate with the standard engine:
`godot --headless --path . --script res://tools/build_character13.gd`

The feature-branch CI asset job saves these exact generated files and source hashes, then verifies that commit. A missing body asset has the same bounded generator as a fallback; it is cached and is never regenerated each frame.
