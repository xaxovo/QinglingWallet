# 清零记账（QinglingWallet）

一款简洁易用、高度个人化的 Android 记账 App。界面遵循 Apple / Google 级设计审美，交互带有丝滑动效与强反馈。**纯本地存储，数据自主可控。**

## 当前功能

### 记账核心（v0.1）
- **记一笔浮层**：底部弹层，收/支、金额、分类、备注、日期，自动适配收支分类；保存触发 confetti 纸屑反馈。
- **明细列表**：按天分组，点击编辑，左滑删除。
- **首页**：余额卡片（本月收入/支出/结余 + 数字滚动动画）、动态问候语、最近记录、快速记一笔胶囊按钮、交错入场动画。
- **开机过渡动画**：LOGO 放大渐显 + 首页元素淡入上滑。

### 分类管理（v0.2.0）
- 我的页 → 分类管理：新增/编辑/删除分类（名称、图标、颜色、收支类型）。
- 内置默认分类，可自定义；删除分类会提示并级联删除其记录。

### 统计图表（v0.2.0）
- 本月分类支出占比**环形图**（`fl_chart` PieChart）。
- 近 6 个月收支**趋势折线**（`fl_chart` LineChart）。

### 数据管理（v0.2.1）
- 导出 CSV / 导入 CSV（系统文件选择器）。
- 一键备份数据库，导出/备份均可通过系统**分享**到其他设备。

### 我的页 / 关于（v0.2.0）
- 点开我的页直接显示应用详情：LOGO、应用名、版本号（`package_info_plus` 读取真实版本）。

### 查账更顺手（v0.3.0）
- **搜索 + 筛选**：明细页按备注搜索，按分类 / 收支类型筛选。
- **历史月份切换**：明细和统计都能切到任意月份。
- **日历视图**：月历点某天看当天收支。

### 自动记账（v0.3.0）
- 新增重复规则（每周 / 每月 / 每年，金额、分类、备注、启用）。
- App **回到前台自动补记**当天命中且未记的规则，并提示。

### 动效 & 自定义界面
- 主题：粉白（seed `0xFFEC9CAF`），启动动画、tab 淡入、Haptic 触感反馈。
- 纸屑反馈：`confetti`（本地渲染，一次性喷发、左上落下、渐隐淡出）。
- **自定义接口** `lib/appearance.dart`：主题色、纸屑颜色/数量/开关等集中配置，为后续多主题/界面效果自定义预留。

## 技术栈
- **Flutter**（Material 3）
- 状态管理：`flutter_riverpod`
- 本地数据库：`sqflite` + `path_provider` + `path`
- 图表：`fl_chart`
- 其他：`intl`、`confetti`、`package_info_plus`、`share_plus`、`file_picker`

## 项目结构
```
lib/
  main.dart                     # 入口 + 主题 + 开机动画 + 底部导航
  models.dart                   # Category / Tx 数据模型
  theme.dart                    # buildTheme(seedColor) 主题
  appearance.dart               # 外观配置层（主题色/纸屑效果，预留自定义接口）
  particle.dart                 # confetti 纸屑爆发
  providers.dart                # Riverpod 状态 & 统计 provider
  util.dart                     # 图标映射
  data/database.dart            # sqflite 数据库 + CRUD + 统计聚合
  screens/
    home_screen.dart            # 首页
    add_record_sheet.dart       # 记一笔浮层
    transactions_screen.dart    # 明细列表
    stats_screen.dart           # 统计图表
    settings_screen.dart        # 我的页（关于详情 + 入口）
    category_manage_screen.dart # 分类管理
    data_manage_screen.dart     # 数据导出/导入/备份
assets/
  logo.png                      # 首页萌系 LOGO
  about_logo.png                # 关于页花体圆角 LOGO
.github/workflows/build.yml     # GitHub Actions 云端构建
```

## 构建方式（GitHub Actions 云端）
向 `main` 推送即自动构建 Release APK：
1. 云端 `flutter create --platforms=android --org com.qingling --project-name qinglingwallet .` 生成 Android 骨架
2. `flutter build apk --release`
3. APK 作为 Artifact 上传，可在 Actions 页面下载；版本号与 GitHub Release 同步

> 注意：`--project-name qinglingwallet` 必须显式小写（仓库名大写会导致包名校验失败）。当前构建使用 Flutter 默认调试签名。

## 运行说明
本机未装 Flutter/Android SDK，完整本地构建见 `开发计划.md`；APK 交付走 GitHub Releases。
