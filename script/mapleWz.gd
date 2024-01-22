extends Node
class_name MapleResource

enum { LOAD_OK, LOAD_FAIL, NO_FOUND }  # 枚举，表示加载状态

# Member variable
var WZ = WZNode.new(null, "", {})  # WZNode实例
var z_map = {}  # 存储zmap的字典


# Called when the node enters the scene tree for the first time.
func _ready():
	# test code
	print("ready for MapleResources.")
	load_z_map()  # 加载zmap


# 加载zmap
func load_z_map():
	load_wz_file("zmap")  # 加载wz文件

	var array = WZ.children.zmap.data._keys  # 获取zmap的keys
	var total = z_map.size()  # 获取zmap的大小
	var index = 0
	for key in array:  # 遍历keys
		z_map[key] = total - index  # 更新z_map
		index += 1

	print("load zmap sort success")  # 打印成功信息


# 根据路径获取数据
func get_by_path(path: String):
	# path example: Character/00002000.img/motion/index
	# 判断缓存是否有，有则直接索引返回；
	# 缓存上没有，则加载文件，并初始化；
	if not path.contains(".img"):
		return NO_FOUND  # 如果路径不包含.img，返回未找到

	var ss = path.split(".img")  # 分割路径
	var file_path = ss[0]  # 获取文件路径
	var sub_path = ss[1]  # 获取子路径
	if WZ.children.has(file_path):  # 如果WZ的子节点中有该文件路径
		var data = WZ.children.get(file_path) as WZNode  # 获取WZNode
		var result = find_for_sub_path(data, sub_path)  # 在子路径中查找
		if result != null:
			return result.resolve_uol()  # 如果找到，返回结果
		else:
			return NO_FOUND  # 如果未找到，返回未找到
	else:
		if load_wz_file(file_path) == LOAD_OK:  # 如果加载文件成功
			return get_by_path(path)  # 重新获取路径
		else:
			printerr("get wz path fail: ", path)  # 打印错误信息
			return NO_FOUND  # 返回未找到


# 加载wz文件
func load_wz_file(file_path):
	var path = "res://wz_client/" + file_path + ".img.xml.json"  # 构造完整路径
	var file = FileAccess.open(path, FileAccess.READ)  # 打开文件
	var error = FileAccess.get_open_error()  # 获取打开错误
	if error != OK:
		printerr("Load wz file fail ", file_path, " reason: ", error)  # 打印错误信息
		return LOAD_FAIL  # 返回加载失败
	var data = JSON.parse_string(file.get_as_text())  # 解析JSON字符串
	WZ.children[file_path] = create_wz_node(WZ, data)  # 创建WZNode并存储
	print("Load wz file success ", path)  # 打印成功信息
	return OK  # 返回成功


# 获取精灵的z索引
func get_sprite_z_index(part):
	if z_map.has(part):  # 如果z_map中有该部分
		return z_map[part]  # 返回该部分的z索引
	else:
		printerr("warn: no part in z map: ", part)  # 打印警告信息
		return 0  # 返回0


# 在子路径中查找
static func find_for_sub_path(data: WZNode, sub_path: String):
	# TODO
	# 拆解 sub_path
	# 循环获取 sub_path 的数据
	var path = sub_path.split("/", false)  # 分割子路径
	return data.find(path)  # 在数据中查找路径


# 创建WZNode
static func create_wz_node(parent, data):
	# if data["type"] != 'object'
	if typeof(data) != TYPE_DICTIONARY:  # 如果数据类型不是字典
		return null  # 返回null

	var name = data["name"]  # 获取名字
	var type = data.get("type", null)  # 获取类型
	if str(type) == "uol":  # 如果类型是uol
		var path = data["path"]  # 获取路径
		return UOLWZNode.new(parent, name, data, path)  # 返回新的UOLWZNode

	var result = WZNode.new(parent, name, data)  # 创建新的WZNode
	for sub_name in data.get("_keys", {}):  # 遍历_keys
		if !data.has(sub_name):  # 如果数据中没有该子名
			continue  # 继续下一次循环
		result.children[sub_name] = create_wz_node(result, data[sub_name])  # 创建子节点

	return result  # 返回结果


# 判断是否是画布
static func is_canvas(data):
	return typeof(data) == TYPE_DICTIONARY and data.has("type") and data.type == "canvas"  # 如果数据类型是字典，并且有类型，且类型是画布，返回真


