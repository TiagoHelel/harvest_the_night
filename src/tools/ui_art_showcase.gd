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
	image.position = at
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP
	image.size = Vector2(10,10) if compact else Vector2(16,16)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_room.add_child(image)
	_icons.append(image)
	return image


func _inventory(speaking: String, high: bool) -> void:
	_label("15 resources / native 16px + HUD 10px / " + speaking,Vector2(12,5),UiKit.WARM)
	expect(UiKit.missing_icons().is_empty() and UiKit.orphan_icons().is_empty(),"Actual core inventory has exactly fifteen icons")
	for i in GameData.RESOURCES.size():
		var id: StringName = GameData.RESOURCES[i]
		var at := Vector2(12+(i%3)*152,25+(i/3)*46)
		var name := Names.of(id)
		expect(UiKit.font().get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x<=148,"Localized resource name fits its actual fixture column: "+name)
		_label(name,at,UiKit.WARM)
		_icon(id,false,at+Vector2(2,11))
		_icon(id,true,at+Vector2(25,14))
		_label("999",at+Vector2(42,14))
	for image in _icons:
		expect(image.texture!=null,"Every full and compact resource loads")
		if image.texture==null:
			continue
		expect(image.texture.get_size()==image.size,"Native UI never resizes an inventory icon")
		var source := Image.load_from_file(ProjectSettings.globalize_path(image.texture.resource_path))
		expect(image.texture.get_image().get_data()==source.get_data(),"Imported source pixels are exact")
	await _shoot("icons_"+speaking+("_contrast" if high else ""))
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
					expect(actual.get_pixelv(at).is_equal_approx(pixel),"Actual native inventory pixel survives both themes: "+image.texture.resource_path)
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
	for id in GameData.RESOURCES:
		var icon := inventory.find_child("inv_icon_%s" % id,true,false) as TextureRect
		expect(icon!=null and icon.texture==UiKit.icon(StringName(id),true),"Every resource is actually integrated in the inventory")
		var label := inventory.find_child("inv_name_%s" % id,true,false) as Label
		expect(label!=null and label.text.contains(Names.of(StringName(id))),"Inventory uses existing localized resource names")
	_check_bounds(inventory)
	expect(var_to_bytes(state)==before,"Actual inventory layout is read-only")
	await _shoot("inventory_"+speaking+("_contrast" if high else ""))
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
		expect(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=480 and rect.end.y<=270,"Actual localized control fits native viewport: "+str(child.name)+" "+str(rect))
		if child is Label:
			var label := child as Label
			var width := label.get_theme_font(&"font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size(&"font_size")).x
			expect(width<=label.size.x,"Localized label fits its actual allocated row: "+str(child.name))
