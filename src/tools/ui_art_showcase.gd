extends SceneTree

## Real native UI fixtures, both locales/themes, without player save writes.
var _checks := 0
var _failed := 0
var _capture := false
var _folder := "res://implementation/shots/sprites/0018/ui/"
var _room: Control
var _icons: Array[TextureRect] = []


func _initialize() -> void:
	call_deferred("_run")


func expect(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		push_error(message)


func _run() -> void:
	CaptureSize.configure(root)
	var args := OS.get_cmdline_user_args()
	_capture = not args.has("--check")
	for arg in args:
		if arg.begins_with("--out="):
			_folder = "res://" + arg.substr(6).trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_folder))
	root.size = Vector2i(480,270)
	root.content_scale_size = Vector2i(480,270)
	await process_frame
	var locale := I18n.locale()
	var contrast := UiKit.high_contrast()
	var state := State.create(18018)
	var original := var_to_bytes(state)
	for speaking in I18n.LOCALES:
		I18n.use(speaking)
		for high in [false,true]:
			UiKit.set_high_contrast(high)
			_new_room()
			await _inventory(speaking,high)
			await _families(speaking,high)
			_new_room()
			await _surfaces(speaking,high)
			await _hud(speaking,high)
			await _menus(speaking,high)
			expect(var_to_bytes(state)==original,"UI observers preserve complete core/save bytes")
	if is_instance_valid(_room):
		_room.free()
	I18n.use(locale)
	UiKit.set_high_contrast(contrast)
	print("UI ART SHOWCASE: %d checks, %d failed" % [_checks,_failed])
	quit(1 if _failed else 0)


func _new_room() -> void:
	if is_instance_valid(_room):
		_room.free()
	_room = Control.new()
	_room.size = Vector2(480,270)
	_room.theme = UiKit.theme()
	_room.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(_room)
	var ground := ColorRect.new()
	ground.color = PaletteData.COLOURS[&"night"]
	ground.size = _room.size
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_room.add_child(ground)
	_icons.clear()


func _label(text: String, at: Vector2, role: StringName = &"") -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.theme_type_variation = role
	_room.add_child(label)
	return label


