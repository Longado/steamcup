<p align="center"><img src="icon/icon-1024.png" width="112" alt="Steamcup"></p>

<h1 align="center">Steamcup</h1>
<p align="center"><strong>菜单栏里一只像素咖啡杯,让 Mac 不睡,合上盖子也不睡。</strong></p>
<p align="center">适合编译、下载、跑智能体这类要很久的活:让它接着跑,你合上电脑走开。</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue" alt="MIT"></a>
  <img src="https://img.shields.io/badge/tested%20on-macOS%2026-black" alt="tested on macOS 26">
  <img src="https://img.shields.io/badge/Swift-6-orange" alt="Swift 6">
  <img src="https://img.shields.io/badge/status-Alpha-orange" alt="Alpha">
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="docs/media/steamcup-intro.mp4">介绍视频(12 秒)</a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="#一起做">一起做</a>
</p>

<p align="center"><img src="docs/media/steamcup-hero.gif" width="960" alt="Steamcup:让 Mac 不睡,合上盖子也不睡。功能示意图。"></p>

大多数防睡眠工具只管「闲着别睡」,一合盖 Mac 照样睡。**Steamcup 合上盖子也能接着跑,而且一定会把它改回来。**

**点一下就开。合盖模式只输一次密码。Mac 过热或电量低,它自己停。**

## 是什么

一个原生的 macOS 菜单栏小程序,约 400 行 Swift,不依赖任何第三方库。点一下杯子,Mac 就不睡,杯子装满并冒热气;再点一下,恢复正常睡眠。右键是定时和选项。

MacBook 合上盖子就会睡,不管哪个程序怎么要求。唯一的办法是改一个全系统的开关 `pmset disablesleep`,要管理员权限。Steamcup 只在开着的时候改这个开关,下面几种情况都会改回来:
- 你关掉它、定时到点、或者退出
- Mac 过热,或电量降到 10%
- 它被强制退出过,下次启动时

