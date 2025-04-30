package main

import (
	"syscall/js"
	
	"github.com/alist-org/alist/v3/cmd"
	"github.com/alist-org/alist/v3/internal/conf"
)

func main() {
	// 设置WASM特定配置
	conf.Conf.Scheme = "https"
	
	// 注册JavaScript回调函数
	js.Global().Set("startAlist", js.FuncOf(startAlist))
	
	// 注册请求处理函数
	registerRequestHandler()
	
	// 防止主程序退出
	c := make(chan struct{}, 0)
	<-c
}

// startAlist 是 JS 可调用的函数，用于启动 Alist
func startAlist(this js.Value, args []js.Value) interface{} {
	go func() {
		// 使用有限的功能启动服务
		cmd.Execute()
	}()
	return nil
} 