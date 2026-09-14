HF1PropCatalogue = {}

local models = {}
local modelSet = {}
local sourceLabel = 'bundled fallback'
local lastUpdate = 0

local function trim(value)
    if type(value) ~= 'string' then return '' end
    return value:match('^%s*(.-)%s*$') or ''
end

local function parseCatalogue(raw)
    local parsed, seen = {}, {}
    if type(raw) ~= 'string' then return parsed end

    for line in raw:gmatch('[^\r\n]+') do
        local model = trim(line)
        -- ObjectList.ini is one model per line. Ignore comments/empty junk defensively.
        if model ~= '' and model:sub(1, 1) ~= '#' and model:sub(1, 1) ~= ';' then
            local key = model:lower()
            if not seen[key] then
                seen[key] = true
                parsed[#parsed + 1] = model
            end
        end
    end

    table.sort(parsed, function(a, b) return a:lower() < b:lower() end)
    return parsed
end

local function installCatalogue(parsed, label)
    if not parsed or #parsed == 0 then return false end
    models = parsed
    modelSet = {}
    for i = 1, #models do
        modelSet[models[i]:lower()] = true
    end
    sourceLabel = label or sourceLabel
    lastUpdate = os.time()
    print(('[hf1_props] Prop catalogue ready: %d models (%s)'):format(#models, sourceLabel))
    return true
end

local function loadCachedCatalogue()
    local raw = LoadResourceFile(GetCurrentResourceName(), Config.Catalogue.CacheFile)
    if not raw or raw == '' then return false end
    local parsed = parseCatalogue(raw)
    if #parsed == 0 then return false end
    return installCatalogue(parsed, (#parsed >= 1000) and 'cached full catalogue' or 'bundled fallback')
end

local function refreshFromWeb()
    if not Config.Catalogue.AutoUpdate then return end
    local url = Config.Catalogue.Url
    if not url or url == '' then return end

    PerformHttpRequest(url, function(statusCode, body)
        if statusCode ~= 200 or type(body) ~= 'string' or #body < 1000 then
            print(('[hf1_props] Catalogue update skipped (HTTP %s). Using %d cached models.'):format(statusCode or 'unknown', #models))
            return
        end

        local parsed = parseCatalogue(body)
        if #parsed < 1000 then
            print(('[hf1_props] Catalogue update returned only %d models; keeping current cache.'):format(#parsed))
            return
        end

        installCatalogue(parsed, 'DurtyFree ObjectList.ini')
        local ok = SaveResourceFile(GetCurrentResourceName(), Config.Catalogue.CacheFile, body, #body)
        if ok == false then
            print('[hf1_props] Warning: could not write catalogue cache file; current session still has the full list.')
        end
    end, 'GET', '', { ['User-Agent'] = 'hf1_props/1.0' })
end

local function categoryMatches(modelLower, categoryIndex)
    if not categoryIndex then return true end
    local category = Config.PropCategories[tonumber(categoryIndex)]
    if not category then return true end

    for i = 1, #category.keywords do
        local keyword = tostring(category.keywords[i]):lower()
        if modelLower:find(keyword, 1, true) then
            return true
        end
    end
    return false
end

function HF1PropCatalogue.Search(query, categoryIndex)
    query = trim(query):lower()
    local maxResults = math.max(20, tonumber(Config.Catalogue.MaxResults) or 150)
    local result, total = {}, 0

    for i = 1, #models do
        local model = models[i]
        local lower = model:lower()
        if categoryMatches(lower, categoryIndex) and (query == '' or lower:find(query, 1, true)) then
            total = total + 1
            if #result < maxResults then
                result[#result + 1] = model
            end
        end
    end

    return {
        items = result,
        total = total,
        truncated = total > #result,
        catalogueSize = #models,
        source = sourceLabel,
    }
end

function HF1PropCatalogue.Contains(model)
    return modelSet[tostring(model or ''):lower()] == true
end

function HF1PropCatalogue.GetStatus()
    return {
        count = #models,
        source = sourceLabel,
        lastUpdate = lastUpdate,
    }
end

CreateThread(function()
    loadCachedCatalogue()
    Wait(1000)
    refreshFromWeb()
end)
