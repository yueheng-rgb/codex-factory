# Architecture Scaling Check 提示词

> 当用户担心"starter 会不会限制 Codex"或"项目到底该用什么架构"时使用。

---

请对以下项目需求做架构体量评估：

## 项目需求

[在此描述项目需求]

## 输出要求

请输出：

### 1. 项目类型
根据 APP_TYPE_ROUTER 判断：（content-site / fullstack-admin / saas-tool / api-service / miniapp / mobile-app / threejs-interactive）

### 2. 项目体量等级
- **等级：** S / M / L / XL
- **判断理由：**

### 3. 风险等级
- **等级：** low / medium / high / extreme
- **判断理由：**

### 4. 默认 Starter
- **推荐 starter：**
- **为什么够：**
- **为什么不够：**（如果不够）

### 5. 是否建议升级架构
- **建议：** 保持 starter / 升级
- **升级到什么程度：**
- **升级理由：**

### 6. 哪些高级架构暂不需要
- [ ] 微服务
- [ ] 消息队列
- [ ] 多租户
- [ ] 支付
- [ ] 复杂 AI Pipeline
- [ ] 缓存层
- [ ] 对象存储
- [ ] WebSocket
- [ ] 其他

### 7. 第一阶段最小闭环
[用 2-3 句话描述用户能在第一版完成什么]

### 8. 后续扩展路径
1. [扩展方向 1]
2. [扩展方向 2]
3. [扩展方向 3]

---

## 注意事项

- starter 是默认安全起点，不是架构天花板
- Codex 可以建议更高级架构，但必须回答"为什么需要"
- Codex 不允许为了"专业感"默认堆复杂架构
- 如果需求很简单（S 级），必须主动压低复杂度
