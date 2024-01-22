extends Control
# MapleMap 模拟场景

var WzHttp  # HTTP类，用于网络请求
var uiWindows  # UI窗口
signal Start_LoadMap(WzHttp)  # 定义一个信号，用于开始加载地图


func _init():
	pass  # 初始化函数，目前为空


func _ready():
	# ProjectSettings.load_resource_pack("src/pck.json")  # 加载资源包，目前被注释掉
	# add_child(WzHttp);  # 添加 WzHttp 作为子节点，目前被注释掉
	await emit_signal("Start_LoadMap", "000010000")  # 发送开始加载地图的信号
	uiWindows = get_node("UIWindows")  # 获取 UIWindows 节点


func _input(event):
	if event is InputEventKey:  # 如果输入的是键盘事件
		if event.is_pressed() && event.keycode == KEY_W:  # 如果按下的是 W 键
			if !uiWindows:  # 如果没有 UIWindows，直接返回
				return
			var item = preload("res://scene/UI/WorldMap.tscn")  # 预加载 WorldMap 场景
			var i: MapleWindow = item.instantiate()  # 实例化 WorldMap 场景
			i.showWindow(uiWindows)  # 在 UIWindows 中显示 WorldMap 场景
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass  # 每帧调用的函数，目前被注释掉


func _on_start_load_map(WzHttp):
	pass  # 当开始加载地图的信号被接收时调用的函数，目前为空
