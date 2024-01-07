function parseXmlToAly(xml)
  local xml,s = xml:gsub("</%w+>","}")
  if s == 0 then
    return xml
  end
  xml = xml:gsub("<%?[^<>]+%?>","")
  xml = xml:gsub("xmlns:android=%b\"\"","")
  xml = xml:gsub("%w+:","")
  xml = xml:gsub("\"([^\"]+)\"",function(s)return string.format("\"%s\"",s:match("([^/]+)$")) end)
  xml = xml:gsub("[\t ]+","")
  xml = xml:gsub("\n+","\n")
  xml = xml:gsub("^\n",""):gsub("\n$","")
  xml = xml:gsub("<","{"):gsub("/>","}"):gsub(">",""):gsub("\n",",\n")
  return xml
end

local function sortAlyTablePairs(t)
  local keys = {}
  local stringKeys = {}
  local otherKeys = {}

  -- 将字符键和非字符键分别存储到不同的表中
  for k, _ in pairs(t) do
    if type(k) == "string" then
      table.insert(stringKeys, k)
     else
      table.insert(otherKeys, k)
    end
  end

  -- 对字符键进行排序
  table.sort(stringKeys)

  table.insert(keys, t[1])

  -- 将字符键放在最前面
  for _, k in ipairs(stringKeys) do
    table.insert(keys, k)
  end
  for _, k in ipairs(otherKeys) do
    table.insert(keys, k)
  end

  -- 返回迭代函数
  local i = 0
  return function()
    i = i + 1
    return keys[i], t[keys[i]]
  end
end

function parseAlyToXml(aly,isntroot,deep)
  local aly = aly
  if type(aly) == "string" then
    aly = load("return " .. aly)()
  end

  if type(deep) != "number" then
    deep = 0
  end

  local fucked = false

  local deepStr = string.rep("    ",deep)
  local deepStr2 = string.rep("    ",deep + 1)

  local xml = deepStr .. "<"

  local iclassName = aly[1].getName()

  if String(iclassName).startsWith("android.widget.")
    iclassName = iclassName:match("android.widget.(.+)")
   elseif String(iclassName).startsWith("android.view.")
    iclassName = iclassName:match("android.view.(.+)")
  end

  xml = xml .. iclassName


  if not isntroot then
    xml = xml .. [[ xmlns:android="http://schemas.android.com/apk/res/android"]] .. "\n" ..[[  xmlns:app="http://schemas.android.com/apk/res-auto"]]-- .. "\n"
   else
    -- xml = xml .. "\n"
  end

  if aly.layout_width == nil then
    aly.layout_width = "wrap_content"
  end
  if aly.layout_height == nil then
    aly.layout_height = "wrap_content"
  end

  for k,v in sortAlyTablePairs(aly) do
    --print("    ":rep(deep),k,v)

    local className

    if type(v) == "table"
      -- 麻痹的 就是这货害得我连夜修bug
      if not isntroot and not fucked then
        xml = xml .. ">\n"
        fucked = true
      end
      xml = xml .. parseAlyToXml(v,true,deep + 1)
     elseif type(k) == "string"
      if k == "id"
        xml = xml .. "\n" .. deepStr2 .. "android:id=\"@+id/" .. v .."\""
       elseif k == "app"
        -- 忽略
       else
        xml = xml .. "\n" .. deepStr2 .. "android:" .. k .. "=\"" .. tostring(v) .. "\""
      end
    end
  end

  if isntroot then
    xml = xml .. ">"
  end

  local ret = xml .. "\n" .. deepStr .. "</" .. iclassName .. ">\n"
  return ret
end

return _G
