/**
 * 便携版服务启动器（nssm 调用）
 * 原因：Next.js standalone 的 app/server.js 不会读取 .env 文件，
 * 必须在进程启动前把 AUTH_SECRET / DATABASE_URL 等注入环境变量；
 * 路径可能含空格，所以不通过 nssm 的 AppEnvironmentExtra 传路径。
 */
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const root = __dirname;
const envFile = path.join(root, "app", ".env");

function loadSecret() {
  if (process.env.AUTH_SECRET) return process.env.AUTH_SECRET;
  try {
    const text = fs.readFileSync(envFile, "utf8");
    const m = text.match(/^AUTH_SECRET=(.+)$/m);
    if (m && m[1].trim()) return m[1].trim();
  } catch {
    // 首次运行没有 .env，走下面的生成逻辑
  }
  const secret = crypto.randomBytes(32).toString("hex");
  fs.writeFileSync(envFile, "AUTH_SECRET=" + secret + "\r\nAUTH_TRUST_HOST=true\r\n");
  return secret;
}

process.env.AUTH_SECRET = loadSecret();
process.env.AUTH_TRUST_HOST = "true";
process.env.DATABASE_URL = "file:" + path.join(root, "prisma", "data.db").replace(/\\/g, "/");
process.env.NODE_ENV = "production";
if (!process.env.PORT) process.env.PORT = "3000";
if (!process.env.HOSTNAME) process.env.HOSTNAME = "0.0.0.0";

require(path.join(root, "app", "server.js"));
