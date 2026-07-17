# Smoke Checklist — vite-react-content-site

> 手动验收清单。运行 `npm run dev` 后逐项检查。
> 以后安装 Playwright 后可以升级为自动测试。

## 基础检查

- [ ] `npm run dev` 能正常启动，浏览器可打开 http://localhost:5173
- [ ] `npm run typecheck` 无错误
- [ ] `npm run build` 无错误
- [ ] `npm run preview` 可正常访问构建产物

## 页面内容

- [ ] Header 导航可见（功能 / 使用流程 / 适用场景 / 联系我们）
- [ ] Hero 区域可见（标题 + 描述 + CTA 按钮）
- [ ] Features 区域可见（4 个功能卡片）
- [ ] How It Works 区域可见（3 个步骤）
- [ ] Use Cases 区域可见（3 个场景卡片）
- [ ] CTA 区域可见（"准备好了吗？" + 联系按钮）
- [ ] Footer 可见（版权信息 + 链接）

## 交互

- [ ] 点击 Header 导航项 → 页面滚动到对应区域
- [ ] 点击 Hero CTA 按钮 → 页面滚动到 CTA 区域
- [ ] 点击 CTA 按钮 → 打开默认邮件客户端

## 响应式

- [ ] 375px 宽度下页面无横向溢出
- [ ] 375px 宽度下 Header 导航正常显示
- [ ] 768px 宽度下布局正常
- [ ] 1440px 宽度下内容居中不溢出

## 控制台

- [ ] 浏览器控制台无红色错误
- [ ] 浏览器控制台无未捕获异常

## 说明

当前为手动检查清单。以后如果安装了 `playwright-interactive`：

```javascript
// 可以升级为自动测试：
// - test("首页正常加载", ...)
// - test("导航锚点点击", ...)
// - test("移动端无溢出", ...)
```
