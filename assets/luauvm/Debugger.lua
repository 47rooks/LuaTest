local P = {

}
Debugger = P
 
function Debugger.dumpTable(t)
    --- Dump all the keys and values in the specified table.
    for k in pairs(t) do print(k) end
end
