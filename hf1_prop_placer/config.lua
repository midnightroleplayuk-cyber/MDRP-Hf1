Config = {}

Config.Command = 'propadmin'

-- ACE is the recommended permission method.
-- Example server.cfg:
-- add_ace group.admin hf1_prop_placer.admin allow
Config.AcePermission = 'hf1_prop_placer.admin'

-- Optional identifier whitelist. ACE OR a matching identifier grants access.
-- Supports license:, license2:, discord:, fivem:, etc.
Config.AllowedIdentifiers = {
    -- ['license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'] = true,
       ['fivem:1059188'] = true, --HARDY
       ['fivem:17286926'] = true, --KAPPER
}

Config.Streaming = {
    spawnDistance = 180.0,
    despawnDistance = 220.0,
    refreshInterval = 1500,
    modelLoadTimeout = 7000,
}

Config.Placement = {
    maxRayDistance = 100.0,
    moveSpeed = 0.035,
    verticalSpeed = 0.025,
    rotateSpeed = 1.0,
    fastMultiplier = 4.0,
    precisionMultiplier = 0.25,
    markerScale = 0.06,
}

Config.Catalogue = {
    -- The maintained DurtyFree object dump currently contains 21k+ GTA object names.
    -- The server downloads it on resource start and caches it to data/objectlist.txt.
    -- Clients NEVER receive the whole catalogue; they only receive matching search results.
    AutoUpdate = true,
    Url = 'https://raw.githubusercontent.com/DurtyFree/gta-v-data-dumps/master/ObjectList.ini',
    CacheFile = 'data/objectlist.txt',
    MaxResults = 150,
    MinimumSearchLength = 2,
}

-- Category browsing is keyword-based so it automatically works with newly-added GTA props.
Config.PropCategories = {
    { label = 'Vending & Retail', icon = 'fa-solid fa-store', keywords = { 'vend', 'vending', 'shop', 'store', 'retail', 'atm', 'cash', 'till' } },
    { label = 'Furniture & Interior', icon = 'fa-solid fa-couch', keywords = { 'chair', 'sofa', 'couch', 'table', 'desk', 'bed', 'shelf', 'cabinet', 'stool', 'rug', 'wardrobe' } },
    { label = 'Food & Drink', icon = 'fa-solid fa-utensils', keywords = { 'food', 'drink', 'coffee', 'burger', 'pizza', 'bottle', 'cup', 'glass', 'beer', 'fruit', 'kitchen' } },
    { label = 'Medical', icon = 'fa-solid fa-kit-medical', keywords = { 'med', 'hospital', 'surg', 'doctor', 'firstaid', 'stretcher', 'wheelchair', 'pill' } },
    { label = 'Electronics', icon = 'fa-solid fa-tv', keywords = { 'tv', 'monitor', 'computer', 'laptop', 'phone', 'radio', 'speaker', 'screen', 'camera', 'console' } },
    { label = 'Office', icon = 'fa-solid fa-briefcase', keywords = { 'office', 'clipboard', 'paper', 'printer', 'folder', 'document', 'pen', 'desk' } },
    { label = 'Construction', icon = 'fa-solid fa-person-digging', keywords = { 'construction', 'scaf', 'cement', 'brick', 'wood', 'plank', 'tool', 'drill', 'hammer', 'cone' } },
    { label = 'Barriers & Signs', icon = 'fa-solid fa-road-barrier', keywords = { 'barrier', 'bollard', 'sign', 'cone', 'roadblock', 'fence', 'rail' } },
    { label = 'Street & City', icon = 'fa-solid fa-city', keywords = { 'street', 'bench', 'bin', 'trash', 'lamp', 'parking', 'hydrant', 'postbox', 'phonebox', 'busstop' } },
    { label = 'Plants & Nature', icon = 'fa-solid fa-tree', keywords = { 'plant', 'tree', 'bush', 'flower', 'palm', 'rock', 'stone', 'grass' } },
    { label = 'Industrial', icon = 'fa-solid fa-industry', keywords = { 'industrial', 'factory', 'pipe', 'tank', 'generator', 'pallet', 'warehouse', 'machine' } },
    { label = 'Garage & Workshop', icon = 'fa-solid fa-screwdriver-wrench', keywords = { 'garage', 'mechanic', 'tool', 'carjack', 'tyre', 'tire', 'workbench', 'lift' } },
    { label = 'Doors & Gates', icon = 'fa-solid fa-door-open', keywords = { 'door', 'gate', 'shutter', 'garage' } },
    { label = 'Lights', icon = 'fa-solid fa-lightbulb', keywords = { 'light', 'lamp', 'neon', 'spotlight' } },
    { label = 'Containers & Storage', icon = 'fa-solid fa-box', keywords = { 'box', 'crate', 'container', 'case', 'locker', 'storage', 'bin', 'barrel' } },
}

Config.Debug = false
