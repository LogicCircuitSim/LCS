-- Better Version of the Collections.lua library
-- Functions dont return a new table, but instead modify the original table
-- This is to reduce memory usage and improve performance
-- This is a modified version of the Collections.lua library
--

class Collection
    -- Creates a new collection instance
    new: (tbl={}) =>
        @table = tbl

    -- internal functions
    falsyValue:

    tableIsAssociative:


    -- public functions

    all: =>
        tbl = {}
        for k, v in pairs(@table) do tbl[k] = v
        return tbl

    append: (value) =>
        table.insert(@table, value)
        return @table

    average: (key) =>
        count = @count!
        if count > 0 then
            return @sum!(key) / count

    count: =>
        i = 0
        for k in pairs(@table) do i += 1
        return i

    -- chunk

    clone: =>
        cloned = {}
        for k, v in pairs(@table) do cloned[k] = v
        return @new(cloned)

    -- collapse

    -- combine

    contains: (containValue, recursive) =>
        checkContains = (key, value) ->
            if type(containValue) == "function" then
                result = containValue(key, value)
                if result then return true
            else
                if value == containValue then return true
            return false

        for k, v in pairs(@table) do
            if type(v) == "table" and recursive then
                for innerK, innerV in pairs(v) do
                    if checkContains(innerK, innerV) then return true
            else
                if checkContains(k, v) then return true
        return false

    convertToIndexed:

    diff:

    diffKeys:

    each:

    eachi:

    equals:

    every:

    except:

    filter:

    first:

    forget:

    get:

    groupBy:

    has:

    implode:

    insert:

    intersect:

    isEmpty:

    isNotEmpty:

    keys:

    last:

    map:

    mapWithKeys:

    max:

    median:

    merge:

    min:

    -- https://en.wikipedia.org/wiki/Mode_(statistics)
    mode:

    nth:

    -- inverse of except
    only:

    partition:

    pipe:

    pluck:

    pop:

    prepend:

    -- Mutates the original table
    pull:

    push:

    put:

    random:

    reduce:

    -- alias for forget
    remove:

    reject:

    -- alias for splice
    replace:

    resort:

    reverse:

    search:

    -- alias for put
    set:

    shift:

    shuffle:

    slice:

    sort:

    sortDesc:

    -- Mutates the original table
    splice:

    split: -- same as chunk?

    sum:

    take: -- same as slice? swap them for sanity :P

    