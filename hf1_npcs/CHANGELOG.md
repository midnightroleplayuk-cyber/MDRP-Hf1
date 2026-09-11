# 1.2.0 Talk Conditions

- Added per-reply conditions for Qbox groups/grades, ox_inventory items, cash and bank balances.
- Added hidden or locked behaviour for unavailable replies.
- Requirement checks run server-side.
- Smoothed ox_lib dialogue context transitions to reduce ResizeObserver warnings.
- Existing dialogue remains compatible; no SQL migration required.

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

## Talk to NPC v2
- Added branching dialogue with up to 4 extra conversation steps.
- Added reply actions: branch, client event, server event, command, return, and close.
- Added friendly reply-icon selector.
- Existing v1 dialogue remains backwards compatible.