func _icon(id: StringName, compact: bool, at: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = UiKit.icon(id,compact)
	image.modulate = PlaceholderArt.art_tint(StringName(("hud_%s" if compact else "icon_%s") % id))
	image.position = at
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP
	image.size = Vector2(10,10) if compact else Vector2(16,16)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_room.add_child(image)
	_icons.append(image)
	return image


func _inventory(speaking: String, high: bool) -> void:
	# Six rows fit the native viewport. Additional packet resources need
	# another fixture page so captured pixels remain inside the image.
	for first in range(0, GameData.RESOURCES.size(), 24):
		_new_room()
		await _inventory_page(speaking, high, GameData.RESOURCES.slice(first, first + 24), first / 24)


func _inventory_page(speaking: String, high: bool, ids: Array, page: int) -> void:
	_label("%d resources / native 16px + HUD 10px / " % GameData.RESOURCES.size() + speaking,Vector2(12,5),UiKit.WARM)
	expect(UiKit.missing_icons().is_empty() and UiKit.orphan_icons().is_empty(),"Every actual core resource has an icon and none is orphaned")
	for i in ids.size():
		var id: StringName = ids[i]
		var at := Vector2(12+(i%4)*116,25+(i/4)*39)
		var name := Names.of(id)
		expect(UiKit.font().get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x<=112,"Localized resource name fits its actual fixture column: "+name)
		_label(name,at,UiKit.WARM)
		_icon(id,false,at+Vector2(2,11))
		_icon(id,true,at+Vector2(25,14))
		_label("999",at+Vector2(42,14))
	await _check_icons("icons_%d_" % page+speaking+("_contrast" if high else ""))


## **The packs' icon families** (task 0147 on): each icon at 16 and at 10,
## the pack's own file and never a stand-in, pixel for pixel on the night.
## A005: the hotbar's defences, then the night bar's pictures. A010: the
## seasons, then the night marks. A019: every tool at every tier (task 0202).
## A020: the six materials of the forge, the woods and the barn (task 0203).
## A029: the animals' goods (task 0211). A015 and A016: spring's and
## summer's produce and seed packets (tasks 0198 and 0199). A022: the sixteen
## fish, then their book portraits at 32 (task 0205). A032: the artisan goods
## and the bread (task 0214).
## A011: the forecast's heads, which are 16x16 only (task 0162).
func _families(speaking: String, high: bool) -> void:
	var tools: Array = []
	for tool in GameData.sorted_names(GameData.TOOLS.keys()):
		for tier in (GameData.TOOLS[tool] as Array).size():
			tools.append(ToolTiers.item(tool, tier))
	# A005's eight defences, not every one since 0224: the decoy is A037's,
	# which since 0236 brings the bait's kit.
	var families := {"A005": [&"auto_crossbow", &"barricade", &"fence", &"flame_tower",
			&"gun_tower", &"mine", &"mortar", &"wall"] + NightHud.ICONS,
		"A010": CalendarMark.MARKS, "A019": tools,
		"A020": [GameData.COPPER, GameData.GOLD, GameData.COAL, GameData.HARDWOOD,
			GameData.HAY, GameData.STRAW],
		"A029": [GameData.EGG, GameData.MILK, GameData.WOOL, GameData.TRUFFLE],
		"A015": [GameData.POTATO, GameData.GARLIC, GameData.STRAWBERRY, GameData.CARROT_SEED,
			GameData.POTATO_SEED, GameData.GARLIC_SEED, GameData.STRAWBERRY_SEED],
		"A016": [GameData.PEPPER, GameData.SUNFLOWER, GameData.MELON, GameData.CORN_SEED,
			GameData.PEPPER_SEED, GameData.SUNFLOWER_SEED, GameData.MELON_SEED],
		"A022": GameData.sorted_names(GameData.FISH_SPECIES.keys()),
		"A037": [&"zombie_bait"],
		"A032": [GameData.WINE, GameData.JUICE, GameData.JELLY, GameData.PICKLES, GameData.CHEESE,
			GameData.BUTTER, GameData.CLOTH, GameData.SANDBAG, GameData.FLOUR, GameData.SUGAR,
			GameData.BREAD]}
	for pack in families:
		_new_room()
		var ids: Array = families[pack]
		_label("%s / %d icons / native 16px + HUD 10px / %s" % [pack, ids.size(), speaking],
			Vector2(12,5), UiKit.WARM)
		for i in ids.size():
			var at := Vector2(12+(i%12)*38,30+(i/12)*44)
			_picture(StringName("icon_%s" % ids[i]),at)
			_picture(StringName("hud_%s" % ids[i]),at+Vector2(3,24))
		await _check_icons("family_%s_" % pack+speaking+("_contrast" if high else ""))
	_new_room()
	var fish: Array = GameData.sorted_names(GameData.FISH_SPECIES.keys())
	_label("A022 / %d book portraits / native 32px / %s" % [fish.size(), speaking],
		Vector2(12,5), UiKit.WARM)
	for i in fish.size():
		_picture(StringName("portrait_%s" % fish[i]), Vector2(12+(i%8)*56,30+(i/8)*44))
	await _check_icons("family_A022_portraits_"+speaking+("_contrast" if high else ""))
	_new_room()
	var kinds: Array = [&"walker", &"runner", &"tank", &"breaker", &"giant"]
	_label("A011 / %d forecast heads / native 16px / %s" % [kinds.size(), speaking],
		Vector2(12,5), UiKit.WARM)
	for i in kinds.size():
		_picture(StringName("head_%s" % kinds[i]),Vector2(12+i*38,30))
	await _check_icons("family_A011_"+speaking+("_contrast" if high else ""))


## A pack's picture by its runtime name, at its native size: a `hud_` cut is
## 10x10, a book `portrait_` 32x32, anything else 16x16.
func _picture(name: StringName, at: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = UiKit.picture(name)
	image.position = at
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP
	image.size = Vector2(10,10) if String(name).begins_with("hud_") \
		else (Vector2(32,32) if String(name).begins_with("portrait_") else Vector2(16,16))
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_room.add_child(image)
	_icons.append(image)
	expect(image.texture!=null and image.texture.resource_path=="res://sprites/ui/%s.png" % name
		and PlaceholderArt.art(name).is_empty(),"The pack's own file draws, not a stand-in: "+String(name))
	return image


## Every icon of the room: it loads, at its native size, with the imported
## file's exact pixels - and, captured, those pixels on the screen.
func _check_icons(shot: String) -> void:
	for image in _icons:
		expect(image.texture!=null,"Every full and compact icon loads")
		if image.texture==null:
			continue
		expect(image.texture.get_size()==image.size,"Native UI never resizes an inventory icon")
		var source := Image.load_from_file(ProjectSettings.globalize_path(image.texture.resource_path))
		expect(image.texture.get_image().get_data()==source.get_data(),"Imported source pixels are exact")
	await _shoot(shot)
	if _capture:
		var actual := root.get_texture().get_image()
		for image in _icons:
			var source := image.texture.get_image()
			var visible := 0
			for y in source.get_height():
				for x in source.get_width():
					var pixel := source.get_pixel(x,y)
					if pixel.a<0.5:
						continue
					visible += 1
					var at := Vector2i(image.global_position)+Vector2i(x,y)
					var drawn := actual.get_pixelv(at)
					var target := pixel * image.modulate
					var exact := drawn.is_equal_approx(target)
					if image.modulate != Color.WHITE:
						# Tint multiplication is rounded into the viewport's RGBA8.
						exact = absf(drawn.r - target.r) <= 1.0 / 255.0 \
							and absf(drawn.g - target.g) <= 1.0 / 255.0 \
							and absf(drawn.b - target.b) <= 1.0 / 255.0 \
							and is_equal_approx(drawn.a, target.a)
					expect(exact,"Actual native inventory pixel survives both themes: "+image.texture.resource_path)
			expect(visible>0,"Icon has visible native pixels")


func _button(text: String, at: Vector2, variation: StringName = &"") -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = Vector2(84,18)
	button.theme_type_variation = variation
	button.focus_mode = Control.FOCUS_ALL
	_room.add_child(button)
	return button


func _surfaces(speaking: String, high: bool) -> void:
	_label("Actual controls / states + keyboard focus / "+speaking,Vector2(12,5),UiKit.WARM)
	var panel := Panel.new()
	panel.position = Vector2(8,24)
	panel.size = Vector2(464,226)
	_room.add_child(panel)
	var buttons: Array[Button] = []
	for i in 5:
		buttons.append(_button(["normal","hover","pressed","disabled","focus"][i],Vector2(14+i*90,40)))
	buttons[2].toggle_mode = true
	buttons[2].button_pressed = true
	buttons[3].disabled = true
	buttons[4].grab_focus()
	var tabs: Array[Button] = []
	for i in 4:
		var tab := _button(["tab","selected","disabled","hover"][i],Vector2(14+i*90,88),UiKit.TAB)
		tabs.append(tab)
		tab.toggle_mode = true
		tab.button_pressed = i==1
		tab.disabled = i==2
	var checks: Array[CheckBox] = []
	for i in 4:
		var check := CheckBox.new()
		checks.append(check)
		check.position = Vector2(14+i*110,132)
		check.text = "on" if i%2 else "off"
		check.button_pressed = bool(i%2)
		check.disabled = i>=2
		check.focus_mode = Control.FOCUS_ALL
		_room.add_child(check)
	var slider := HSlider.new()
	slider.position = Vector2(14,180)
	slider.size = Vector2(160,16)
	slider.value = 65
	slider.focus_mode = Control.FOCUS_ALL
	_room.add_child(slider)
	_label("65",Vector2(180,183))
	var quiet := HSlider.new()
	quiet.position = Vector2(245,180)
	quiet.size = Vector2(160,16)
	quiet.value = 35
	quiet.editable = false
	_room.add_child(quiet)
	_label("35",Vector2(414,183),UiKit.DIM)
	var mouse := InputEventMouseMotion.new()
	mouse.position = buttons[1].get_global_rect().get_center()
	root.push_input(mouse)
	await process_frame
	expect(buttons[1].is_hovered() and buttons[2].button_pressed and buttons[3].disabled and buttons[4].has_focus(),"Real controls enter hover/pressed/disabled/focus states")
	var theme := _room.theme
	for kind in [&"Button",UiKit.TAB]:
		var paths := {}
		for state in UiKit.BUTTON_STATES:
			var box := theme.get_stylebox(StringName(state),kind) as StyleBoxTexture
			expect(box!=null,"Drawn UI surfaces exist")
			if box!=null:
				paths[box.texture.resource_path]=true
				expect(box.texture_margin_left==3 and box.texture_margin_right==3,"Three-pixel nine-patch side margins are preserved")
		expect(paths.size()==4,"Normal/hover/pressed/disabled have distinct actual frame sources")
	expect(theme.get_stylebox(&"focus",&"Button") is StyleBoxTexture and theme.get_stylebox(&"focus",&"HSlider") is StyleBoxTexture,"Button and slider keyboard focus remain drawn")
	expect(quiet.get_theme_icon(&"grabber_disabled").resource_path=="res://sprites/ui/slider_grab_disabled.png","Disabled slider uses the small authored grip rather than the engine default")
	await _shoot("controls_"+speaking+("_contrast" if high else ""))
	slider.grab_focus()
	expect(slider.has_focus(),"Keyboard focus can reach slider")
	await _shoot("slider_focus_"+speaking+("_contrast" if high else ""))
	mouse.position = tabs[3].get_global_rect().get_center()
	root.push_input(mouse)
	await process_frame
	expect(tabs[3].is_hovered() and tabs[1].button_pressed and tabs[2].disabled,"Actual tabs show hover, selection and disabled states")
	checks[1].grab_focus()
	expect(checks[1].has_focus(),"Keyboard focus can reach checkbox")
	await _shoot("tab_check_focus_"+speaking+("_contrast" if high else ""))


func _shoot(name: String) -> void:
	if not _capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	expect(image!=null and image.get_size()==Vector2i(480,270),"Actual UI viewport is 480x270")
	if image!=null:
		expect(image.save_png(ProjectSettings.globalize_path(_folder+name+".png"))==OK,"Native UI capture saved")


func _hud(speaking: String, high: bool) -> void:
	_new_room()
	var state := State.create(18018)
	state["day"] = 99
	state["day_tick"] = GameData.DUSK_AT_TICK+GameData.SECONDS
	Resources.add(state,GameData.MONEY,999999)
	var before := var_to_bytes(state)
	var hud := DayHud.new()
	_room.add_child(hud)
	hud.set_process(false)
	hud.show_state(state)
	await process_frame
	await process_frame
	var day := hud.find_child("Day",true,false) as Label
	var money_icon := hud.find_child("icon_money",true,false) as TextureRect
	var money := hud.find_child("Money",true,false) as Label
	expect(day.get_global_rect().end.x<=money_icon.global_position.x,"Full localized dusk label cannot overlap the native money icon: "+day.text+" "+str(day.get_global_rect()))
	expect(money.get_global_rect().end.x<=210,"Six-digit money stays before the resource grid")
	for icon in hud.find_children("icon_*","TextureRect",true,false):
		expect(icon.texture.get_size()==Vector2(10,10) and icon.size==Vector2(10,10),"Actual HUD uses native compact icons")
	expect(var_to_bytes(state)==before,"Actual HUD cannot mutate the core")
	await _shoot("hud_dusk_"+speaking+("_contrast" if high else ""))
	state["phase"] = Phases.NIGHT
	before = var_to_bytes(state)
	hud.show_state(state)
	var power := hud.find_child("icon_energy",true,false) as TextureRect
	expect(power.is_visible_in_tree() and not money_icon.is_visible_in_tree(),"Power icon stays visible at night while day-only money hides")
	expect(var_to_bytes(state)==before,"Night HUD remains read-only")
	await _shoot("hud_night_"+speaking+("_contrast" if high else ""))


func _menus(speaking: String, high: bool) -> void:
	var state := State.create(18018)
	for id in GameData.RESOURCES:
		Resources.add(state,StringName(id),999)
	_new_room()
	var inventory := InventoryPanel.new()
	_room.add_child(inventory)
	inventory.set_process(false)
	inventory.show_state(state)
	inventory.toggle()
	var before := var_to_bytes(state)
	inventory._process(0.0)
	await process_frame
	await process_frame
	for page in inventory.page_count():
		for line in inventory.page_rows():
			var id := StringName(line["id"])
			var icon := inventory.find_child("inv_icon_%s" % id,true,false) as TextureRect
			expect(icon!=null and icon.texture==UiKit.icon(id,true),"Every page row integrates its resource icon")
			var label := inventory.find_child("inv_name_%s" % id,true,false) as Label
			expect(label!=null and label.text.contains(Names.of(id)),"Inventory uses localized resource names")
		_check_bounds(inventory)
		expect(var_to_bytes(state)==before,"Actual inventory pages are read-only")
		await _shoot("inventory_%d_" % page+speaking+("_contrast" if high else ""))
		inventory.turn_page(1)
		await process_frame
		await process_frame
	for which in [Shop.BUY,Shop.SELL]:
		_new_room()
		Shop.open(state)
		Shop.show_tab(state,which)
		before = var_to_bytes(state)
		var shop := ShopPanel.new()
		_room.add_child(shop)
		shop.set_process(false)
		shop.show_state(state)
		shop._process(0.0)
		await process_frame
		await process_frame
		var buttons := shop.find_children("*","Button",true,false)
		var icons := 0
		for button in buttons:
			if button.name.begins_with("buy_one_") or button.name.begins_with("sell_one_"):
				icons += 1
				expect(button.icon!=null and button.icon.get_size()==Vector2(10,10),"Actual shop quantity buttons use compact native icons")
				expect(button.size.x<=34 and button.size.y<=12,"Icon does not enlarge the existing shop button footprint")
		expect(icons>0,"Actual shop tab displays resource icons")
		_check_bounds(shop)
		expect(var_to_bytes(state)==before,"Actual shop layout cannot change resources or stock")
		await _shoot("shop_"+str(which)+"_"+speaking+("_contrast" if high else ""))


func _check_bounds(control: Control) -> void:
	for child in control.find_children("*","Control",true,false):
		if not child.is_visible_in_tree():
			continue
		var rect: Rect2 = child.get_global_rect()
		var ancestor := child.get_parent()
		var scroll: ScrollContainer = null
		while ancestor != null and ancestor != control:
			if ancestor is ScrollContainer:
				scroll = ancestor as ScrollContainer
				break
			ancestor = ancestor.get_parent()
		# Scrolled descendants may lie beyond the screen; their enclosing
		# viewport must fit, and horizontal text still has to fit every row.
		var fits_y := scroll != null or (rect.position.y >= 0 and rect.end.y <= 270)
		expect(rect.position.x>=0 and fits_y and rect.end.x<=480,"Actual localized control fits native viewport: "+str(child.name)+" "+str(rect))
		if child is Label:
			var label := child as Label
			var font := label.get_theme_font(&"font")
			var font_size := label.get_theme_font_size(&"font_size")
			var measured := font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
			if label.autowrap_mode != TextServer.AUTOWRAP_OFF:
				measured = font.get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,label.size.x,font_size)
				expect(measured.y<=label.size.y,"Wrapped shop text fits its row height: "+str(child.name))
			var width := measured.x
			expect(width<=label.size.x,"Localized label fits its actual allocated row: "+str(child.name))
