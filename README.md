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

常用维护命令（管理员命令行）：

```bat
net start WebGbPortable     :: 启动
net stop  WebGbPortable     :: 停止
sc query  WebGbPortable     :: 查看状态
```

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

> 这是随仓库发布的默认凭证，**正式对外部署前请立即修改**；仓库包含 `data.db`，若公开仓库等同于公开该密码。
> 修改方式：先 `/register` 注册新管理员账号 → 停止服务 → 将其 `role` 改为 `ADMIN`（见下方 SQL）→ 启动服务登录，再按需处理旧账号。

- 角色共五种：`ADMIN`（管理员）、`EDITOR`（编辑）、`MUSIC_ADMIN`（音乐管理员）、`VIDEO_ADMIN`（视频管理员）、`USER`（普通用户），由管理员在后台「用户管理」中调整
- 新注册账号的角色为 `USER`。需要提升权限或增加管理员时，停止服务后用 SQLite 工具（如 DB Browser for SQLite）打开 `prisma/data.db` 执行：

```sql
UPDATE User SET role = 'ADMIN' WHERE username = '目标用户名';
```

- 密码以 bcrypt 哈希存储，无法反解、也不能在库里直接写明文。忘记密码时，推荐注册新账号并按上面的 SQL 提权，再用新账号登录后台。

---

## 五、配置说明

### 环境变量（一般无需修改）

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `PORT` | `80`（`安装为服务.bat` 第 7 行；未传入时 `service.js` 兜底 `3000`） | HTTP 监听端口 |
| `HOSTNAME` | `0.0.0.0` | 监听地址，`0.0.0.0` 表示允许局域网访问 |
| `DATABASE_URL` | 自动指向 `prisma/data.db` | SQLite 连接串，由 `service.js` 注入 |
| `AUTH_SECRET` | 自动生成并写入 `app/.env` | NextAuth 会话签名密钥 |
| `NODE_ENV` | `production` | 运行模式 |
| `KEEP_ALIVE_TIMEOUT` | 未设置 | 可选，HTTP 长连接超时（毫秒） |

### 站点配置

站点标题、副标题、徽标、导航样式、页头元素开关、首页轮播间隔与切换效果、各列表分页条数、页脚备案信息、整站主题、视频采集 KEY 等，全部在后台 **系统设置** 中修改，保存在数据库 `Config` 表，修改后立即生效。

---

## 六、主要页面与接口

| 前台页面 | 说明 |
| --- | --- |
| `/` | 首页（头条轮播、大图轮播、图文卡/文字卡版块、广告位） |
| `/topics/[id]` | 栏目列表页 |
| `/entries/[id]` | 新闻详情页（含点击量统计） |
| `/search` | 站内搜索 |
| `/music`、`/music/album/[id]` | 音乐库、专辑详情与播放 |
| `/video`、`/video/series/[id]` | 视频库、剧集详情与分集播放 |
| `/login`、`/register` | 登录、注册 |

| 后台页面 | 说明 |
| --- | --- |
| `/admin` | 概览 |
| `/admin/entries`、`/admin/entries/new` | 内容管理、新建/编辑新闻（Tiptap 富文本、封面上传） |
| `/admin/headline` | 头条管理（上下架、排序、定时生效窗口） |
| `/admin/topics` | 栏目管理（导航显示、排序、外链地址） |
| `/admin/sections` | 首页版块与广告位编排 |
| `/admin/music`、`/admin/album` | 音乐、专辑管理 |
| `/admin/video`、`/admin/series` | 视频、剧集与分集管理 |
| `/admin/users` | 用户与角色管理 |
| `/admin/settings` | 站点设置 |

| 接口 | 说明 |
| --- | --- |
| `/api/auth/[...nextauth]` | 认证 |
| `/api/upload` | 图片/音频/视频上传（写入 `app/public/uploads`） |
| `/api/asset/[...path]` | 上传资源访问 |
| `/api/provide/vod` | 视频聚合站采集接口，需先在后台设置中填写 `vodApiKey`，留空则关闭 |
| `/api/cast/discover`、`/api/cast/control` | 投屏设备发现与控制 |

