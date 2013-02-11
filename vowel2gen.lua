manifest = function()
  return {
    name = "vowel2gen",
    comment = "各母音に対応する値だけGENをずらす",
    author = "bucchigiri",
    pluginID = "{6c994720-2671-43b8-aa6b-e96405146feb}",
    pluginVersion = "1.0.0.1",
    apiVersion = "3.0.0.1"
  }
end
main = function(processParam, envParam)
  local FlexDlg = {
    FieldType = {
      INTEGER = 0,
      BOOL = 1,
      FLOAT = 2,
      STRING = 3,
      STRING_LIST = 4
    }
  }
  local dump
  dump = function(obj, indent)
    if indent == nil then
      indent = ""
    end
    local msg = ""
    local _exp_0 = type(obj)
    if "string" == _exp_0 then
      return '"' .. obj .. '"'
    elseif "boolean" == _exp_0 then
      return (function()
        if obj then
          return "true"
        else
          return "false"
        end
      end)()
    elseif "number" == _exp_0 then
      return "" .. obj
    elseif "table" == _exp_0 then
      msg = msg .. "{\n"
      for k, v in pairs(obj) do
        msg = msg .. ("    " .. indent .. k .. ": " .. dump(v, "    " .. indent) .. "\n")
      end
      msg = msg .. (indent .. "}")
      return msg
    else
      return "(" .. type(obj) .. ")"
    end
  end
  local openDlg
  openDlg = function(title, param, cfg)
    VSDlgSetDialogTitle(title)
    for i, c in pairs(cfg) do
      VSDlgAddField({
        name = c[3],
        caption = c[1],
        type = FlexDlg.FieldType[c[2]],
        initialVal = param[c[3]]
      })
    end
    if VSDlgDoModal() ~= 1 then
      return nil
    end
    local ret = { }
    for i, c in pairs(cfg) do
      local v = nil
      local _exp_0 = c[2]
      if "INTEGER" == _exp_0 then
        local isOk
        isOk, v = VSDlgGetIntValue(c[3])
      elseif "BOOL" == _exp_0 then
        local isOk
        isOk, v = VSDlgGetBoolValue(c[3])
      elseif "FLOAT" == _exp_0 then
        local isOk
        isOk, v = VSDlgGetFloatValue(c[3])
      else
        local isOk
        isOk, v = VSDlgGetStringValue(c[3])
      end
      ret[c[3]] = v
    end
    return ret
  end
  local eachNotes
  eachNotes = function(beginPosTick, endPosTick, fn)
    VSSeekToBeginNote()
    while 1 do
      local _continue_0 = false
      repeat
        local code, note = VSGetNextNoteEx()
        if code ~= 1 then
          break
        end
        if note.posTick < beginPosTick then
          _continue_0 = true
          break
        end
        if endPosTick <= note.posTick then
          break
        end
        if fn then
          fn(note)
        end
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
  end
  local eachControls
  eachControls = function(beginPosTick, endPosTick, ctrlType, fn)
    VSSeekToBeginControl(ctrlType)
    while 1 do
      local _continue_0 = false
      repeat
        local code, control = VSGetNextControl(ctrlType)
        if code ~= 1 then
          break
        end
        if control.posTick < beginPosTick then
          _continue_0 = true
          break
        end
        if endPosTick <= control.posTick then
          break
        end
        if fn then
          fn(control)
        end
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
  end
  local capture
  capture = function(str, pattern)
    if str == nil then
      return nil
    end
    local ret = { }
    for s in string.gmatch(str, pattern) do
      ret[#ret + 1] = s
    end
    return ret
  end
  local param = {
    addToExisting = 0,
    posOffset = -60,
    genOffset = -10,
    gen_a = -10,
    gen_i = -15,
    gen_M = 25,
    gen_e = 0,
    gen_o = 10,
    gen_default = ""
  }
  local dlgCfg = {
    {
      "add to existing control",
      "BOOL",
      "addToExisting"
    },
    {
      "position offset",
      "INTEGER",
      "posOffset"
    },
    {
      "GEN offset",
      "INTEGER",
      "genOffset"
    },
    {
      "[a] GEN",
      "INTEGER",
      "gen_a"
    },
    {
      "[i] GEN",
      "INTEGER",
      "gen_i"
    },
    {
      "[M] GEN",
      "INTEGER",
      "gen_M"
    },
    {
      "[e] GEN",
      "INTEGER",
      "gen_e"
    },
    {
      "[o] GEN",
      "INTEGER",
      "gen_o"
    },
    {
      "default GEN",
      "STRING",
      "gen_default"
    }
  }
  param = openDlg("test", param, dlgCfg)
  if param == nil then
    return 0
  end
  local posLeft = processParam.beginPosTick + math.min(0, param.posOffset)
  local posRight = processParam.endPosTick + math.max(0, param.posOffset)
  local GENs = { }
  local onControl
  onControl = function(control)
    GENs[control.posTick] = control
  end
  eachControls(posLeft, posRight, "GEN", onControl)
  local genDiff = { }
  local onNote
  onNote = function(note)
    local posTick = note.posTick + param.posOffset
    local posTickEnd = note.posTick + note.durTick
    local p = capture(note.phonemes, "[^ ]+")
    if not p[#p] then
      return 
    end
    local gen = param["gen_" .. p[#p]] or param.gen_default
    if gen ~= "" then
      genDiff[posTick] = gen + param.genOffset
    end
  end
  eachNotes(processParam.beginPosTick, processParam.endPosTick, onNote)
  local isOk, currGen = VSGetControlAt("GEN", posLeft)
  local currGenDiff = param.gen_default
  if currGenDiff == "" then
    currGenDiff = 0
  end
  currGenDiff = currGenDiff + param.genOffset
  for posTick = posLeft, posRight do
    local toInsert = nil
    if genDiff[posTick] then
      currGenDiff = genDiff[posTick]
      toInsert = 1
    end
    if GENs[posTick] then
      currGen = GENs[posTick].value
      VSRemoveControl(GENs[posTick])
      if param.addToExisting ~= 0 then
        toInsert = 1
      end
    end
    if toInsert then
      if param.addToExisting == 0 then
        currGen = 64
      end
      local ctrl = {
        type = "GEN",
        posTick = posTick,
        value = math.max(0, math.min(127, currGen + currGenDiff))
      }
      VSInsertControl(ctrl)
    end
  end
  return 0
end
