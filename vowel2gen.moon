export manifest = ->
	return {
		name: "vowel2gen",
		comment: "各母音に対応する値だけGENをずらす",
		author: "bucchigiri",
		pluginID: "{6c994720-2671-43b8-aa6b-e96405146feb}",
		pluginVersion: "1.0.0.1",
		apiVersion: "3.0.0.1"
	}



export main = (processParam, envParam) ->

	FlexDlg = {
		FieldType: {
			INTEGER: 0,
			BOOL: 1,
			FLOAT: 2,
			STRING: 3,
			STRING_LIST: 4
		}
	}

	dump = (obj, indent="") ->
		msg = ""
		switch type(obj)
			when "string"
				return '"'..obj..'"'
			when "boolean"
				return if obj then "true" else "false"
			when "number"
				return ""..obj
			when "table"
				-- might loop infinitely!
				msg ..= "{\n"
				for k, v in pairs obj
					msg ..= "    "..indent..k..": "..dump(v, "    "..indent).."\n"
				msg ..= indent.."}"
				return msg
			else
				return "("..type(obj)..")"
	
	openDlg = (title, param, cfg) ->
		VSDlgSetDialogTitle(title)
		for i, c in pairs cfg
			VSDlgAddField({
				name: c[3],
				caption: c[1],
				type: FlexDlg.FieldType[c[2]],
				initialVal: param[c[3]]
			})
		return nil if VSDlgDoModal() != 1
		ret = {}
		for i, c in pairs cfg
			v = nil
			switch c[2]
				when "INTEGER"
					isOk, v = VSDlgGetIntValue(c[3])
				when "BOOL"
					isOk, v = VSDlgGetBoolValue(c[3])
				when "FLOAT"
					isOk, v = VSDlgGetFloatValue(c[3])
				else
					isOk, v = VSDlgGetStringValue(c[3])
			ret[c[3]] = v
		return ret

	eachNotes = (beginPosTick, endPosTick, fn) ->
		VSSeekToBeginNote()
		while 1
			code, note = VSGetNextNoteEx()
			break if code != 1
			continue if note.posTick < beginPosTick
			break if endPosTick <= note.posTick
			fn(note) if fn

	eachControls = (beginPosTick, endPosTick, ctrlType, fn) ->
		VSSeekToBeginControl(ctrlType)
		while 1
			code, control = VSGetNextControl(ctrlType)
			break if code != 1
			continue if control.posTick < beginPosTick
			break if endPosTick <= control.posTick
			fn(control) if fn

	capture = (str, pattern) ->
		return nil if str == nil
		ret = {}
		for s in string.gmatch(str, pattern)
			ret[#ret+1] = s
		return ret

	param = {
		addToExisting: 0,
		posOffset: -60,
		genOffset: 0,
		gen_a: -10,
		gen_i: -15,
		gen_M: 25,
		gen_e: -10,
		gen_o: 10,
		gen_default: ""
	}

	dlgCfg = {
		{"add to existing control", "BOOL", "addToExisting"},
		{"position offset", "INTEGER", "posOffset"},
		{"GEN offset", "INTEGER", "genOffset"},
		{"[a] GEN", "INTEGER", "gen_a"},
		{"[i] GEN", "INTEGER", "gen_i"},
		{"[M] GEN", "INTEGER", "gen_M"},
		{"[e] GEN", "INTEGER", "gen_e"},
		{"[o] GEN", "INTEGER", "gen_o"},
		{"default GEN", "STRING", "gen_default"}
	}

	param = openDlg("test", param, dlgCfg)
	return 0 if param == nil
	-- VSMessageBox(dump(param), 0)

	--

	posLeft = processParam.beginPosTick + math.min(0, param.posOffset)
	posRight = processParam.endPosTick + math.max(0, param.posOffset)
	GENs = {}
	onControl = (control using GENs) ->
		GENs[control.posTick] = control
	eachControls(posLeft, posRight, "GEN", onControl)

	--

	genDiff = {}
	onNote = (note using param, genDiff) ->
		posTick = note.posTick + param.posOffset
		posTickEnd = note.posTick + note.durTick
		p = capture(note.phonemes, "[^ ]+")
		return if not p[#p]
		gen = param["gen_"..p[#p]] or param.gen_default
		genDiff[posTick] = gen + param.genOffset if gen != ""
	eachNotes(processParam.beginPosTick, processParam.endPosTick, onNote)

	--

	isOk, currGen = VSGetControlAt("GEN", posLeft)
	currGenDiff = param.gen_default
	currGenDiff = 0 if currGenDiff == ""
	currGenDiff += param.genOffset

	for posTick = posLeft, posRight
		toInsert = nil
		if genDiff[posTick]
			currGenDiff = genDiff[posTick]
			toInsert = 1
		if GENs[posTick]
			currGen = GENs[posTick].value
			VSRemoveControl(GENs[posTick])
			toInsert = 1 if param.addToExisting != 0
		if toInsert
			currGen = 64 if param.addToExisting == 0
			ctrl = {
				type: "GEN",
				posTick: posTick,
				value: math.max(0, math.min(127, currGen + currGenDiff))
			}
			VSInsertControl(ctrl)
			-- VSMessageBox(dump(ctrl), 0)

	return 0

