# vite-threejs-interactive — Three.js Interactive Web Prototype Starter

> 一个通用 Vite + TypeScript + Three.js 交互式 Web 原型骨架。
> 用于 3D 交互场景、虚拟房间、展厅、线索场景、地图原型。

## 适合项目

- 3D 交互式 Web 原型
- 虚拟房间 / 展厅 / 场景漫游
- 线索/剧本杀类交互场景
- 可点击物体的轻量 Web 原型
- 地图 / 房间布局交互原型
- 游戏化 Web 原型

## 不适合项目

- 复杂 3D 游戏（需游戏引擎）
- 多人联机场景
- 语音/音视频会议
- 物理模拟（需物理引擎）
- 大型开放世界
- Blender/GLTF 模型依赖项目
- 纯后端 / API 服务

## 默认体量等级

**M** — 中等体量。第一版做单一场景 + 可交互对象。

## 升级条件

- 多场景切换 → 增加场景管理器
- 任务/背包/线索系统 → 增加状态管理层
- 后端状态同步 → 接 `node-api-postgres` 或 `next-fullstack-admin`
- 多人同步 → 需 WebSocket/CRDT
- 复杂模型 → 引入 GLTF loader + CDN 托管

## 目录说明

```
vite-threejs-interactive/
├── README.md / AGENTS.md / PROJECT_BRIEF.md
├── package.json / tsconfig.json / vite.config.ts
├── index.html / .env.example / src/styles.css
├── src/
│   ├── main.ts                # 入口，bootstrap scene + UI
│   ├── types/index.ts         # SceneObject, AppState 等类型
│   ├── scene/                 # Three.js 场景层
│   │   ├── createScene.ts     # 创建 Scene
│   │   ├── createCamera.ts    # 创建 PerspectiveCamera
│   │   ├── createRenderer.ts  # 创建 WebGLRenderer
│   │   ├── createLights.ts    # 灯光
│   │   ├── createObjects.ts   # low-poly placeholder 对象
│   │   ├── interaction.ts     # Raycaster hover/click
│   │   ├── animationLoop.ts   # 渲染循环
│   │   └── resize.ts          # 窗口 resize 处理
│   ├── ui/                    # 原生 DOM UI 层
│   │   ├── hud.ts             # HUD（项目名/模式/提示）
│   │   ├── panel.ts           # 右侧信息面板
│   │   ├── minimap.ts         # 小地图占位
│   │   └── toast.ts           # Toast 通知
│   ├── state/                 # 状态管理
│   │   ├── appState.ts        # 选中/悬停/模式/消息
│   │   └── sceneObjects.ts    # 场景对象 registry
│   └── utils/
│       ├── dom.ts             # DOM 工具函数
│       └── objectGuards.ts    # 对象安全访问
└── tests/smoke-checklist.md
```

## 如何复制使用

```powershell
C:\Codex_App_Factory\scripts\create-project-from-starter.ps1 `
  -StarterName vite-threejs-interactive `
  -TargetPath C:\Projects\my-scene `
  -ProjectName my-scene
```

## 如何运行

```bash
npm install
npm run dev         # 开发模式（Vite HMR）
npm run typecheck   # TypeScript 类型检查
npm run build       # 生产构建
npm run preview     # 预览构建产物
```

## Three.js 场景结构

- **Scene** — 深色背景（`#1a1a2e`）
- **Camera** — PerspectiveCamera，60° FOV，位置 (0, 3, 8)
- **Renderer** — WebGLRenderer + 阴影
- **Lights** — AmbientLight + DirectionalLight（带阴影）
- **Ground** — 灰色平面地板
- **Objects** — 3 个 low-poly placeholder：圆桌、线索盒、上锁的门

## 场景对象 Registry

`src/state/sceneObjects.ts` 维护所有可交互对象：

```ts
{
  id: "room_table",
  name: "圆桌",
  type: "furniture",
  description: "...",
  status: "default",
  position: { x: 0, y: 0, z: -2 },
  color: 0x8b5e3c,
  selectable: true,
  metadata: {},
}
```

## Raycaster 交互

- **Hover** — 指针划过物体时触发高亮
- **Click** — 点击物体选中，打开右侧 Panel
- **Click empty** — 点击空白取消选择
- 交互层与 UI 层分离（`interaction.ts` 只做拾取和状态更新）

## UI 层说明

- **HUD** — 顶部：项目名 + 交互模式 + 提示
- **Panel** — 右侧：空状态 / 对象详情 + "标记已查看" 按钮
- **MiniMap** — 右下：对象位置点阵图
- **Toast** — 底部居中：操作反馈通知

## 如何扩展

1. **添加对象**：在 `sceneObjects.ts` 的 `INITIAL_OBJECTS` 添加条目，在 `createObjects.ts` 添加对应的几何体创建函数
2. **添加场景**：创建新的 `sceneObjects` 数据集，在 `createObjects` 中按 `currentSceneId` 切换
3. **接后端**：使用 `node-api-postgres` starter 创建 API，在 `main.ts` 中 fetch 数据替换 mock 对象
4. **多人同步**：先确保单机交互闭环正确，再引入 WebSocket

## 如何避免变成纯视觉 demo

- 必须保证 750+ 可点击对象注册在 registry 中
- 必须保证点击 → Panel 更新 → 状态变更 → Toast 反馈闭环
- 每增加视觉华丽度前，先确认交互闭环可用
- 不要做"只能看不能点"的场景

## 如何避免过度设计

- 第一版不做多场景
- 第一版不做 GLTF 模型加载
- 第一版不做物理引擎
- 第一版不做多人
- 第一版不做语音
- 第一版不做复杂任务/背包系统

## 第一阶段验收标准

- `npm run dev` 能启动，canvas 可见
- 场景中有 ground + 3 个 placeholder objects
- HUD / Panel / MiniMap 可见
- hover 对象有高亮反馈
- click 对象能选中，Panel 更新
- 点击空白取消选择
- 点击"标记已查看"更新状态
- Toast 显示反馈
- 移动端不横向溢出
- `npm run typecheck` 通过
- `npm run build` 通过
