# AGENTS.md — vite-threejs-interactive Starter

## 这是什么

`vite-threejs-interactive` 是 Vite + TypeScript + Three.js 交互式 Web 原型骨架。
用于 threejs-interactive / 3d-web-prototype / interactive-scene 类型项目。

## 适合项目

- 3D 交互 Web 原型、虚拟房间、展厅、线索场景、地图、可点击物体

## 不适合项目

- 复杂 3D 游戏、多人联机、语音房、物理模拟、大型开放世界

## 使用前规则

1. 先读取 `C:\Codex_App_Factory`
2. 先走 Project Expertise Flow + architecture-scaling-ladder 判体量
3. 第一版只做：1 个场景 + 3 个可交互对象 + HUD/Panel/MiniMap
4. 不要下载外部模型（GLTF/FBX/OBJ）
5. 不要引入外部贴图/图片
6. 不要添加物理引擎（cannon/rapier）
7. 不要第一阶段做多人联机/语音
8. 交互逻辑必须与 UI 分离
9. 对象必须通过 registry 管理，不靠 mesh.name 硬编码
10. 先用 low-poly placeholder 跑通交互闭环，再替换为实际模型
