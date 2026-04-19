TM = TM or {}
TM.Catalogue = {}

-- Walks Config.Props and returns a flat list of { item, category, catIcon }.
-- Accepts both shapes:
--   categorized: { { category = '...', icon = '...', items = { {label, model, ...}, ... } }, ... }
--   flat:        { { label, model, desc, icon }, ... }    -- legacy
function TM.Catalogue.iter()
    local out = {}
    for _, entry in ipairs(Config.Props or {}) do
        if type(entry.items) == 'table' then
            for _, item in ipairs(entry.items) do
                out[#out + 1] = {
                    item     = item,
                    category = entry.category or 'Misc',
                    catIcon  = entry.icon,
                }
            end
        elseif entry.model then
            out[#out + 1] = {
                item     = entry,
                category = 'Other',
                catIcon  = 'cube',
            }
        end
    end
    return out
end

-- Returns categories in declared order: { { name, icon, items = { ... } }, ... }.
-- Flat / uncategorized entries are bundled under "Other".
function TM.Catalogue.categories()
    local map, order = {}, {}

    local function ensure(name, icon)
        if not map[name] then
            map[name] = { name = name, icon = icon, items = {} }
            order[#order + 1] = name
        end
        return map[name]
    end

    for _, entry in ipairs(Config.Props or {}) do
        if type(entry.items) == 'table' then
            local cat = ensure(entry.category or 'Misc', entry.icon)
            for _, item in ipairs(entry.items) do
                cat.items[#cat.items + 1] = item
            end
        elseif entry.model then
            local cat = ensure('Other', 'cube')
            cat.items[#cat.items + 1] = entry
        end
    end

    local result = {}
    for _, name in ipairs(order) do result[#result + 1] = map[name] end
    return result
end

function TM.Catalogue.count()
    return #TM.Catalogue.iter()
end
