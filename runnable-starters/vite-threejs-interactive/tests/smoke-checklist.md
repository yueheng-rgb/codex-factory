# Smoke Checklist — vite-threejs-interactive

> 手动验收清单。运行 `npm run dev` 后逐项检查。
> 以后安装 Playwright 后可升级为自动测试。

## 基础检查

- [ ] `npm run dev` 正常启动（默认 http://localhost:5173）
- [ ] `npm run typecheck` 无错误
- [ ] `npm run build` 无错误

## 场景渲染

- [ ] canvas 可见（非空白）
- [ ] 场景中有地面 plane
- [ ] 场景中有 3 个 placeholder objects（桌子/盒子/门）
- [ ] 控制台无 WebGL 错误

## HUD

- [ ] 左上角显示项目名
- [ ] 显示当前交互模式（默认"探索"）
- [ ] 显示提示文字

## 右侧 Panel

- [ ] 右侧 300px 面板可见
- [ ] 未选中对象时显示空状态（👆 + 提示）
- [ ] hover 对象有高亮反馈（emissive 变化）
- [ ] click 对象后 Panel 更新为对象详情
- [ ] 对象详情显示：名称、类型、状态、描述
- [ ] "标记已查看"按钮存在

## 交互行为

- [ ] click 空白处 → 取消选择，Panel 回到空状态
- [ ] click "标记已查看" → Toast 显示反馈
- [ ] 标记后对象状态更新

## MiniMap

- [ ] 右下角小地图可见
- [ ] 小地图上有对象位置点
- [ ] 小地图尺寸约 140×140px

## Toast

- [ ] 底部 Toast 容器存在
- [ ] Toast 消息出现后自动消失

## 响应式

- [ ] 375px 下无横向溢出
- [ ] 移动端 Panel 变为底部抽屉
- [ ] 移动端 MiniMap 缩小
- [ ] resize 窗口后画面正常（无拉伸/变形）

## 控制台

- [ ] 浏览器控制台无红色错误
- [ ] 无 "Cannot read property of undefined" 类错误
- [ ] 无 WebGL context 警告