> **早期版本。** 在一台装 macOS 26 的 Apple 芯片 MacBook 上手动测过(下载包也能在 Intel Mac 和 macOS 14 以上运行,但还没人试过):开关、定时、合盖模式开和关、正常退出和强制退出、锁屏暂停。还没测:macOS 14–15、Intel Mac、过热和低电量通知真的弹出来。见[已知问题](#已知问题)。

## 怎么用

| 你…… | Steamcup 会…… |
| --- | --- |
| 点杯子 | 让 Mac 和屏幕都不睡(电源断言,和 `caffeinate -d` 一样);再点一下停 |
| 右键 → For 30 minutes … 4 hours | 在杯子旁显示剩余时间(`0:30`),到点自己停,中间睡过也照样准 |
| 勾上 **Keep Awake with Lid Closed** | 第一次会要一次管理员密码;之后开着时杯子上有把小锁,合盖不再让 Mac 睡 |
| Mac 太热时合盖,或用电池到 10% | 15 秒内停掉合盖模式,并弹一条通知 |
| 勾上 **Let the Screen Turn Off** | 屏幕可以熄,Mac 接着跑 |
| 勾上 **Sleep When Screen Locks** | 锁屏时松手,解锁后按原来的结束时间接着来 |
| 任何地方按 **⌃⌥W** | 开或关,刘海挡住杯子时用得上 |

## 可以试试这些

- 点杯子,在终端跑 `pmset -g assertions | grep Steamcup` → 看到 `Steamcup is on`。再点一下 → 没了。
- 右键 → **For 30 minutes** → 杯子旁出现 `0:30`,开始倒数。
- 勾上 **Keep Awake with Lid Closed**,点杯子,跑 `pmset -g | grep SleepDisabled` → 看到 `SleepDisabled 1`。点掉杯子 → 这一行没了。
- 合盖模式开着时放首歌,合盖 30 秒 → 歌一直在放。

## 安全吗

- **管理员那一步允许什么:** 只加一个文件 `/etc/sudoers.d/steamcup`,让你的用户不输密码就能跑两条命令:`pmset -a disablesleep 1` 和 `pmset -a disablesleep 0`,别的都不行。装之前先用 `visudo` 检查过规则。可以读 [setup-lid-mode.sh](setup-lid-mode.sh),一共 24 行。
- **发热:** 合着盖子放在包里的 MacBook 会热。合盖模式开着时 Steamcup 每 15 秒查一次,macOS 报告严重过热就停。
- **强制退出:** 合盖时 Steamcup 被强行杀掉,Mac 会一直醒着,直到 Steamcup 再次启动。打开合盖模式时会顺带打开登录时启动,所以最迟下次登录就会恢复。
- **全部撤销:** `sudo pmset -a disablesleep 0 && sudo rm /etc/sudoers.d/steamcup`。
- **联网:** Steamcup 不发任何网络请求。

## 和别的工具比

| | Steamcup | [KeepingYouAwake](https://github.com/newmarcel/KeepingYouAwake) | [Amphetamine](https://apps.apple.com/us/app/amphetamine/id937984704?mt=12) |
| --- | --- | --- | --- |
| 价格 / 源码 | 免费,MIT | 免费,MIT | 免费,不开源 |
| 合盖不睡 | 能,输一次密码 | 不能([#258](https://github.com/newmarcel/KeepingYouAwake/issues/258)、[#262](https://github.com/newmarcel/KeepingYouAwake/issues/262)) | 能;Apple 芯片要另装 Power Protect 插件 |
| 锁屏时让它睡 | 能 | 不能([#98](https://github.com/newmarcel/KeepingYouAwake/issues/98)) | 有锁屏相关选项 |
| 图标旁显示剩余时间 | 能 | 不能([#154](https://github.com/newmarcel/KeepingYouAwake/issues/154)) | 没找到 |
| 全局快捷键 | ⌃⌥W | 没有 | 有 |

## 快速开始

### 方式 A:让你的 AI 帮你装

把这段贴进 Claude Code 或 Codex:

```text
帮我从 https://github.com/Longado/steamcup 安装 Steamcup。
1. 先读它的 README。
2. 确认 `xcode-select -p` 能用,macOS 是 14 或更新。
3. 克隆,运行 ./build.sh,把 Steamcup.app 移到 /Applications。
4. 打开它。如果 macOS 说无法验证开发者,告诉我去
   系统设置 → 隐私与安全性,点「仍要打开」。
5. 告诉我点菜单栏里的杯子试试;第一次勾合盖模式时会要一次管理员密码。
```

### 方式 B:自己装

需要 Xcode 命令行工具(`xcode-select --install`)和 macOS 14 或更新。

```sh
git clone https://github.com/Longado/steamcup
cd steamcup
./build.sh
mv Steamcup.app /Applications/
open /Applications/Steamcup.app
```

这个程序还没做 Apple 公证。如果下载的是发布包而不是自己编译,第一次打开会被拦:去 **系统设置 → 隐私与安全性**,点 **仍要打开**([Apple 说明](https://support.apple.com/zh-cn/102445))。

## 已知问题

- 点 Dock 图标不再开关:macOS 分不清「点 Dock」和「从访达或聚焦再次打开」。请用杯子、⌃⌥W 或 Dock 图标的右键菜单。
- 合盖时被强制退出,要等 Steamcup 下次启动才恢复(见[安全吗](#安全吗))。
- 过热和低电量停止只测了判断逻辑,还没在真的很热或快没电的 Mac 上看到它触发。

## 一起做

**合盖不睡这件事,能不能放心交给一个小程序?** Steamcup 想用一份小而好读的代码和硬性的安全停止来回答。

| 你喜欢…… | 可以贡献 |
| --- | --- |
| 在别的 Mac 上试 | 在 macOS 14–15 或 Intel MacBook 上试,告诉我们结果 |
| 研究 macOS 内部 | 找一个不用后台助手、强制退出后也能恢复合盖睡眠的办法 |
| 写脚本 | 加一个 `steamcup://on?minutes=120` 链接,给快捷指令和脚本用 |
| 像素画 | 改进 `icon/make_menubar.py` 里 18 像素的菜单栏图标 |
| 写字 | 翻译菜单里那几句话 |

欢迎提 issue 或 pull request。

## 开发

```sh
./build.sh                                   # 编出 Steamcup.app(Apple 芯片和 Intel 通用,macOS 14 起),ad-hoc 签名
ditto -c -k --norsrc --noextattr --keepParent Steamcup.app Steamcup.zip   # 发布用压缩包
swiftc Rules.swift tests/main.swift -o /tmp/steamcup-tests && /tmp/steamcup-tests
python3 icon/make_icon.py                    # 应用图标
python3 icon/make_menubar.py                 # 菜单栏图标(关 / 开 / 合盖)
```

`main.swift` 是菜单栏程序,`Power.swift` 管电源断言、合盖睡眠开关和电量读取,`Rules.swift` 放测试要检查的纯判断。

## 许可证

[MIT](LICENSE) © Yutai Lin
