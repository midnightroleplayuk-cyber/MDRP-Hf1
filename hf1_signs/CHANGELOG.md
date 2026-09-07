# Changelog

## 1.1.0

- Changed database table from `qbox_signs` to `hf1_signs`.
- Changed default sign view distance to `50.0`.
- Added strict identifier-only permissions for Kapper and Hardy.
- Added support for both `identifier.fivem:` and runtime `fivem:` identifiers.
- Reworked sign placement around the hit surface normal.
- Replaced the old 3D box placement preview with a flat 2D surface rectangle.
- Added surface normal persistence to SQL.
- Added surface offset configuration to reduce z-fighting.
- Kept DUI caching, active-DUI cap and throttled rendering/projection logic.
