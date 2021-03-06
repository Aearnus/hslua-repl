{-# LANGUAGE QuasiQuotes #-}

module LuaPrelude where

import NeatInterpolation
import Data.Text (unpack, pack, replace, Text)

luaPrelude :: String -> String
luaPrelude homeDir = unpack $ replace (pack "<HOMEDIR>") (pack homeDir) $ [text|
function __replShow(object, depth)
    local maxDepth = 10
    local out = ""
    if (depth < maxDepth) then
        if (type(object) == "nil") then
            out = "nil"
        elseif (type(object) == "string") then
            out = "\"" .. object .. "\""
        elseif (type(object) == "number") then
            out = tostring(object)
        elseif (type(object) == "function") then
            debugData = debug.getinfo(object)
            out = "<" .. debugData.what .. " function>"
        elseif (type(object) == "userdata") then
            out = "<userdata>"
        elseif (type(object) == "table") then
            out = out .. "{\n"
            for k,v in pairs(object) do
                out = out .. string.rep("  ", depth + 1) .. __replShow(k, depth + 1) .. " = " ..  __replShow(v, depth + 1) .. "\n"
            end
            out = out .. string.rep("  ", depth) .. "}"
        end
    else
        out = "... <max print depth> ..."
    end
    return out
end
function __replPrint(object)
    print("=> " .. __replShow(object, 0))
end
function __replGlobalNames()
    local gnames = {}
    for k,v in pairs(_G) do
        gnames[#gnames + 1] = k
        if (type(v) == "table") and (k ~= "_G") and (k ~= "gnames") then
            --todo: actual recursion
            for _k,_v in pairs(v) do
                gnames[#gnames + 1] = k .. "." .. _k
            end
        end
    end
    return gnames
end
function __replErrorHandler(error)
    print(error)
end
function __replPathLocs(loc)
    return ("<HOMEDIR>/.local/hslua-repl-sandbox/" .. loc .. ";/usr/local/" .. loc .. ";")
end
package.path = __replPathLocs("share/lua/5.3/?.lua") .. __replPathLocs("share/lua/5.3/?/init.lua") .. __replPathLocs("lib/lua/5.3/?.lua") .. __replPathLocs("lib/lua/5.3/?/init.lua") .. "./?.lua;./?/init.lua"
package.cpath = __replPathLocs("lib/lua/5.3/?.so") .. __replPathLocs("lib/lua/5.3/loadall.so") .. "./?.so"
__replRequire = require
function require(str)
    local status, result = pcall(__replRequire, str)
    if status then
        print("Successfully loaded package " .. str)
        print("If you want full REPL functionality, please use `:load` and not `require()`.")
        return result
    else
        print(result)
    end
end
|]
