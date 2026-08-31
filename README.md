# 清零记账（QinglingWallet）

一款简洁易用、高度个人化的 Android 记账 App。界面遵循 Apple / Google 级设计审美，交互带有丝滑动效与强反馈。

## 技术栈
- **Flutter**（Material 3 + Cupertino 双设计语言）
- 状态管理：Riverpod（规划）
- 路由：go_router（规划）
- 本地数据库：Isar / Drift(SQLite)（规划）
- 图表：fl_chart（规划）

## 当前功能（v0.1）
- 首页：余额卡片 + 快速记一笔 + 快捷分类 + 最近记录（本地占位数据）
- 设计：Material 3 渐变余额卡、大圆角、柔和阴影

## 项目结构
```
lib/
  main.dart            # 应用入口 + 首页雏形
.github/workflows/
  build.yml            # GitHub Actions 云端构建 APK
开发计划.md           # 规划与里程碑（技术选型/功能/动画/疑难点）
```

## 构建方式（云端）
本项目配置 GitHub Actions，向 `main` 分支推送即可自动构建 Release APK：
1. 云端 `flutter create` 补 Android 平台骨架
2. `flutter build apk --release`
3. APK 作为 Artifact 上传，可在 Actions 页面下载

## 运行说明
本机未装 Flutter/Android SDK，完整本地构建请参见开发计划.md 第 8 节「构建与运行」。
