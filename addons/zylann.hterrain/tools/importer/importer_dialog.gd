tool
extends WindowDialog

const Util = preload("../../util/util.gd")
const HTerrainData = preload("../../hterrain_data.gd")
const Errors = preload("../../util/errors.gd")
const Logger = preload("../../util/logger.gd")

signal permanent_change_performed(message)

onready var _inspector = $VBoxContainer/Inspector
onready var _errors_label = $VBoxContainer/ColorRect/ScrollContainer/VBoxContainer/Errors
onready var _warnings_label = $VBoxContainer/ColorRect/ScrollContainer/VBoxContainer/Warnings

var _terrain = null
var _logger = Logger.get_for(self)


func _ready():
	_inspector.set_prototype({
		"heightmap": { "type": TYPE_STRING, "usage": "file", "exts": ["raw", "png"] },
		"min_height": { "type": TYPE_REAL, "range": {"min": -2000.0, "max": 2000.0, "step": 1.0}, "default_value": 0.0 },
		"max_height": { "type": TYPE_REAL, "range": {"min": -2000.0, "max": 2000.0, "step": 1.0}, "default_value": 400.0 },
		"splatmap": { "type": TYPE_STRING, "usage": "file", "exts": ["png"] },
		"colormap": { "type": TYPE_STRING, "usage": "file", "exts": ["png"] }
	})
	
	# Testing
#	_errors_label.text = "- Hello World!"
#	_warnings_label.text = "- Yolo Jesus!"


func set_terrain(terrain):
	_terrain = terrain


func _notification(what: int):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible and is_inside_tree():
			_clear_feedback()


static func _format_feedbacks(feed):
	var a = []
	for s in feed:
		a.append("- " + s)
	return PoolStringArray(a).join("\n")


func _clear_feedback():
	_errors_label.text = ""
	_warnings_label.text = ""


func _show_feedback(res):
	for e in res.errors:
		_logger.error(e)

	for w in res.warnings:
		_logger.warn(w)
	
	_clear_feedback()
	
	if len(res.errors) > 0:
		_errors_label.text = _format_feedbacks(res.errors)

	if len(res.warnings) > 0:
		_warnings_label.text = _format_feedbacks(res.warnings)


func _on_CheckButton_pressed():
	var res = _validate_form()
	_show_feedback(res)


func _on_ImportButton_pressed():
	assert(_terrain != null and _terrain.get_data() != null)

	# Verify input to inform the user of potential issues
	var res = _validate_form()
	_show_feedback(res)

	if len(res.errors) != 0:
		_logger.debug("Cannot import due to errors, aborting")
		return

	var params = {}

	var heightmap_path = _inspector.get_value("heightmap")
	if heightmap_path != "":
		params[HTerrainData.CHANNEL_HEIGHT] = {
			"path": heightmap_path,
			"min_height": _inspector.get_value("min_height"),
			"max_height": _inspector.get_value("max_height"),
		}

	var colormap_path = _inspector.get_value("colormap")
	if colormap_path != "":
		params[HTerrainData.CHANNEL_COLOR] = {
			"path": colormap_path
		}

	var splatmap_path = _inspector.get_value("splatmap")
	if splatmap_path != "":
		params[HTerrainData.CHANNEL_SPLAT] = {
			"path": splatmap_path
		}

	var data = _terrain.get_data()
	data._edit_import_maps(params)
	emit_signal("permanent_change_performed", "Import maps")
	
	_logger.debug("Terrain import finished")
	hide()


func _on_CancelButton_pressed():
	hide()


func _on_Inspector_property_changed(key, value):
	pass # replace with function body


func _validate_form():

	var res = {
		"errors": [],
		"warnings": []
	}

	var heightmap_path = _inspector.get_value("heightmap")
	var splatmap_path = _inspector.get_value("splatmap")
	var colormap_path = _inspector.get_value("colormap")

	if colormap_path == "" and heightmap_path == "" and splatmap_path == "":
		res.errors.append("No maps specified.")
		return res

	# If a heightmap is specified, it will override the size of the existing terrain.
	# If not specified, maps will have to match the resolution of the existing terrain.
	var heightmap_size = _terrain.get_data().get_resolution()

	if heightmap_path != "":
		var min_height = _inspector.get_value("min_height")
		var max_height = _inspector.get_value("max_height")

		if min_height >= max_height:
			res.errors.append("Minimum height must be lower than maximum height")
			# Returning early because min and max can be slided,
			# so we avoid loading other maps everytime to do further checks
			return res

		var size = _load_image_size(heightmap_path, _logger)
		if size.has("error"):
			res.errors.append(str("Cannot open heightmap file: ", _error_to_string(size.error)))
			return res

		var adjusted_size = HTerrainData.get_adjusted_map_size(size.width, size.height)

		if adjusted_size != size.width:
			res.warnings.append(
				"The square resolution deduced from heightmap file size is not power of two + 1.\n" + \
				"The heightmap will be cropped.")

		heightmap_size = adjusted_size

	if splatmap_path != "":
		_check_map_size(splatmap_path, "splatmap", heightmap_size, res, _logger)

	if colormap_path != "":
		_check_map_size(colormap_path, "colormap", heightmap_size, res, _logger)

	return res


static func _check_map_size(path, map_name, heightmap_size, res, logger):
	var size = _load_image_size(path, logger)
	if size.has("error"):
		res.errors.append("Cannot open splatmap file: ", _error_to_string(size.error))
		return
	var adjusted_size = HTerrainData.get_adjusted_map_size(size.width, size.height)
	if adjusted_size != heightmap_size:
		res.errors.append(str(
			"The ", map_name, 
			" must have the same resolution as the heightmap (", heightmap_size, ")"))
	else:
		if adjusted_size != size.width:
			res.warnings.append(
				"The square resolution deduced from ", map_name, 
				" file size is not power of two + 1.\nThe ", 
				map_name, " will be cropped.")


static func _load_image_size(path, logger):
	var ext = path.get_extension().to_lower()

	if ext == "png":
		var im = Image.new()
		var err = im.load(path)
		if err != OK:
			logger.error("An error occurred loading image '{0}', code {1}" \
				.format([path, err]))
			return { "error": err }

		return { "width": im.get_width(), "height": im.get_height() }

	elif ext == "raw":
		var f = File.new()
		var err = f.open(path, File.READ)
		if err != OK:
			logger.error("Error opening file {0}".format([path]))
			return { "error": err }

		# Assume the raw data is square in 16-bit format,
		# so its size is function of file length
		var flen = f.get_len()
		f.close()
		var size = Util.integer_square_root(flen / 2)
		if size == -1:
			return { "error": "RAW image is not square" }
		
		logger.debug("Deduced RAW heightmap resolution: {0}*{1}, for a length of {2}" \
			.format([size, size, flen]))

		return { "width": size, "height": size }

	else:
		return { "error": ERR_FILE_UNRECOGNIZED }


static func _error_to_string(err):
	if typeof(err) == TYPE_STRING:
		return err
	return str("code ", err, ": ", Errors.get_message(err))
