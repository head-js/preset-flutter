# 在 Windows 11 上初始化 Flutter 开发环境

> updated_by: GLM-5
> updated_at: 2026-04-17 14:53:12

---

## PowerShell 设置

**规范要求**：
- 使用 Windows 内置的 PowerShell 5.1

**检查步骤**：
1. 确认 PowerShell 版本：`$PSVersionTable.PSVersion`

---

## Git Bash 设置

**规范要求**：
- 安装 Git for Windows，包含 Git Bash
- 安装路径为 `C:\Programs\Git`

**配置文件位置**：
- 用户级：`%USERPROFILE%\.bashrc`
- 系统级：`C:\Programs\Git\etc\bash.bashrc`

**检查步骤**：
1. 确认 Git 安装：`git --version`
2. 确认 Git Bash 路径：检查 `C:\Programs\Git\bin\bash.exe` 是否存在
3. 确认用户配置文件：检查 `%USERPROFILE%\.bashrc` 是否存在

---

## Flutter / Dart 环境

### Flutter

**规范要求**：
- 必须安装在 `D:\flutter\`
- PATH 必须包含 `D:\flutter\bin`
- 国内环境必须配置镜像源（环境变量）

**镜像源配置**：
设置以下系统级环境变量：
- `PUB_HOSTED_URL=https://pub.flutter-io.cn`
- `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`

**检查步骤**：
1. 确认 Flutter 安装路径：`where.exe flutter`，应返回 `D:\flutter\bin\flutter.bat`
2. 确认 PATH 配置：`$env:PATH -split ';' | Select-String 'flutter'`，应包含 `D:\flutter\bin`
3. 确认镜像源配置（系统级）：`[Environment]::GetEnvironmentVariable('PUB_HOSTED_URL', 'Machine')` 和 `[Environment]::GetEnvironmentVariable('FLUTTER_STORAGE_BASE_URL', 'Machine')`
4. 确认版本：`flutter --version`

**预缓存依赖**：
```bash
flutter precache --android
```
此命令预下载 Android 平台的 Flutter 构建依赖（如 Gradle、Android SDK 组件等），用于离线开发或加速首次构建。

### Dart

**规范要求**：
- 使用 Flutter 附带的 Dart SDK（无需单独安装）
- 无需额外配置 PATH（Flutter PATH 已包含 Dart）
- `dart` 命令应指向 `D:\flutter\bin\dart.bat`

**检查步骤**：
1. 确认 `dart` 命令来源：`where.exe dart`，应返回 `D:\flutter\bin\dart.bat`
2. 确认版本：`dart --version`

---

## Android Studio / Android SDK 环境

**规范要求**：
- 必须安装 Android Studio 2025.1.4
- 安装路径为 `D:\Programs\Android Studio`
- 必须安装 Android SDK、Android SDK Platform-Tools
- 必须安装 Android SDK Build-Tools
- 必须安装 Android SDK Command-line Tools

**检查步骤**：
1. 确认 Android Studio 安装路径：检查 `D:\Programs\Android Studio\bin\studio64.exe` 是否存在
2. 确认版本：查看 `D:\Programs\Android Studio\product-info.json` 中的 version 字段
3. 确认 Android SDK 路径：检查 `D:\Programs\AndroidSdk` 是否存在
4. 确认已安装平台版本：`ls D:\Programs\AndroidSdk\platforms`
5. 确认已安装 build-tools：`ls D:\Programs\AndroidSdk\build-tools`
6. 确认 cmdline-tools：`ls D:\Programs\AndroidSdk\cmdline-tools`（⚠️ 存疑：版本路径规范待确认）

**环境变量要求**（系统级）：
- `ANDROID_HOME=D:\Programs\AndroidSdk`
- PATH 添加 `D:\Programs\AndroidSdk\platform-tools`

> 注：`ANDROID_SDK_ROOT` 已被 Google 于 2019 年弃用（deprecated），只保留 `ANDROID_HOME`。现代 Android Gradle Plugin、Flutter、`sdkmanager` 等工具均优先读 `ANDROID_HOME`；同时设置两者反而会触发 `sdkmanager` 警告。

**检查步骤**：
1. 确认 `ANDROID_HOME`：`[Environment]::GetEnvironmentVariable('ANDROID_HOME', 'Machine')`
2. 确认 PATH：`[Environment]::GetEnvironmentVariable('PATH', 'Machine') -split ';' | Where-Object { $_ -eq 'D:\Programs\AndroidSdk\platform-tools' }`

---

## Gradle / Maven 环境

**概念说明**：
- **Gradle** - 构建工具，负责编译、打包项目
- **Maven Repository** - 依赖仓库，存放第三方库文件（如 `androidx.*`、`com.android.tools.build` 等）
- Gradle 构建时会从 Maven 仓库下载项目依赖

**系统级镜像源**：
- **不允许**配置系统级镜像源
- Gradle 全局配置（`~/.gradle/init.gradle`）不推荐使用
- Maven 是仓库概念，无系统级配置
- 镜像源应在项目级配置，确保配置可控且不影响其他项目

### Gradle Wrapper 镜像源

**配置文件位置**：
- `<项目目录>/android/gradle/wrapper/gradle-wrapper.properties`

**规范要求**：
- 国内环境必须配置阿里云镜像源
- 修改 `distributionUrl` 指向阿里云镜像

**配置示例**：
```properties
distributionUrl=https\://mirrors.aliyun.com/gradle/distributions/v8.10.2/gradle-8.10.2-all.zip
```

**检查步骤**：
1. 打开 `android/gradle/wrapper/gradle-wrapper.properties`
2. 确认 `distributionUrl` 指向 `mirrors.aliyun.com` 而非 `services.gradle.org`

**验证命令**：
- 在项目根目录执行：`cd android; .\gradlew.bat --version`
- 此命令会触发 Gradle Wrapper 初始化并显示版本信息，是验证 Gradle 环境的最小命令

### Maven 仓库镜像

**配置位置**：
- `android/settings.gradle.kts` - pluginManagement.repositories
- `android/build.gradle.kts` - allprojects.repositories

**规范要求**：
- 国内环境必须配置阿里云镜像源
- 替换 `google()` 为阿里云 google 镜像
- 替换 `mavenCentral()` 为阿里云 central 镜像

**settings.gradle.kts 配置示例**：
```kotlin
pluginManagement {
    // ...
    repositories {
        // google()
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        // mavenCentral()
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        // gradlePluginPortal()
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
    }
}
```

**build.gradle.kts 配置示例**：
```kotlin
allprojects {
    repositories {
        // google()
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        // mavenCentral()
        maven { url = uri("https://maven.aliyun.com/repository/central") }
    }
}
```

**检查步骤**：
1. 打开 `android/settings.gradle.kts`，确认 `repositories` 块使用阿里云镜像
2. 打开 `android/build.gradle.kts`，确认 `allprojects.repositories` 块使用阿里云镜像
3. 确认无 `google()` 或 `mavenCentral()` 直接调用

**验证命令**：
```powershell
cd android; .\gradlew.bat buildEnvironment --info
```
查看输出中的仓库 URL，应显示 `maven.aliyun.com` 而非 `dl.google.com` 或 `repo.maven.apache.org`
