# dsh-im-hold

`@xmanrui/dsh-im` 的本地补丁：**`/hold` 图文暂存** + **主动投递文件接口**。

> 这是对上游的补丁，不是独立插件。上游 issue 已在讨论（[xmanrui/dsh-im#385](https://github.com/xmanrui/dsh-im/issues/385)）；
> 如果被合并，本仓库即可弃用。

## 解决什么问题

微信个人号协议里图片和文字是两条消息。图片单独到达时，插件会自动用「请分析这张图片。」发起一个回合，
用户再补要求时那一轮已经跑完——「图 + 说明」永远变成两轮。

`/hold` 在消息进入批处理层之前把它们收在一起：

```
/hold             进入暂存：文字、图片、文件都只收不发
（发图 / 发文件 / 打字，回执「已暂存 N/10 项（文字 a 条、图片 b 张、文件 c 个）」）
/send             合成一条提交：文字按顺序作 [消息 N]，媒体作为附件一起带上
/cancel           丢弃
```

限制：10 项；图片合计 ≤ 20 张、文件合计 ≤ 10 个；仅私聊。暂存时图片立即下载，避免短时效链接过期。

## 附带：主动投递文件

```
POST /api/dsh-im/delivery/files
{"botId":"...","targetId":"...","path":"/absolute/path/file.pdf"}
→ {"sent":true,"fileName":"file.pdf"}
```

绝对路径、普通文件、≤ 30 MB；图片走 `sendImage`，其它走 `sendFile`。

覆盖渠道：微信、飞书（仅群聊目标）、企微、企微自建应用、钉钉、QQ、Telegram、Slack、Discord、
WhatsApp、Email、Matrix；iMessage 仅文字。

## 兼容性

| dsh-im 版本 | 状态 |
| --- | --- |
| 5.0.2 | ✅ 本补丁目标版本 |
| 5.1.0+ | ❌ 需要 rebase（上游改动较大，见 issue） |

## 安装

```bash
git clone https://github.com/weiza0v0/dsh-im-hold.git
cd dsh-im-hold
bash apply.sh
# 然后重启 dsh web
```

`apply.sh` 会：

1. 校验已安装版本是 5.0.2；
2. 备份并 `patch -p1` 应用 `patches/dsh-im-5.0.2.patch`（36 个源文件）；
3. 把预先构建好的 `dist/lib-index-5.0.2.js` 安装为 `lib/index.js`（校验 SHA-256）；
4. 提示重启。

自定义安装位置：

```bash
DSH_IM_PKG_DIR=/path/to/node_modules/@xmanrui/dsh-im bash apply.sh
```

### 卸载 / 回滚

```bash
cd ~/.dsh/profiles/web
rm -rf node_modules/@xmanrui/dsh-im
pnpm install --force
```

或者恢复安装时生成的 `*.bak_hold_<时间戳>` 备份文件。

### 与 pnpm install 的关系

`pnpm install` 可能把 dsh-im 重装成原版并冲掉补丁。装完插件/升级依赖后重新跑一次 `apply.sh`，
或在 profile 的 `package.json` 里加：

```json
"scripts": { "postinstall": "bash patches/dsh-im-hold/apply.sh || true" }
```

## 从源码重建

`lib/index.js` 是 esbuild 打出来的单文件 bundle，改 `src/` 必须重建：

```bash
cd build
npm install
DSH_IM_PKG_DIR="$HOME/.dsh/profiles/web/node_modules/@xmanrui/dsh-im" node build.mjs
```

细节见 `build/README.md`。

## 改动范围

- `src/channels/shared/batch-input.mjs`：`/hold` 状态机、条目结构、上限；
- `src/channels/shared/text-harness-bridge.mjs`：媒体接入收集器；
- 微信 / 飞书 / 企微 / 企微应用 / 钉钉 / QQ 六个桥的批处理入口；
- `plugin-src/host/delivery-{adapter,service,rpc,http}.mjs`：文件投递接口；
- 各渠道 runtime/controller：`sendProactiveFile`；
- 命令目录与英文翻译。

完整 diff 见 `patches/dsh-im-5.0.2.patch`。

## 安全

- 文件接口**没有鉴权、也没有 CORS**，只应在本机使用；
- 接口接受任意本地绝对路径（≤ 30 MB），不可信环境请自行加目录白名单或不要暴露 3080。

## 许可

MIT。修改与分发基于 [`@xmanrui/dsh-im`](https://github.com/xmanrui/dsh-im)（MIT），保留其版权声明。
