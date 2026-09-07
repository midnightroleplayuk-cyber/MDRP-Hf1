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
