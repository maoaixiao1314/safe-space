# ✅ Internal Server Error 500 问题已解决

## 🎯 问题描述

访问 http://13.250.19.178:3002/ 显示 **Internal Server Error 500**

## 🔍 问题根因

1. **NODE_ENV 冲突**
   - PM2 配置设置为 `NODE_ENV: production`
   - 但使用 `yarn dev` 开发模式启动
   - 导致 React 编译错误：`jsxDEV is not a function`

2. **.next 目录缓存问题**
   - 旧的编译缓存损坏
   - 缺少 `required-server-files.json`
   - Webpack 缓存写入失败

## ✅ 解决方案

### 1. 修复 PM2 环境变量

```javascript
// ecosystem.config.js
env: {
  PORT: 3002,
  NODE_ENV: 'development'  // 改为 development
}
```

### 2. 清理编译缓存

```bash
# 停止服务
pm2 stop safe-web

# 清理 .next 目录
rm -rf /home/ubuntu/safe-space/safe-wallet-web/apps/web/.next

# 重新启动
pm2 start safe-web
```

### 3. 保存配置

```bash
pm2 save
```

## 📊 验证结果

```bash
# 测试首页
curl -I http://localhost:3002/

# 结果
✅ HTTP/1.1 200 OK
✅ Content-Type: text/html; charset=utf-8
✅ X-Powered-By: Next.js
```

## 🔧 完整修复流程

```bash
# 1. 修改 PM2 配置
vim /home/ubuntu/safe-space/safe-wallet-web/ecosystem.config.js
# 修改 NODE_ENV: 'development'

# 2. 清理并重启
pm2 stop safe-web
cd /home/ubuntu/safe-space/safe-wallet-web/apps/web
rm -rf .next
cd /home/ubuntu/safe-space/safe-wallet-web
pm2 start ecosystem.config.js
pm2 save

# 3. 等待编译完成（约 40 秒）
pm2 logs safe-web

# 4. 验证
curl http://localhost:3002/
```

## 📝 技术细节

### 错误日志分析

**错误 1：React 编译错误**
```
TypeError: (0 , react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV) is not a function
at eval (src/features/spaces/components/SpaceSidebarNavigation/config.tsx:24:11)
```

**原因：** `NODE_ENV=production` 与 `yarn dev` 不兼容

**错误 2：文件缺失**
```
[Error: ENOENT: no such file or directory, open '.next/required-server-files.json']
```

**原因：** `.next` 目录缓存损坏

**错误 3：Webpack 缓存失败**
```
<w> [webpack.cache.PackFileCacheStrategy] Caching failed for pack
```

**原因：** 旧缓存文件冲突

### 修复原理

1. **使用正确的 NODE_ENV**
   - `yarn dev` → `NODE_ENV=development`
   - `yarn start` → `NODE_ENV=production`

2. **清理缓存**
   - 删除 `.next` 目录强制重新编译
   - Next.js 自动重建所有必需文件

3. **编译过程**
   - 启动后自动编译
   - 大约需要 40-60 秒
   - 完成后显示 "✓ Ready in X.Xs"

## 🎯 当前状态

✅ **服务正常运行**
- PM2 进程：safe-web (online)
- 端口：3002
- 状态：HTTP 200 OK
- 编译：完成

✅ **配置已保存**
- PM2 配置已更新
- 自动重启已配置
- 开机自启已配置

## 🚨 预防措施

### 如果再次出现 500 错误：

1. **检查日志**
   ```bash
   pm2 logs safe-web --err --lines 30
   ```

2. **清理并重启**
   ```bash
   pm2 stop safe-web
   rm -rf /home/ubuntu/safe-space/safe-wallet-web/apps/web/.next
   pm2 start safe-web
   ```

3. **等待编译**
   - 不要立即访问，等待 40-60 秒
   - 查看日志确认 "Ready" 消息

### 常见问题

**Q: 首页加载很慢？**
A: 首次访问需要编译，等待 30-60 秒。后续访问会快很多。

**Q: 修改代码后需要重启吗？**
A: 开发模式（`yarn dev`）会自动热重载，不需要重启。

**Q: 如何切换到生产模式？**
A: 
```bash
# 1. 构建
cd /home/ubuntu/safe-space/safe-wallet-web/apps/web
yarn build

# 2. 修改 PM2 配置
# args: 'start' (不是 'dev')
# NODE_ENV: 'production'

# 3. 重启
pm2 restart safe-web
```

## 📚 相关文档

- 服务持续运行：`/home/ubuntu/safe-space/SERVICE_PERSISTENCE_GUIDE.md`
- 快速参考：`/home/ubuntu/safe-space/QUICK_REFERENCE.txt`
- PM2 配置：`/home/ubuntu/safe-space/safe-wallet-web/ecosystem.config.js`

---

**修复时间：** 2025-10-17 11:01  
**问题状态：** ✅ 已解决  
**访问地址：** http://13.250.19.178:3002/  
**状态码：** 200 OK 🎉