# 创建精灵
static func create_sprite(draw_map, data):
	if is_canvas(data):  # 如果是画布
		var sprite = Sprite2D.new()  # 创建新的Sprite2D
		sprite.texture = data._image.texture  # 设置纹理
		var origin = off_set(draw_map, data)  # 获取原点
		sprite.position = origin  # 设置位置
		sprite.offset += (sprite.texture.get_size() / 2)  # 设置偏移
		return sprite  # 返回精灵
	else:
		printerr("error, no canvas found for sprite")  # 打印错误信息
		print_stack()  # 打印堆栈
		return null  # 返回null


# 计算偏移量
static func off_set(draw_map, data):
	var origin = Vector2(-data.origin.X, -data.origin.Y)  # 获取原点
	var name = data.name  # 获取名字
	var map = data.map as Dictionary  # 获取map
	var result  # 结果

	for key in map["_keys"]:  # 遍历_keys
		var m = map[key]  # 获取m
		draw_map["%s/%s" % [name, key]] = Vector2(-m.X, -m.Y)  # 更新draw_map

	if map.has("brow"):  # 如果map中有brow
		var brow = Vector2(-map.brow.X, -map.brow.Y)  # 获取brow
		result = (
			origin
			+ get_or(draw_map, "head/neck")  # 获取head/neck
			- get_or(draw_map, "body/neck")  # 获取body/neck
			- get_or(draw_map, "head/brow")  # 获取head/brow
			+ brow
		)

	if map.has("neck"):  # 如果map中有neck
		var neck = Vector2(-map.neck.X, -map.neck.Y)  # 获取neck
		result = origin + get_or(draw_map, "head/neck") - get_or(draw_map, "body/neck")  # 计算结果

	if map.has("hand"):  # 如果map中有hand
		var hand = Vector2(-map.hand.X, -map.hand.Y)  # 获取hand
		result = (
			origin
			+ get_or(draw_map, "arm/navel")  # 获取arm/navel
			- get_or(draw_map, "body/navel")  # 获取body/navel
			- get_or(draw_map, "arm/hand")  # 获取arm/hand
			+ hand
		)

	if map.has("handMove"):  # 如果map中有handMove
		var handMove = Vector2(-map.handMove.X, -map.handMove.Y)  # 获取handMove
		result = origin - get_or(draw_map, "lHand/handMove") + handMove  # 计算结果

	if map.has("navel"):  # 如果map中有navel
		var navel = Vector2(-map.navel.X, -map.navel.Y)  # 获取navel
		result = origin - get_or(draw_map, "body/navel") + navel  # 计算结果

	draw_map["%s/origin" % [name]] = result  # 更新draw_map
	return result  # 返回结果


# 获取map中的值，如果没有则返回Vector2()
static func get_or(map, key):
	if map.has(key):  # 如果map中有key
		return map[key]  # 返回key对应的值
	else:
		return Vector2()  # 返回Vector2()


class WZNode:
	var parent = null
	var name = null
	var data = {}
	var children = {}

	func _init(parent, name, data):
		# 递归构建 WZNode 对象
		self.parent = parent
		self.name = name
		self.data = resolve_data(data)

	func find(path: Array):
		# 索引查找数据
		var next = path.pop_front()
		match next:
			"..":
				return parent.find(path)
			".":
				return self
			null:
				return self
			_:
				if children.has(next):
					return children[next].find(path)

		printerr("can not find wznode path: ", path, " current node: ", self)
		return null

	func is_type(type):
		return type == "WZNode"

	func resolve_uol():
		# 递归解析 uol 引用
		var children_resolved = {}
		for name in children:
			var child = children[name] as WZNode
			if child != null and child.is_type("UOLWZNode"):
				child = child.resolve_uol()
			children_resolved[name] = child
		self.children = children_resolved
		return self

	# 数据转换方法
	static func resolve_data(data):
		match data.get("type"):
			# 图片
			"canvas":
				# 将数据转化为 texture
				var image_source = data["_image"]
				var image_ = Image.new()
				image_.load_png_from_buffer(Marshalls.base64_to_raw(image_source.uri))
				var texture = ImageTexture.create_from_image(image_)
				data._image.texture = texture
				data._image.uri = null
				return data
			# 音频等数据结构 TODO
			_:
				return data


class UOLWZNode:
	extends WZNode
	var uol_path: String

	func _init(parent, name, data, path):
		self.name = name
		self.parent = parent
		self.data = resolve_data(data)
		self.uol_path = path

	func find(path: Array):
		path.append_array(self.uol_path.split("/", false))
		return self.parent.find(path)

	func is_type(type):
		return type == "UOLWZNode"

	func resolve_uol():
		var node = find([]) as WZNode
		return node.resolve_uol()
