﻿
/*

Вспомогательные функции для русской адаптации

*/



; конвертируем русские названия модов в их английские варианты
; сохраняем русские названия модов в отдельном параметре
AdpRu_ConvertRuModToEn(_item)
{
;console_log(_item, "_item")	
	For k, imod in _item.mods {
		
		_item.mods[k].name_ru := _item.mods[k].name
		result1 := AdpRu_Ru_En_Stats_Value(_item.mods[k].name)
		_item.mods[k].name := result1.name
		
		; попытаемся сконвертировать оригинальное название мода, 
		; это нужно для модов с числами, например "Имеет 1 гнездо" 
		; - для таких модов в файле должно быть соответствие полному названию с числовыми значениями
		result2 := AdpRu_Ru_En_Stats_Value(_item.mods[k].name_orig)
		_item.mods[k].name_orig_en := result2.name
		
		; если мод не был сконвертирован
		;If (_item.mods[k].name = _item.mods[k].name_ru) {		
		If (not result1.IsName) {		
			; в массиве соответствий названия модов без плюса и минуса перед #, поэтому если они присутствуют, то избавляемся от них
			RegExMatch(_item.mods[k].name, "(.*)([+-]#)(.*)", mod_name)			
			modRu := mod_name1 "#" mod_name3
			result := AdpRu_Ru_En_Stats_Value(modRu)
			modEn := result.name
			; и добавляем после получения английского названия
			_item.mods[k].name := StrReplace(modEn, "#", mod_name2)
		}
	}
;console_log(_item, "_item")
	Return _item
}


; конвертирование для одной строки мода
AdpRu_ConvertRuOneModToEn(smod)
{
	result := AdpRu_Ru_En_Stats_Value(smod)
		
	; если мод не был сконвертирован		
	If (not result.IsName) {		
		; в массиве соответствий названия модов без плюса перед #, поэтому если он присутствует, то избавляемся от него
		RegExMatch(smod, "(.*)([+]#)(.*)", mod_name)			
		modRu := mod_name1 "#" mod_name3

		result := AdpRu_Ru_En_Stats_Value(modRu)
		If (result.IsName) {
			modEn := result.name
			; и добавляем после получения английского названия
			smod := StrReplace(modEn, "#", "+#")
		}
	} Else {
		smod := result.name
	}

;console_log(smod, "smod")

	Return smod
}


;
AdpRu_Ru_En_Stats_Value(smod)
{
	ru_en_stats := Globals.Get("ru_en_stats")
	
	result := {}
	result.name := ""
	result.IsName := ""

	smod_en := ru_en_stats[smod]
	
	If(not smod_en) {
	
		; для случая с константой - имя мода содержит # вместо константы
		res := AdpRu_nameModNumToConst(smod)
		If (res.IsNameRuConst) {
			smod_en := ru_en_stats[res.nameModConst]
		}
		
		; возможно это мод бестиария
		If(not smod_en) {				
			; в массиве соответствий в имени мода бестиария присутствует фраза (Пойманное животное) - добавим её к ру имени мода
			smod_en := ru_en_stats[smod . " (Пойманное животное)"]
			; и удалим из анг. имени мода
			smod_en := RegExReplace(smod_en, " \(Captured Beast\)", "")
		}
		
		If(not smod_en) {	
			;return smod
			result.name := smod
			result.IsName := false
			return result
		}
	}
	
	; избавимся от символа новой строки заменив его на пробел
	; - для случая, когда в файле соответствий в английском названии мода присутствует символ новой строки, т.к. в модах poetrade он отсутствует
	StringReplace, smod_en, smod_en, `n, %A_Space%, All
	
	result.name := smod_en
	result.IsName := true
	
	;return smod_en
	return result
}


;конвертирует русские имена предметов в английский вариант
AdpRu_ConvertRuItemNameToEn(itemRu, currency=false)
{
	Global Item
	
	; совпадает с названием валюты - исключить
	If (not currency and RegExMatch(itemRu, "i)Древняя сфера")) {
		return itemRu
	}
	
	;itemRu_ := Trim(RegExReplace(itemRu, "i)высокого качества", ""))
	itemRu_ := Trim(StrReplace(itemRu, "высокого качества", ""))
	
	/*If (Item.IsMap) {
		; для карты "Вихрь хаоса" имя  будем формировать вручную, т.к. в английском
		; названии карты присутствует символ отсутвующий в ANSI кодировке - "o" с двумя точками вверху
		; соответственно данный символ не сохраняется в файле с ANSI кодировкой
		;If (RegExMatch(itemRu_, "Вихрь хаоса")) 
		IfInString, itemRu_, Вихрь хаоса
		{
			itemEn := "Maelstr" chr(0xF6) "m of Chaos"
			return itemEn
		}
	}
	
	If (Item.IsWeapon and Item.SubType = Mace) {
		; тоже для уникального молота "Мьельнир" 
		IfInString, itemRu_, Мьельнир
		{
			itemEn := "Mj" chr(0xF6) "lner"
			return itemEn
		}
	}
	*/
	
	; обработаем особые случаи предметов с одинаковыми названиями
	sameNameItem  := Globals.Get("sameNameItem")
	itemEn := ""
	If (Item.IsDivinationCard) {
		itemEn := sameNameItem.DivinationCard[itemRu_]
		If (itemEn) {
			return itemEn
		}
	}
	Else If (Item.IsGem) {
		itemEn := sameNameItem.Gem[itemRu_]
		If (itemEn) {
			return itemEn
		}
	}
	Else If (Item.IsUnique or Item.IsRelic) {
		itemEn := sameNameItem.Unique[itemRu_]
		If (itemEn) {
			return itemEn
		}
	}

	; массив соответствий базовых имен предметов на русском языке их английским вариантам
	nameItemRuToEn := Globals.Get("nameItemRuToEn")	
	
	itemEn := ""
	itemEn := nameItemRuToEn[itemRu_]
	
	If (not itemEn) {
		; если соответствия не найдено, возвращаем имя на русском
		; возможно необходимо как-то обрабатывать такой случай - нельзя, в другом коде используется проверка на русские символы
		itemEn := itemRu
	}	
	
	return itemEn
}


; конвертирование полного имени волшебных флаконов в английский вариант
AdpRu_ConvertRuFlaskNameToEn(nameRu, baseNameRu)
{
	ruPrefSufFlask := TradeGlobals.Get("ruPrefSufFlask")
	
	affName := RegExReplace(nameRu, baseNameRu, "")
	
	; извлекаем аффиксы из названий	
	If (RegExMatch(affName, "^([а-яА-ЯёЁ]+) ([а-яА-ЯёЁ ]+)*$", aff_name))
	{		
		pref := Trim(aff_name1)
		suff := Trim(aff_name2)
	} ; только префикс
	Else If (RegExMatch(affName, "([А-ЯЁ][а-яё]+)", aff_name)){
		pref := Trim(aff_name1)
		suff := ""
	} ; только суффикс
	Else If (RegExMatch(affName, "([а-яё]+)", aff_name)){
		pref := ""
		suff := Trim(aff_name1)
	}
	
	nameEn := ""
	nameEn := ruPrefSufFlask[pref] " " AdpRu_ConvertRuItemNameToEn(baseNameRu) " " ruPrefSufFlask[suff]
	
	return nameEn
}


; конвертирует имя мода с # в имя мода с константами
AdpRu_nameModNumToConst(nameMod)
{
	nameModNum  := Globals.Get("nameModNum")
	nameModConst := nameModNum[nameMod]
	
	result := {}
	
	If(not nameModConst)
	{
		result.IsNameRuConst := false
		result.nameModConst := nameMod
		return result
	} 
	result.IsNameRuConst := true
	result.nameModConst := nameModConst
;console_log(nameMod, "nameMod")	
;console_log(nameMod, "nameMod")	
;console_log(result, "result")		

	return result
}


; есть моды с константами идущими первыми в имени мода
; в результате извлечение значения мода работает не корректно
; такие моды необходимо обработать подготовив их к извлечению значения -
; из мода нужно удалить константу заменив её на #
AdpRu_ConverNameModToValue(nameMod, name_ru)
{
	; разбираем адаптированный мод на подстроки	
	RegExMatch(name_ru, "([^\d#]*)([\d#]*)([^\d#]*)([\d#]*)([^\d#]*)([\d#]*)([^\d#]*)", name_ruSub)

	If (name_ruSub2 or name_ruSub4 or name_ruSub6) {
		
		; разбираем оригинальный мод на подстроки
		RegExMatch(nameMod, "(\D*)(\d+)(\D*)(\d+)(\D*)(\d*)(\D*)", nameModSub)

		; если значения равны, значит это константа
		If ((nameModSub2 = name_ruSub2) and nameModSub2) {
			value1 := "#"
		} Else { ; иначе, это величина
			value1 := nameModSub2
		}
		
		If ((nameModSub4 = name_ruSub4) and nameModSub4) {
			value2 := "#"
		} Else { 
			value2 := nameModSub4
		}
		
		; есть моды с двумя константами
		If ((nameModSub6 = name_ruSub6) and nameModSub6) {
			value3 := "#"
		} Else { 
			value3 := nameModSub6
		}
		
		nameMod := nameModSub1 . value1 . nameModSub3 . value2 . nameModSub5 . value3 . nameModSub7
				
		;console_log(nameMod, "CONST")		
	}
	;console_log(nameMod, "nameMod Full")		
	
	return nameMod
}


; На текущий момент в оригинальной версии 2.8.0 нет поддержки уникальных предметов с переменными модами - это
; уникальные предметы состав модов которых не постоянен и зависит от конкретного экземпляра предмета, а не от его типа.
; Алгоритм оригинального скрипта не рассчитан на обработку таких предметов.
; Также присутствует ряд уникальных предметов которые, либо не добавлены в дата-файл скрипта \data_trade\uniques.json, 
; либо в этом файле не корректно прописаны названия модов, хотя в дата-файле \data_trade\mods.json содержащем
; названия модов присутствующих на poe.trade моды названы корректно - отсюда возникают ошибки, либо с полностью недоступным
; расширенным поиском предмета, либо с отсутствующими определенными модами на предмете при расширенном поиске.
; Данная функция позволяет справиться с такими ограничениями путем добавления к запросу необходимых отсутствующих модов взятых с предмета. 
;
; Такие предметы необходимо добавлять в файл \data_trade\ru\uniquesItemModEmpty.txt
AdpRu_AddUniqueVariableMods(uniqueItem)
{
	Global Item, ItemData
	
	tempMods	:= []
	utempMods	:= {}
	
	Affixes	:= StrSplit(ItemData.Affixes, "`n")

	For key, val in Affixes {

		modFound := false
		
		; remove negative sign also			
		t_ru_full := TradeUtils.CleanUp(RegExReplace(val, "i)-?[\d\.]+", "#"))

		; для модов с константами
		t_ru := AdpRu_nameModNumToConst(t_ru_full)
		; если мод с константой
		If (t_ru.IsNameRuConst) {
			t := AdpRu_ConvertRuOneModToEn(t_ru.nameModConst)
		} Else {
			t := AdpRu_ConvertRuOneModToEn(t_ru_full)
		}
		
		; английское имя мода
		nameVarMod := t

		t := TradeUtils.CleanUp(RegExReplace(t, "i)-?[\d\.]+", "#"))
		
		; избавимся от "+" в модах - есть моды у которых "+" расположен в середине
		t := StrReplace(t, "+", "")

		For k, v in uniqueItem.mods {
			
			; воспользуемся подготовленным модом
			n := utempMods[k]

			If (not n){ ; если мод не подготовлен, то подготовим его
				n := TradeUtils.CleanUp(RegExReplace(v.name, "i)-?[\d\.]+", "#"))
				n := TradeUtils.CleanUp(n)

				; избавимся от "+" в модах - есть моды у которых "+" расположен в середине			
				n := StrReplace(n, "+", "")
				
				; сохраним подготовленный мод во временном массиве
				utempMods[k] := n
			}

			; match with optional positive sign to match for example "-7% to cold resist" with "+#% to cold resist"
			RegExMatch(n, "i)(\+?" . t . ")", match)

			If (match) {
				; присутствующие моды пропускаем
				modFound := true
				break				
			} 
		}
		
		If (not modFound) {
			; сформируем запись о моде
			varMod := {}
			; английское имя мода
			varMod.name := nameVarMod
			; добавляем оригинальную строку мода с предмета
			varMod.name_orig_item := val
			; оригинальный диапазон значений будет пустым
			varMod.ranges := []
			; пометим, что мод изменяемый
			varMod.isVariable := true
			; пометим, что моды необходимо отсортировать
			varMod.isSort := true
			
			; добавляем отсутствующие моды
			tempMods.push(varMod)
		}
	}
;console_log(tempMods, "tempMods")	
	; 
	If (tempMods) {
		For key, val in tempMods {
			; добавим мод к списку модов на уникальном предмете
			uniqueItem.mods.push(val)
		}
	}
	
	return uniqueItem
}


; функция инициализации массива имен уникальных предметов:
; - с переменным составом модов
; - с модами которые ещё не добавлены в служебный файл uniques.json оригинального скрипта.
; необходим для функции AdpRu_AddUniqueVariableMods(uniqueItem)
AdpRu_InitUniquesItemModEmpty()
{
	FileRead, uniquesItemModEmpty, %A_ScriptDir%\data_trade\ru\uniquesItemModEmpty.txt
	uniquesItemModEmpty	:= StrSplit(uniquesItemModEmpty, "`r`n")
	
	tmpArr := {}
	
	For k, uIt in uniquesItemModEmpty {
		uIt := Trim(uIt)
		If (uIt) {
			tmpArr[uIt] := true
		}
	}

	TradeGlobals.Set("uniquesItemModEmpty", tmpArr)
}


; инициализация английских названий предметов
AdpRu_InitNameEnItem()
{
	Global Item
	
	; конвертирование полного имени волшебных флаконов
	If (Item.IsFlask and Item.RarityLevel = 2) {
		Item.Name_En := AdpRu_ConvertRuFlaskNameToEn(Item.Name, Item.BaseName)
	}
	Else {
		; сконвертируем по возможности русские названия в английские
		Item.Name_En := AdpRu_ConvertRuItemNameToEn(Item.Name, Item.IsCurrency)
	}
	
	Item.BaseName_En := AdpRu_ConvertRuItemNameToEn(Item.BaseName, Item.IsCurrency)
}

; функция инициализации массива соответствий названий префиксов и суффиксов флаконов
AdpRu_InitRuPrefSufFlask()
{
	FileRead, ruPrefSufFlask, %A_ScriptDir%\data_trade\ru\ruPrefSufFlask.json	
	TradeGlobals.Set("ruPrefSufFlask", JSON.Load(ruPrefSufFlask))
}


; функция инициализации массива соответствий перфиксов и суффиксов в названиях валюты русских вариантов английским
AdpRu_InitBuyoutCurrencyEnToRu()
{
	FileRead, buyoutCurrencyEnToRu, %A_ScriptDir%\data_trade\ru\ruBuyoutCurrency.json	
	TradeGlobals.Set("buyoutCurrencyEnToRu", JSON.Load(buyoutCurrencyEnToRu))
}


; конвертирует название валюты с английского на русский
AdpRu_ConvertBuyoutCurrencyEnToRu(buycurEn)
{
	buyoutCurrencyEnToRu := TradeGlobals.Get("buyoutCurrencyEnToRu")
	buycurRu := buyoutCurrencyEnToRu[ buycurEn ]

	If (buycurRu){
		return buycurRu
	}
	Else {
		return buycurEn
	}
}


; вспомогательная функция полного копирования объекта
; встроенные метод Clone() выполняет только мелкое копирование, т.е. подобъекты копируются не полностью,
; а в виде ссылок
AdpRu_ObjFullyClone(obj)
{
	nobj := obj.Clone()
	For k,v in nobj
		if IsObject(v)
			nobj[k] := A_ThisFunc.(v)
	return nobj
}


; функция вывода значения переменной в отладачную консоль
; var_ - переменная
; name_var - текстовое имя переменной, либо текст который будут выведен в заголовок блока сообщения
; console_log(var_, "var_")
console_log(var_, name_var)
{
	;console.log("############ " name_var " ############")
	;console.log(var_)
	;console.log("##############################")
	console.log("------------- " name_var " -------------")
	console.log(var_)
	console.log("---------------------------------------")
}


AdpRu_InitTimeStart := 0

; функции применяемые при тестировании для оценки производительности
;
; фиксируем текущий момент времени - должна вызываться перед оцениваемым кодом
AdpRu_InitTime()
{
	Global AdpRu_InitTimeStart
	
	;AdpRu_InitTimeStart := A_TickCount
	; количество тактов прошедшее с момента старта компьютера
	DllCall("QueryPerformanceCounter", "Int64*", AdpRu_InitTimeStart)
}


; выводит в отладочную консоль количество тактов прошедшее с момента вызова предыдущей функции
; должна вызываться после оцениваемого кода
AdpRu_ElapsedTime()
{
	Global AdpRu_InitTimeStart
	
	;_A_TickCount_ := A_TickCount
	DllCall("QueryPerformanceCounter", "Int64*", _A_TickCount_)

	elapsed_time := _A_TickCount_ - AdpRu_InitTimeStart
	console_log(elapsed_time, " Прошло тактов: ")
}
