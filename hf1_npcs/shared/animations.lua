-- User-friendly NPC activities. Most admins should only need this list.
-- `scenario` entries use GTA scenarios (including props where appropriate).
-- `anim` entries use a known animation dictionary/name pair.
ActivityPresets = {
    { label = 'None / Stand Normally', value = 'none', type = 'none' },

    -- Useful work / service poses
    { label = 'Clipboard', value = 'clipboard', type = 'scenario', scenario = 'WORLD_HUMAN_CLIPBOARD' },
    { label = 'Guard / Security Stand', value = 'guard', type = 'scenario', scenario = 'WORLD_HUMAN_GUARD_STAND' },
    { label = 'Police Idle', value = 'cop_idle', type = 'scenario', scenario = 'WORLD_HUMAN_COP_IDLES' },
    { label = 'Janitor / Sweeping', value = 'janitor', type = 'scenario', scenario = 'WORLD_HUMAN_JANITOR' },
    { label = 'Gardener', value = 'gardener', type = 'scenario', scenario = 'WORLD_HUMAN_GARDENER_PLANT' },
    { label = 'Hammering / Working', value = 'hammering', type = 'scenario', scenario = 'WORLD_HUMAN_HAMMERING' },
    { label = 'Welding', value = 'welding', type = 'scenario', scenario = 'WORLD_HUMAN_WELDING' },

    -- Everyday props / actions
    { label = 'Coffee', value = 'coffee', type = 'scenario', scenario = 'WORLD_HUMAN_AA_COFFEE' },
    { label = 'Drink', value = 'drink', type = 'scenario', scenario = 'WORLD_HUMAN_DRINKING' },
    { label = 'Smoking', value = 'smoking', type = 'scenario', scenario = 'WORLD_HUMAN_SMOKING' },
    { label = 'Phone', value = 'phone', type = 'scenario', scenario = 'WORLD_HUMAN_STAND_MOBILE' },
    { label = 'Tourist Map', value = 'tourist_map', type = 'scenario', scenario = 'WORLD_HUMAN_TOURIST_MAP' },
    { label = 'Binoculars', value = 'binoculars', type = 'scenario', scenario = 'WORLD_HUMAN_BINOCULARS' },
    { label = 'Camera / Paparazzi', value = 'paparazzi', type = 'scenario', scenario = 'WORLD_HUMAN_PAPARAZZI' },

    -- Idle body language
    { label = 'Arms Crossed', value = 'arms_crossed', type = 'anim', dict = 'amb@world_human_hang_out_street@female_arms_crossed@base', name = 'base', flag = 1 },
    { label = 'Folded Arms (Boss)', value = 'fold_arms', type = 'anim', dict = 'anim@heists@heist_corona@single_team', name = 'single_team_loop_boss', flag = 1 },
    { label = 'Hands On Hips', value = 'hands_hips', type = 'anim', dict = 'amb@world_human_cop_idles@female@base', name = 'base', flag = 1 },
    { label = 'Thinking', value = 'thinking', type = 'anim', dict = 'misscarsteal4@aliens', name = 'rehearsal_base_idle_director', flag = 1 },
    { label = 'Stand Impatient', value = 'impatient', type = 'scenario', scenario = 'WORLD_HUMAN_STAND_IMPATIENT' },
    { label = 'Leaning', value = 'leaning', type = 'scenario', scenario = 'WORLD_HUMAN_LEANING' },

    -- Fitness / miscellaneous
    { label = 'Flex Muscles', value = 'flex', type = 'scenario', scenario = 'WORLD_HUMAN_MUSCLE_FLEX' },
    { label = 'Push Ups', value = 'pushups', type = 'scenario', scenario = 'WORLD_HUMAN_PUSH_UPS' },
    { label = 'Sit Ups', value = 'situps', type = 'scenario', scenario = 'WORLD_HUMAN_SIT_UPS' },
    { label = 'Yoga', value = 'yoga', type = 'scenario', scenario = 'WORLD_HUMAN_YOGA' },

    -- Keeps support for unusual animations without confusing normal users.
    { label = 'Advanced: Custom Animation', value = 'advanced', type = 'advanced' },
}

-- Kept for backwards compatibility with any code that references the old tables.
ScenarioPresets = {
    { label = 'None', value = '' },
}

AnimationPresets = {
    { label = 'None', dict = '', name = '', flag = 1 },
}
