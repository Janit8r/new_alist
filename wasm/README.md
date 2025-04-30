# Alist WebAssembly for Cloudflare Workers

本文档介绍如何将 Alist 项目编译为 WebAssembly 并部署到 Cloudflare Workers。

## 前提条件

- Go 1.16+ (推荐 1.23.4)
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/) (Cloudflare Workers 的命令行工具)
- Cloudflare 账号

## 编译步骤

1. 确保您已安装 Go 环境并正确设置了 `GOPATH`：

```bash
go version
```

2. 安装 Wrangler CLI：

```bash
npm install -g wrangler
```

3. 登录 Cloudflare 账号：

```bash
wrangler login
```

4. 运行编译脚本：

```bash
# 添加执行权限
chmod +x build_wasm.sh
# 运行编译脚本
./build_wasm.sh
```

编译完成后，所有相关文件都会生成在 `build/wasm/` 目录中。

## 部署到 Cloudflare Workers

1. 进入生成的构建目录：

```bash
cd build/wasm/
```

2. 使用 Wrangler 发布应用：

```bash
wrangler publish
```

3. 发布成功后，您将获得一个 Cloudflare Workers URL，您可以通过该 URL 访问部署的应用。

## 工作原理

这个项目将 Alist 编译为 WebAssembly，并通过 Cloudflare Workers 运行。核心步骤如下：

1. 创建了 WASM 入口文件，暴露必要的 JavaScript 接口
2. 创建 Cloudflare 适配器，处理来自 Workers 的请求
3. 使用 WebAssembly 编译 Go 代码
4. 通过 Cloudflare Workers 托管和运行 WebAssembly 代码

## 限制

由于 Cloudflare Workers 的限制，某些 Alist 的功能可能无法完全运行：

- Workers 的 CPU 时间限制为 50ms (免费计划) 或 150ms (付费计划)
- 内存限制为 128MB
- 不支持直接文件系统访问 (需要通过 R2 或 KV 等存储服务)
- 原生网络请求可能受到限制

根据您的具体需求，您可能需要调整代码以适应这些限制。

## 进一步定制

要进一步定制应用，您可以：

1. 修改 `wasm/main.go` 文件，增加或移除功能
2. 更新 `wasm/cloudflare_adapter.go` 以改进请求处理
3. 修改 `worker.js` 文件以更好地集成 Cloudflare Workers 功能

## 故障排除

如果遇到问题，请尝试以下步骤：

- 检查 Go 版本是否兼容
- 确保 Wrangler 版本是最新的
- 查看 Cloudflare Workers 日志以获取错误信息
- 尝试在本地测试 WebAssembly 代码 