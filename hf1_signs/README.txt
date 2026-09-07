HF1 Signs - 3D wall-flat rendering fix

The previous implementation used DrawSprite for the sign image.
DrawSprite is camera-facing screen-space rendering, so the image could
appear to move around the player when the camera moved.

This version renders the runtime texture as two world-space triangles
using DrawTexturedPoly. The four vertices are generated from the saved
surface normal and wall basis, so the sign remains flat against the
surface.

Also included:
- client + server HTTPS validation fix
- .png support
- query-string-safe image extension validation
- hf1_signs database table
- 50.0m default view distance
- identifier.fivem allowlist
- existing management/delete UI
- existing performance/DUI limits

Replace the resource files and run:
restart hf1_signs

No full server restart is normally required.

Rendering fix:
- Corrected the DrawTexturedPoly argument order and UVW values so the DUI
  runtime texture is actually sampled by the world-space sign.


DUI loading fix:
- Runtime textures are now created only after IsDuiAvailable reports the
  browser is ready, preventing the silent early-DUI texture race.
- The world-space quad renderer remains in use, so signs stay flat on the
  stored surface.

Latest correction:
- Fixed renderer reference from missing getSignBasis() to the existing
  getSurfaceBasis() helper.
- Kept the world-space DrawTexturedPoly renderer and DUI texture path.
- Kept W=1.0 UVW coordinates.
- Runtime texture is only considered ready when CreateRuntimeTextureFromDuiHandle succeeds.
