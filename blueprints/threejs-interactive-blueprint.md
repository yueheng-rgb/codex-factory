# Three.js Interactive Blueprint

## 用户需求拆解

当用户说"做一个 3D XX"时，按以下步骤拆解：

### 最少必要问题
1. 3D 场景的目的是什么？（展示 / 交互 / 数据可视化）
2. 用户能干什么？（旋转查看 / 点击交互 / 漫游行走）
3. 场景里有什么物体？（建筑 / 产品 / 数据点）
4. 需要 UI 面板吗？（信息展示 / 操作按钮）
5. 移动端需要吗？

### 不能默认乱加的内容
- ❌ 不要默认加物理引擎
- ❌ 不要默认加复杂粒子效果
- ❌ 不要默认加后期处理（post-processing）
- ❌ 不要默认加 VR/AR
- ❌ 不要默认加骨骼动画

## 第一版页面/场景结构

```
index.html 或 App.tsx
  ├── Three.js Canvas（3D 渲染区）
  │   ├── Scene（场景）
  │   ├── Camera（OrbitControls，限制范围）
  │   ├── Lights（环境光 + 平行光）
  │   └── Objects（至少 1 个可交互物体）
  └── UI Overlay（2D 覆盖层）
      ├── 标题/信息面板
      └── 操作按钮
```

## 第一版数据结构

```typescript
// 场景对象定义（可放 JSON 或 TypeScript）
interface SceneObject {
  id: string;
  type: 'product' | 'building' | 'marker';
  position: [number, number, number];
  rotation?: [number, number, number];
  scale?: [number, number, number];
  metadata: {
    name: string;
    description: string;
    // ...
  };
}
```

## 第一版交互流程

```
用户打开页面
  → 看到 3D 场景加载（loading 状态）
  → 场景加载完成
  → 可以用鼠标/触控旋转、缩放场景
  → hover 物体 → 高亮效果
  → click 物体 → UI 面板显示物体信息
  → 点击关闭按钮 → 面板关闭
```

## 第一版运行方式

```bash
npm install
npm run dev       # Vite 开发服务器
# 浏览器打开 http://localhost:5173
```

## 后续扩展方向
- 多个场景切换
- 动画/过渡效果
- 加载 3D 模型文件（glTF/GLB）
- 粒子效果
- 后期处理
- 性能优化（LOD）
