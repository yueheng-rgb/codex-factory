# Auth & Permission Security

## 用途
设计安全的登录、注册、权限系统。
**默认不开放注册。** **密钥永远不放前端。**

## 使用场景
- 需要用户系统的项目
- 需要权限控制的项目
- 涉及微信登录的小程序

## 登录系统设计

### 默认策略
```
注册：默认不开放注册，由管理员手动创建账号
登录：用户名/邮箱 + 密码
密码：bcrypt 哈希（cost=12），永不存明文
Token：JWT（短期 15min-2h）+ Refresh Token
```

### 如果必须开放注册
需要用户确认后再加上，且：
- 至少要求邮箱 + 验证码
- 密码最少 8 位，含大小写+数字
- 注册要有限速（同 IP 每小时 3 次）

## 权限模型

### RBAC（角色-权限）
```
User → UserRole → Role → RolePermission → Permission
```

**第一版只做：**
- 管理员（admin）：全部权限
- 普通用户（user）：基本 CRUD 自己的数据

**不要第一版就做：**
- 细粒度的自定义权限
- 数据行级权限
- 权限模板

## 服务端校验（核心铁律）

```
❌ 前端隐藏按钮 ≠ 权限控制
❌ 前端路由守卫 ≠ 权限控制
✅ 每个需要权限的 API 都必须在服务端校验
✅ 权限从认证 token 中获取，不信任前端参数
```

### API 权限保护示例
```typescript
// 中间件
function requireRole(...roles: string[]) {
  return (req, res, next) => {
    const user = getCurrentUser(req); // 从 token 解析
    if (!roles.includes(user.role)) {
      return res.status(403).json({
        success: false,
        error: { code: 'FORBIDDEN', message: '无权限' }
      });
    }
    next();
  };
}

// 使用
router.delete('/api/users/:id', requireRole('admin'), deleteUser);
```

## 安全清单

### 密码安全
- [ ] 密码用 bcrypt/argon2 哈希存储
- [ ] 不记录明文密码到日志
- [ ] 重置密码需要验证身份

### Token 安全
- [ ] Token 有过期时间
- [ ] Token 不存前端 localStorage（用 httpOnly cookie 或 secure store）
- [ ] 401 时前端重新登录

### 密钥安全
- [ ] AppSecret / API Key 只存后端环境变量
- [ ] 小程序 code2session 只在服务端调用
- [ ] .env 文件加入 .gitignore

### 防护措施
- [ ] 登录接口限速（防暴力破解）
- [ ] 敏感操作记日志（删除、修改权限等）
- [ ] 账号禁用后立即生效（token 失效）
- [ ] 登出后 token 失效

## 常见错误
- ❌ 密码明文存储
- ❌ 权限只在前端控制
- ❌ AppSecret 写在前端代码
- ❌ 没有登录限速
- ❌ Token 永不过期
- ❌ 删除用户后 token 仍有效

## 输出格式
```
## 权限设计

### 角色定义
- admin：[权限列表]
- user：[权限列表]

### 认证流程
1. [步骤]
2. [步骤]

### 安全措施
- [ ] 密码哈希
- [ ] Token 管理
- [ ] 密钥保护
- [ ] 限速
- [ ] 日志
```
