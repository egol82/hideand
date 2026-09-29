# Phase 14 — material families / shader v2

2026-09-29. Branch `phase14/material-shaders`; new entry `scenes/phase14.tscn`.

## Scope

A material-only opt-in extension above Phase13, using its exact weighted body and existing GL Compatibility renderer. No engine migration, new GI, geometry displacement, retopology, new attack rules or paid assets. Previous entry scenes and the generation1 shader remain intact.

| Material | New response | Boundary |
|---|---|---|
| Vinyl character/paws | Broad coated highlight, controlled grazing reflection and restrained lit-side diffusion; body-only rest-UV face/belly value tint | Artistic scattering approximation, not physical subsurface scattering or light transported through a wall |
| Foam weapon | Matte response, small pores and a denser edge/softer face mask on the existing filled contour | Shader normal/value difference only: original outline, bevel, grip, reach and all contact samples unchanged |
| Fabric sleeve/cushion | Periodic warp/weft height and direction, diffuse body with a restrained grazing fiber sheen | Existing geometry/coordinates, not simulated cloth or a new texture atlas |
| Painted wood | Restrained directional grain under the paint and a low coating response | Not a photographic texture pack, random wear, or a new furniture model |
| Plaster / ceramic | Fine matte plaster versus smoother glazed highlights | Same public palette and scene lighting |

The shared shader uses separate per-family roughness/specular/coat/sheen settings, mipmapped periodic data tiles, derivative-filtered detail and a tangent-free surface-gradient normal perturbation. There is no `TIME`-driven movement, `ALPHA`/`EMISSION` output, disabled depth test or screen-texture postprocess. World light/shadow attenuation remains; view-only meshes retain the prior directional-shadow exception while local light attenuation remains enabled.

Tiles are deterministic project-authored 128x128 RGB data textures, generated once and cached under five keys. They are not color images and use no source_color conversion. Body tint uses the existing Phase13 UV coordinates; models and weights are not regenerated or changed. The static cache does not touch gameplay RNG. All material instances belong to their converter; original StandardMaterial3D sources remain immutable.

## In-game comparison

Open the existing Graphics comparison dialog from the menu/pause page. A/B/C meanings stay:
- A: original scene/materials.
- B: original Studio scene finishing with StandardMaterial3D.
- C: custom toy materials. In C choose **Materials I / Materials II** to compare using identical models and lights. II defaults on in the new entry.

Surface microdetail can be disabled independently; this disables fine bump/microdetail, not material identity or broad painted grain. This is a preference, not a measured performance tier. Invalid/out-of-bounds local preferences fall back safely; saved material settings are separate from gameplay saves. No visual option changes physics, hidden-player information, score, clocks or damage.

All world participants, camera paws/weapons, workshop and KO representations receive the applicable material. The new director also watches weapon revision/instance changes: re-equipping refreshes the new world weapon as well as the camera copy. It does not create fresh materials or textures every steady frame. Baseline A and historical entry scenes restore/retain their original materials.

## Files

- `shaders/material14/toy_v2.gdshader`: surface and light response.
- `scripts/material14/microtextures.gd`: shared deterministic mipmapped data textures.
- `scripts/material14/materials.gd`: recipes, independent view/world/role cache.
- `scripts/material14/director.gd`: generation comparison and revision-driven integration.
- `tests/material14/`: state tests, actual GPU pixel tests and reproducible renders.
- `tools/test_material14.py`: exit/error/marker/timeout-checked runner.

## Validation contract

Run `GODOT_BIN=/path/to/godot python tools/test_material14.py --matches`.
Use a display or Xvfb and `--capture` for real GLSL pixel tests, same-light images and a rotating-light material preview. Keep every inherited runner listed in AGENTS.md.

New tests cover six recipe families, immutable sources/cache reuse/data channels, generation/detail switches, seven-map state and collider preservation, eighteen-bone body and skinned preview, world/view separation, actual re-equipping, original samples and fixed0.40 view scale, hidden-body/face visibility and paused controls. The existing94 contact assertions are reused unchanged with a scene selector.

Actual rendered-pixel tests independently check lit output, darkness with all illumination off, complete opaque-wall occlusion, and lower luminance under a real engine shadow. They are small controlled fixtures, not proof of perfect fairness on every map or every GPU. Still/video scenes are automated staging, not manual gameplay. The reaction still uses actual input and swept collision.

## Known limits

This step makes surface response more distinct; it cannot repair underlying character topology, furniture silhouettes or coarse shadow bias. Direct-light wrap is not real SSS. No live LightmapGI, new reflections pipeline or advanced animation is added. Microdetail filtering reduces high-frequency detail at distance but is not a guarantee of zero aliasing on every device. Source-color palette and physical geometry stay, yet human visibility/accessibility/fun/comfort and Windows GPU/audio performance still require separate testing. The same-color swatches are a diagnostic, not a quantitative premium-art certification.

Technical references (official Godot4.4 documentation, implementation verified in4.4.1):
- https://docs.godotengine.org/en/4.4/tutorials/shaders/shader_reference/spatial_shader.html
- https://docs.godotengine.org/en/4.4/tutorials/shaders/shader_reference/shader_functions.html

No competitor content, fonts, engine executables, caches, user saves, telemetry, paid APIs or secrets are included. Existing LICENSE and branches are preserved. Main is not merged automatically.
