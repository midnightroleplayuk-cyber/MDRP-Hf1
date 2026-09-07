HF1 Signs

Fix included:
- Client and server HTTPS validation now correctly accept valid HTTPS .png URLs.
- URL extension checking ignores query strings/fragments.
- Example URL that is accepted:
  https://iili.io/n32kYbV.png

Other included settings:
- Database table: hf1_signs
- Default view distance: 50.0
- Permissions: only the two configured identifier.fivem IDs
- Flat 2D surface placement with saved surface normals

Installation:
1. Import sql/hf1_signs.sql.
2. Ensure ox_lib, oxmysql and qbx_core before hf1_signs.
3. Restart hf1_signs.

If the resource is already running, restart hf1_signs; a full server restart is not normally required.