---

## 七、数据备份与迁移

需要备份的只有两处：

- `prisma/data.db` —— 全部业务数据（用户、栏目、新闻、音乐、视频、站点配置）
- `app/public/uploads/` —— 上传的图片、音频、视频

推荐操作顺序：**先停止服务** → 复制 `prisma/data.db` 与 `app/public/uploads`（或整个目录）→ 到新机器粘贴 → 启动服务。

> 直接热复制 SQLite 文件可能在写入过程中产生不一致，务必先停服务（`net stop WebGbPortable`）。

若在后台设置中开启了「删除内容时同步清理上传文件」，删除新闻/音乐会连带删除磁盘文件，操作前请先备份。

---

## 八、从源码重新构建

本仓库保存的是**构建产物**，`app/server.js`、`app/.next`、`app/node_modules` 均由源码工程执行 `next build`（`output: "standalone"`）后拷贝而来。仓库内不包含 `src/`、`next.config.ts`、`prisma/migrations`，因此**不能在此基础上直接改代码**。

需要修改功能时，请回到源码工程执行：

```bash
npm ci
npx prisma generate
npm run build
```

然后把构建产物覆盖到 `app/`：

1. `.next/standalone/` 下的全部内容 → 覆盖 `app/`
2. 源码的 `public/` → 覆盖 `app/public/`（注意保留 `uploads/`）
3. `prisma/schema.prisma` 更新到 `prisma/`

注意：`app/server.js` 中内嵌了构建时的 `outputFileTracingRoot`（原为 `E:\WebWin`）。换机器重新构建后必须整份替换 standalone 产物，不要只替换部分文件。

---

## 九、常见问题

**1. 服务启动失败 / 页面打不开**
先看 `logs/service.err.log`。常见原因：端口被占用、非管理员权限运行 bat、杀毒软件拦截 `node.exe`。

**2. 80 端口被占用**
`netstat -ano | findstr :80` 找到占用进程，或把 bat 中的 `PORT` 改成 `8080` 后重新运行 `安装为服务.bat`（脚本会先移除旧服务再重装）。

**3. 局域网其它机器访问不了**
确认 bat 中端口已放行 Windows 防火墙；`HOSTNAME` 保持 `0.0.0.0`；用 `http://服务器IP:端口` 访问。

**4. 升级或换机后所有人都要重新登录**
`app/.env` 中的 `AUTH_SECRET` 变了（该文件未随仓库提交、或首次启动重新生成）。把原机器的 `app/.env` 一并复制过去即可保持会话。

**5. 上传的图片/音视频 404**
`app/public/uploads` 未随目录一起复制，或迁移时只复制了数据库。

**6. 后台上传大文件失败**
`next.config` 中图片优化已关闭（`unoptimized`），但请求体仍有大小限制；超大视频建议先手工放入 `app/public/uploads/medias/` 再用后台「扫描补录」（如后台提供）或直接入库。

---

## 十、安全提示

- `app/.env` 含真实 `AUTH_SECRET`，已加入 `.gitignore`，**请勿提交或外发**。
- `prisma/data.db` 含用户密码哈希与全部业务数据，且内置默认管理员 `admin / Admin@123`；上线前必须修改密码，公开仓库前请先评估是否移除该文件（移除后首次运行将没有表结构，需要额外初始化）。
- `node/node.exe` 为 95 MB 的单文件，接近 GitHub / Gitee 的 100 MB 单文件限制，推送失败时请改用 Git LFS 或将该目录排除。
- 对外提供访问时建议在前面加一层 Nginx/Caddy 反向代理并启用 HTTPS，不要长期直接暴露 80 端口。
- 本项目未附带开源许可证文件，如需开源请自行补充 `LICENSE`。
