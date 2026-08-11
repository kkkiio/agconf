# Homebrew tap bootstrap

`agconf` 尚无 Git tag 或 GitHub Release，因此 tap 无法预先写入正式版本的下载地址和 SHA256。

首个版本发布前，`Formula/agconf.rb` 仅提供 `--HEAD` 开发安装。首个 GitHub Release 发布后，需要为该工具一次性建立 stable Formula。此后 tap 内的 Homebrew autobump workflow 会定时发现新 Release、计算 SHA256 并创建 Formula 更新 PR，不需要工具仓库拥有 tap 的写权限。
