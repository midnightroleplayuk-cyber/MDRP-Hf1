Custom dialogue sounds
======================

1. Put short .ogg files in this folder.
2. Add each file to Config.DialogueSounds in config.lua.
3. Restart hf1_npcs.
4. The sound will appear in the Response sound dropdown when editing a dialogue reply.

Example config entry:
{ label = 'Gang - Deal accepted', value = 'gang_accept.ogg' },

Sounds are played locally only for the player using the NPC. A new response sound stops the previous response sound.
