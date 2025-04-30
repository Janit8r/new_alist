#!/bin/bash

# 设置 Go 环境变量以编译 WebAssembly
export GOOS=js
export GOARCH=wasm

# 创建构建目录
mkdir -p build/wasm

# 编译 Go 代码为 WebAssembly
echo "Compiling Go code to WebAssembly..."
go build -o build/wasm/alist.wasm ./wasm

# 复制 wasm_exec.js 文件（Go 的 WebAssembly 辅助文件）
echo "Copying wasm_exec.js..."
cp "$(go env GOROOT)/misc/wasm/wasm_exec.js" build/wasm/

# 创建 Cloudflare Worker 文件
echo "Creating Cloudflare Worker file..."
cat > build/wasm/worker.js << 'EOF'
// wasm_exec.js 需要这些全局变量
self.global = self;
self.process = {
  argv: [],
  env: {}
};

importScripts('./wasm_exec.js');

const go = new Go();

let wasmInstance = null;

// 初始化 WebAssembly 模块
async function initWasm() {
  if (!wasmInstance) {
    try {
      const wasmModule = await WebAssembly.compileStreaming(
        fetch('./alist.wasm')
      );
      wasmInstance = await WebAssembly.instantiate(wasmModule, go.importObject);
      go.run(wasmInstance);
      
      // 启动 Alist
      self.startAlist();
      console.log("Alist WASM initialized successfully");
      return true;
    } catch (error) {
      console.error("Failed to initialize Alist WASM:", error);
      return false;
    }
  }
  return true;
}

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  // 初始化 WebAssembly
  const initialized = await initWasm();
  if (!initialized) {
    return new Response('Failed to initialize Alist WebAssembly', {
      status: 500,
      headers: { 'content-type': 'text/plain' },
    });
  }

  try {
    // 准备请求对象传递给 Go
    const requestObj = {
      method: request.method,
      url: request.url,
      headers: Object.fromEntries(request.headers.entries())
    };

    // 如果是有请求体的方法，获取请求体
    if (request.method === 'POST' || request.method === 'PUT') {
      requestObj.body = await request.text();
    }

    // 调用 Go 注册的请求处理函数
    const responseJsonPromise = self.handleAlistRequest(requestObj);
    const responseJson = await responseJsonPromise;
    
    // 解析响应
    const responseObj = JSON.parse(responseJson);
    
    // 创建响应
    return new Response(responseObj.body, {
      status: responseObj.status,
      headers: responseObj.headers,
    });
  } catch (error) {
    console.error("Error handling request:", error);
    return new Response(`Error processing request: ${error.message}`, {
      status: 500,
      headers: { 'content-type': 'text/plain' },
    });
  }
}
EOF

# 创建 Cloudflare 配置文件
echo "Creating Cloudflare configuration file..."
cat > build/wasm/wrangler.toml << 'EOF'
name = "alist-wasm"
type = "javascript"
usage_model = "bundled"
compatibility_date = "2023-10-30"

[build]
command = ""

[build.upload]
format = "service-worker"

[[build.upload.rules]]
type = "Text"
globs = ["**/*.js"]

[[build.upload.rules]]
type = "CompiledWasm"
globs = ["**/*.wasm"]
EOF

echo "Build completed. Files are in build/wasm/"
echo "You can deploy to Cloudflare Workers using Wrangler with: wrangler publish" 