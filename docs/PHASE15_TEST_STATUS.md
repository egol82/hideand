# Phase 15 — candidate implementation, bake validation pending

Local official Godot4.4.1 restored from the mounted archive and SHA512 verified.
The export produced 326 fixed meshes, 34 unique UV2 unwraps, 167247 vertices, 264192 triangles
and 254 manual probes. The unbaked local candidate passed 100 state/geometry assertions and
an actual entry smoke. This is NOT evidence that the GI bake has completed.

The local container has software OpenGL but no Vulkan driver; actual baking is required in the
branch-scoped GitHub runner. Final status must record that exact bake, asset hash readback,
Windows/Linux engine tests and live render/probe pixel evidence after observing their outputs.
No guessed success, fabricated GI data or image-generation substitution is permitted.
