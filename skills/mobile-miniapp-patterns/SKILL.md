# Mobile & MiniApp Patterns

## 用途
为小程序、H5、App 设计专业的移动端页面结构、API 调用、登录态管理、弱网处理、密钥安全。
**不要把 PC 后台强行压缩成手机页面。**

## 使用场景
- 微信小程序项目
- H5 移动端页面
- Expo/React Native App
- uni-app 跨端项目

## 页面结构设计

### 小程序页面结构
```
app.json → 全局配置（窗口、TabBar、权限）
pages/
  index/      → 首页（列表/入口）
  detail/     → 详情页
  user/       → 用户中心
```

### App 页面结构（Expo Router）
```
app/
  (tabs)/
    index     → 首页
    profile   → 我的
  detail/[id] → 详情（Stack）
  (auth)/
    login     → 登录
```

### 设计原则
- ✅ 一屏一个核心操作
- ✅ 信息层级不超过 3 层
- ✅ 按钮在屏幕下半部（拇指热区）
- ❌ 不要把 PC 的侧边栏 + 表格搬到手机上
- ❌ 不要一个页面超过 2 屏滚动
- ❌ 不要横向滚动表格

## API 调用规范

### 封装要求
```javascript
// 统一的 API 请求封装
const api = {
  baseUrl: 'https://api.example.com',
  token: null,
  
  async request(method, path, data) {
    try {
      const res = await fetch(this.baseUrl + path, {
        method,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.token}`
        },
        body: data ? JSON.stringify(data) : undefined
      });
      
      if (res.status === 401) {
        // token 过期 → 重新登录
        await this.refreshToken();
        return this.request(method, path, data);
      }
      
      const json = await res.json();
      if (!json.success) throw new ApiError(json.error);
      return json.data;
    } catch (err) {
      if (err.name === 'TypeError') {
        throw new ApiError({ code: 'NETWORK_ERROR', message: '网络异常' });
      }
      throw err;
    }
  }
};
```

## 登录态管理

### 小程序登录
```
1. 前端：wx.login() → 获取 code
2. 前端：发 code 给后端
3. 后端：用 code 调微信 code2session → 获取 openid
4. 后端：生成自定义 token → 返回给前端
5. 前端：存 token → 后续请求带 token
```

### App 登录
```
1. 用 expo-secure-store 存 token（比 AsyncStorage 安全）
2. API 拦截器自动附加 token
3. 401 → 跳转登录页
4. 退出登录 → 清除 token
```

## 弱网处理
- [ ] 请求超时设置（10-15s）
- [ ] 网络错误提示（不是"未知错误"）
- [ ] 重试按钮
- [ ] 离线提示
- [ ] 骨架屏/loading（不要让用户干等）

## 密钥安全
- ❌ AppSecret 放小程序代码（明文）
- ❌ API Key 放前端
- ❌ 支付密钥放前端
- ✅ 所有密钥只在服务端
- ✅ 前端只拿 token

## 常见错误
- ❌ 把 PC 后台的复杂表格搬到手机
- ❌ 小程序包过大（超过 2MB 限制）
- ❌ 图片不压缩/不懒加载
- ❌ 没做安全区域适配（刘海屏）
- ❌ 弱网时白屏无提示
- ❌ 登录态过期不处理

## 输出格式
```
## 移动端设计

### 页面结构
[页面树]

### 登录方案
[描述]

### 弱网策略
- timeout: ...
- 错误提示: ...
- 重试: ...

### 安全清单
- [ ] 密钥在服务端
- [ ] Token 安全存储
```
