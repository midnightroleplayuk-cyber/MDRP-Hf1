# Changelog

## 1.1.0-talk-test
- Added built-in Talk to NPC interaction mode using ox_target + ox_lib context menus.
- Added configurable NPC opening dialogue and up to four player reply buttons.
- Each reply can show an NPC response and optionally trigger a client event.
- Preserved the existing direct client-event interaction as an Advanced mode.
- Dialogue is stored in the existing metadata JSON; no SQL migration required.


## 1.0.1
- Changed Ped Model from free-text entry to a searchable dropdown.
- Typing in the Ped Model dropdown now filters matching catalog labels/model names immediately.
- Preserves existing saved custom model values while editing.

## 1.0.0
- Initial test release.
