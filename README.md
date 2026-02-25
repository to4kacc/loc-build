# 🚀 Loc-Build: OpenWRT 全自动编译流水线

[![Version](https://img.shields.io/badge/Version-7.5_Pro-green?style=flat-square)](https://github.com/breeze303/loc-build)
[![Style](https://img.shields.io/badge/Style-Minimalist-blue?style=flat-square)](https://github.com/breeze303/loc-build)

**Loc-Build** 是一款面向专业用户的 OpenWRT/ImmortalWrt 极简编译框架。它通过自研的 TUI 仪表盘，将环境修复、源码同步、插件管理及定时调度整合为一体，提供丝滑的本地编译体验。

---

## ⚡ 极速部署 (One-Click)

在任意 Ubuntu/Debian 终端运行：

```bash
bash <(curl -sL https://raw.githubusercontent.com/breeze303/loc-build/main/Install.sh)
```

---

## ✨ 核心亮点

- **🌈 极简 TUI 控制台 (`Build.sh`)**: 支持箭头/数字双模操作，实时监控系统负载与内存。
- **🛡️ 智能环境守卫**: 自动检测并一键修复编译所需的 Linux 依赖。
- **📦 插件系统分离**: 插件管理完全配置化，核心与自定义插件互不干扰。
- **🚀 颗粒度缓存管理**: 自由勾选要保留的缓存目录，二次编译仅需数分钟。
- **⏰ 自动化调度**: 交互式设置定时任务，支持多机型全自动流水线。
- **🌍 多语言支持**: 内置中英文切换，适配不同操作环境。

---

## 🛠️ 进阶配置指南

本项目遵循“**数据与逻辑彻底分离**”原则，你只需修改 `Config/` 下的文件即可完成所有定制：

### 1. 源码仓库管理 (`Config/REPOS.txt`)
格式: `显示名称 仓库URL`
> 示例: `Lean https://github.com/coolsnowwolf/lede.git`

### 2. 插件列表管理
- **核心插件**: `Config/CORE_PACKAGES.txt`
- **自定义插件**: `Config/CUSTOM_PACKAGES.txt`
> 格式: `包名 仓库 分支 [特殊模式] [冲突包]`

### 3. 全局公用配置 (`Config/GENERAL.txt`)
这里的 `.config` 片段会自动合并到**所有**机型的编译配置中。

### 4. 机型专属配置 (`Config/Profiles/`)
将每个机型的 `.config` 文件（.txt 格式）放入此目录，仪表盘会自动识别并生成选择列表。

---

## 📂 目录结构

```text
/
├── Build.sh            # 核心控制台入口
├── Install.sh          # 一键安装/更新引导
├── Scripts/
│   ├── Ui.sh           # 视觉引擎 & 翻译字典
│   ├── Auto.sh         # 自动化流水线执行器
│   ├── Packages.sh     # 插件下载引擎
│   └── Update.sh       # 代码同步工具
└── Config/
    ├── Auto.conf       # 自动化流水线持久化参数
    └── Profiles/       # 机型配置文件存放处
```

---

**Built with ❤️ by breeze303 | Powered by Loc-Build V7.5**
