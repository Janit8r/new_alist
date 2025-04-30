package main

import (
	"encoding/json"
	"net/http"
	"strings"
	"syscall/js"
)

// 注册处理 HTTP 请求的函数
func registerRequestHandler() {
	js.Global().Set("handleAlistRequest", js.FuncOf(handleRequest))
}

// handleRequest 处理来自 Cloudflare Worker 的请求
func handleRequest(this js.Value, args []js.Value) interface{} {
	// 获取请求信息
	requestObj := args[0]
	method := requestObj.Get("method").String()
	url := requestObj.Get("url").String()
	
	// 解析请求体
	var body []byte
	if method == "POST" || method == "PUT" {
		bodyStr := requestObj.Get("body").String()
		body = []byte(bodyStr)
	}
	
	// 创建请求
	req, err := http.NewRequest(method, url, strings.NewReader(string(body)))
	if err != nil {
		return createErrorResponse("Failed to create request: " + err.Error())
	}
	
	// 添加请求头
	headers := requestObj.Get("headers")
	if headers.Type() == js.TypeObject {
		for _, key := range js.Global().Get("Object").Call("keys", headers).Call("map", js.FuncOf(func(this js.Value, args []js.Value) interface{} {
			return args[0].String()
		})).Call("valueOf").Interface().([]interface{}) {
			keyStr := key.(string)
			req.Header.Add(keyStr, headers.Get(keyStr).String())
		}
	}
	
	// 创建响应通道
	respChan := make(chan map[string]interface{}, 1)
	
	// 在新协程中处理请求
	go func() {
		// 此处可以调用 Alist 的特定功能处理请求
		// 简化版本中，我们只返回成功消息
		resp := map[string]interface{}{
			"status": 200,
			"body": "Alist WebAssembly is running",
			"headers": map[string]string{
				"Content-Type": "text/plain",
			},
		}
		respChan <- resp
	}()
	
	// 创建Promise对象
	promise := js.Global().Get("Promise").New(js.FuncOf(func(this js.Value, args []js.Value) interface{} {
		resolve := args[0]
		go func() {
			resp := <-respChan
			respJSON, _ := json.Marshal(resp)
			resolve.Invoke(js.ValueOf(string(respJSON)))
		}()
		return nil
	}))
	
	return promise
}

// createErrorResponse 创建错误响应
func createErrorResponse(errMsg string) js.Value {
	resp := map[string]interface{}{
		"status": 500,
		"body": errMsg,
		"headers": map[string]string{
			"Content-Type": "text/plain",
		},
	}
	respJSON, _ := json.Marshal(resp)
	return js.ValueOf(string(respJSON))
} 