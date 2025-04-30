# 配置GitHub Actions自动部署到Cloudflare Workers

本文档介绍如何配置GitHub Secrets以支持自动编译和部署WebAssembly到Cloudflare Workers。

## 配置GitHub Secrets

在使用GitHub Actions工作流部署到Cloudflare Workers之前，您需要在GitHub仓库中设置以下Secrets：

1. 登录您的GitHub仓库
2. 点击 "Settings" > "Secrets and variables" > "Actions"
3. 点击 "New repository secret" 并添加以下secrets：

### 必需的Secrets

| Secret名称 | 描述 | 获取方式 |
|------------|------|----------|
| `CLOUDFLARE_API_TOKEN` | Cloudflare API令牌 | Cloudflare Dashboard > Profile > API Tokens > Create Token |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare账户ID | Cloudflare Dashboard > Account Home > 右侧"Account ID" |

## 创建Cloudflare API令牌

1. 登录[Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 点击右上角的个人图标，然后选择"My Profile"
3. 在左侧菜单中选择"API Tokens"
4. 点击"Create Token"
5. 选择"Edit Cloudflare Workers"模板或创建自定义令牌
6. 确保令牌具有以下权限：
   - Account > Workers Scripts > Edit
   - Zone > Workers Routes > Edit（如果需要配置路由）
7. 设置适当的账户和区域资源
8. 创建令牌并复制显示的值（此值只会显示一次）

## 获取Cloudflare账户ID

1. 登录[Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 在主页右侧找到"Account ID"
3. 复制此ID值

## 触发部署

配置完成后，部署将在以下情况自动触发：

1. 推送到`main`分支时
2. 手动通过GitHub Actions界面触发"workflow_dispatch"事件

## 验证部署

部署完成后，您可以通过以下方式验证部署：

1. 检查GitHub Actions运行日志
2. 访问Cloudflare Workers部署的URL（格式通常为`https://alist-wasm.<your-workers-subdomain>.workers.dev`）

## 故障排除

如果部署失败，请检查：

1. GitHub Actions日志中的错误信息
2. 确认API令牌权限是否正确
3. 确认账户ID是否正确
4. 检查Go版本兼容性
5. 确认wrangler.toml配置是否正确

## 在本地测试构建

如果您想在本地测试构建而不部署，可以从GitHub Actions下载构建产物，然后使用本地安装的wrangler进行测试。 