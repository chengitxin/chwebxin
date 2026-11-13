# WebGb 新闻网站内容发布管理系统（Windows 便携版）

开箱即用的新闻门户 + 内容管理后台。整包内置 Node.js 运行时、Next.js 构建产物、SQLite 数据库与 NSSM 服务封装，**无需安装 Node.js、无需联网**，复制目录即可运行。

- 前台：新闻浏览、栏目、搜索、头条轮播、音乐播放、视频/剧集播放
- 后台：内容、头条、栏目、首页版块、站点设置、用户、音乐、视频管理
- 部署：直接命令行启动，或注册为 Windows 服务实现开机自启、崩溃自动重启

---

## 一、技术栈

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

卸载服务：双击 [卸载服务.bat](卸载服务.bat)，或执行 `nssm\nssm.exe remove WebGbPortable confirm`。卸载只移除服务，**不会删除任何项目文件**。

---

## 三、登录与账号

- 登录页：`/login`，注册页：`/register`
- 默认管理员账号（已随 `prisma/data.db` 内置）：
- 用户名：admin       密码：Admin@123
