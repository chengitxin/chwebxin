# WebGb 新闻网站内容发布管理系统（Windows 便携版）

开箱即用的新闻门户 + 内容管理后台。整包内置 Node.js 运行时、Next.js 构建产物、SQLite 数据库与 NSSM 服务封装，**无需安装 Node.js、无需联网**，复制目录即可运行。

- 前台：新闻浏览、栏目、搜索、头条轮播、音乐播放、视频/剧集播放
- 后台：内容、头条、栏目、首页版块、站点设置、用户、音乐、视频管理
- 部署：直接命令行启动，或注册为 Windows 服务实现开机自启、崩溃自动重启

---

## 一、目录结构

```
WebWin/
├─ service.js              # 便携版启动器：注入环境变量后加载 app/server.js
├─ 安装为服务.bat          # 管理员运行：注册并启动 Windows 服务（默认端口 80）
├─ 卸载服务.bat            # 停止并移除服务（保留全部文件）
├─ node/node.exe           # 内置 Node.js v26.13.0（x64）
├─ nssm/nssm.exe           # NSSM，Windows 服务封装工具
├─ app/
│  ├─ server.js            # Next.js standalone 服务入口（构建产物）
│  ├─ .next/               # 构建产物（页面、路由、服务端代码）
│  ├─ node_modules/        # 运行时依赖
│  ├─ public/
│  │  ├─ assets/           # 站点徽标
│  │  └─ uploads/          # 后台上传的图片/音乐/视频
│  ├─ package.json
│  └─ .env                 # 首次启动自动生成，已被 .gitignore 排除
├─ prisma/
│  ├─ schema.prisma        # 数据库模型
│  └─ data.db              # SQLite 数据文件（含现有站点数据）
└─ logs/                   # 服务运行日志（自动创建、自动轮转）
```

技术栈：Next.js 15（App Router / standalone）、React 19、TypeScript、Tailwind CSS 4、Prisma 6 + SQLite、NextAuth v5、Tiptap 3、bcryptjs、Zod。

---

## 二、安装与启动

### 1. 修改端口（可选）

用记事本打开 [安装为服务.bat](安装为服务.bat)，把第 7 行的 `set PORT=80` 改成实际要用的端口（如 `8080`）。
端口 80 容易被 IIS、其它 Web 服务占用，建议先确认空闲。

### 2. 安装并启动服务

双击运行 `安装为服务.bat`。脚本会自动请求管理员权限（UAC 弹窗点“是”），随后依次执行：停止并移除同名旧服务 → 重新安装 → 启动。

### 3. 访问站点

- 前台：`http://localhost:端口号`
- 后台：`http://localhost:端口号/admin`
- 局域网：`http://本机IP:端口号`（需在防火墙放行该端口）

脚本实际执行的动作（便于排查）：

| 配置项 | 值 |
| --- | --- |
| 服务名 | `WebGbPortable` |
| 可执行程序 | `node\node.exe` + 参数 `service.js` |
| 工作目录 | 项目根目录 |
| 启动类型 | 自动（开机自启） |
| 失败处理 | 进程退出后 5 秒自动重启 |
| 日志 | `logs/service.out.log`、`logs/service.err.log`，单文件超 10MB 轮转 |

卸载服务：双击 [卸载服务.bat](卸载服务.bat)，或执行 `nssm\nssm.exe remove WebGbPortable confirm`。卸载只移除服务，**不会删除任何项目文件**。

---

## 三、首次启动做了什么

`service.js` 在加载 Next.js 之前完成三件事，因此不需要手工编辑任何配置：

1. **AUTH_SECRET**：优先读取 `app/.env`；不存在时随机生成 32 字节密钥并写入该文件，同时写入 `AUTH_TRUST_HOST=true`。
2. **DATABASE_URL**：按当前目录动态计算为 `file:<项目根>/prisma/data.db`，路径含空格也能正常工作。
3. **NODE_ENV / PORT / HOSTNAME**：默认 `production` / `3000` / `0.0.0.0`；安装为服务时 `PORT` 由 [安装为服务.bat](安装为服务.bat) 传入（默认 `80`）。

因为所有路径都是相对路径，整个目录可以随意换盘符、换机器、改文件夹名，无需改配置。

---

## 四、登录与账号

- 登录页：`/login`，注册页：`/register`
- 默认管理员账号（已随 `prisma/data.db` 内置）：

| 用户名 | 密码 | 角色 |
| --- | --- | --- |
| `admin` | `Admin@123` | `ADMIN` |
