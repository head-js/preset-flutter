# 在 macOS 上初始化 Flutter 开发环境

> updated_by: Cascade - Claude-Sonnet-4.5
> updated_at: 2026-04-17 22:46:00

---

## 📌 待办：Java 目标版本 11 → 17

**当前状态**：`android/app/build.gradle.kts` 中 `sourceCompatibility` / `targetCompatibility` / `kotlinOptions.jvmTarget` 均为 `JavaVersion.VERSION_11`（Flutter 3.29 生成的默认值）。

**计划升级到**：`JavaVersion.VERSION_17`。

**动机**：

- 主流 Android / Kotlin 生态已稳定支持 JVM 17
- AGP 8.x + Gradle 8.10.2 + Kotlin 2.x 对 17 兼容成熟
- 打开 Java 17 语言特性：record、sealed class、pattern matching for switch 等

**不涉及**：

- `org.gradle.java.home` 保持指向 Android Studio 内置 JBR 21（作为 Daemon JVM 不变）
- 系统 JAVA_HOME（Corretto 11）不受影响

**执行时机**：非紧急，待后续可接受构建风险的迭代中集中切换。

**涉及改动**（3 行）：

```kotlin
// android/app/build.gradle.kts
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17   // 原: VERSION_11
    targetCompatibility = JavaVersion.VERSION_17   // 原: VERSION_11
}
kotlinOptions {
    jvmTarget = JavaVersion.VERSION_17.toString()  // 原: VERSION_11
}
```

**验收方法**：改完后 `./gradlew clean assembleDebug` 成功；用 `javap -v <class>` 抽查产物，Major version 应为 `61.0`（JVM 17）。

---

## ⚠️ Agent 执行检查时的 shell 状态问题（已验证）

**结论**：Windsurf 的 `run_command` 工具**不是 stateless**，多次调用共享同一个 zsh 进程。

**验证方式**：

```bash
# 第 1 次调用
echo "pid=$$"            # 输出 pid=9875

# 第 2 次调用（不同 run_command）
echo "pid=$$"            # 仍然 pid=9875

# 第 1 次调用设置变量
export MY_VAR=hello

# 第 2 次调用读取
echo $MY_VAR             # 输出 hello（变量跨调用保留）
```

**影响**：

- Agent 若在 run_command 里 `source ~/.bashrc` 或 `export X=...`，修改会持久化并污染后续所有调用
- 典型症状：PATH 中某个条目累积出现多次，例如 `platform-tools` 出现 2~3 次——这是 Agent 多次 source 造成的假象，不是你真实 shell 的状态

**Agent 执行检查时的纪律**：

1. **不要**在 run_command 里修改共享 shell 状态：
   - ❌ `source ~/.bashrc`
   - ❌ `export X=...`
   - ❌ `cd <dir>`（用 run_command 的 `cwd` 参数）
2. **每条检查命令必须在一个全新的、隔离的 zsh 子进程里运行**，使用：

   ```bash
   env -i HOME="$HOME" USER="$USER" LANG="$LANG" TERM=xterm-256color zsh -ilc '<实际检查命令>'
   ```

   - `env -i` 清空从父进程继承的 env（避免 Agent 父 shell 的污染）
   - `HOME / USER / LANG / TERM` 是重建干净 zsh 所需的最小必要变量
   - `zsh -ilc`：`-l` login（读 `/etc/zprofile` 跑 `path_helper`），`-i` interactive（读 `~/.zshrc` 并 `source ~/.bashrc`），`-c` 执行单条命令
   - 这等价于"打开一个新 Terminal 窗口跑一条命令"

3. **结论一律以人工在真实终端的观察为准**。Agent 的观察仅供参考。

---

## Shell 设置

**规范要求**：
- 使用 macOS 默认的 zsh
- 自定义环境变量 / PATH 统一写入 `~/.bashrc`（由 `~/.zshrc` 通过 `source ~/.bashrc` 加载）
- `~/.zshrc` 只负责 zsh 本身的配置（如 oh-my-zsh）与 `source ~/.bashrc`

**检查步骤**：
1. 确认当前 Shell：`echo $SHELL`，应返回 `/bin/zsh`
2. 确认 zsh 版本：`zsh --version`
3. 确认配置文件存在：`~/.zshrc` 与 `~/.bashrc`
4. 确认 `~/.zshrc` 中有 `source ~/.bashrc`：`grep -n 'source ~/.bashrc' ~/.zshrc`

---

## Git 设置

**规范要求**：
- 仅支持 Apple Silicon（M 系列）机型
- 必须通过 Homebrew 安装 Git
- `git` 命令应指向 `/opt/homebrew/bin/git`

**检查步骤**：
1. 确认 CPU 架构：`uname -m`，应返回 `arm64`
2. 确认 Homebrew 已安装 Git：`brew list --versions git`
3. 确认 Git 路径：`which git`，应返回 `/opt/homebrew/bin/git`，而非 `/usr/bin/git`
4. 确认版本：`git --version`

---

## Flutter / Dart 环境

### Flutter

**规范要求**：
- 必须安装在 `~/develop/flutter`
- PATH 必须包含 `~/develop/flutter/bin`
- 国内环境必须配置镜像源（环境变量）

**镜像源配置**：
在 `~/.bashrc` 中追加以下环境变量：
- `export PUB_HOSTED_URL=https://pub.flutter-io.cn`
- `export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`

**PATH 配置**：
在 `~/.bashrc` 中追加：
```bash
export PATH="$HOME/develop/flutter/bin:$PATH"
```

**检查步骤**：
1. 确认 Flutter 安装路径：`which flutter`，应返回 `~/develop/flutter/bin/flutter`
2. 确认 PATH 配置：`echo $PATH | tr ':' '\n' | grep flutter`，应包含 `~/develop/flutter/bin`
3. 确认镜像源配置：`echo $PUB_HOSTED_URL` 和 `echo $FLUTTER_STORAGE_BASE_URL`
4. 确认版本：`flutter --version`

**预缓存依赖**：
```bash
flutter precache --android -v
```

> 加 `-v` 显示详细下载/解压日志，否则 `precache` 默认不打印每个产物的进度，执行看起来"一闪而过"，难以确认是否真的下载了内容。

`flutter precache` 下载的是 **Flutter SDK 级别**的构建产物（Dart SDK、引擎二进制、Material 字体等），存放于 `~/develop/flutter/bin/cache/`，所有项目共享，与是否存在项目代码无关。

**执行时机**：装完 Flutter SDK 后立即执行，把"懒加载"改为"急加载"，避免首次 `flutter run` / `flutter build` 时卡网络。

**不包含**以下产物（需有项目后再单独处理，不是本命令的职责）：

- pub 包依赖（`flutter pub get` → `~/.pub-cache/`）
- Gradle wrapper 与 Android 构建依赖（首次 `./gradlew` → `~/.gradle/caches/`）

### Dart

**规范要求**：
- 使用 Flutter 附带的 Dart SDK（无需单独安装）
- 无需额外配置 PATH（Flutter PATH 已包含 Dart）
- `dart` 命令应指向 `~/develop/flutter/bin/dart`

**检查步骤**：
1. 确认 `dart` 命令来源：`which dart`，应返回 `~/develop/flutter/bin/dart`
2. 确认版本：`dart --version`

---

## Xcode 环境

**适用范围**：本项目仅开发 Android，不涉及 iOS / macOS 应用构建。因此：

- 不涉及 CocoaPods、iOS 模拟器、`xcodebuild` 构建 iOS 项目
- 仍要求安装完整 Xcode.app，用于统一 mac 开发机基线，并隐式提供 Command Line Tools

**规范要求**：
- 必须安装完整 Xcode.app（位于 `/Applications/Xcode.app`）
- 必须接受 Xcode 许可协议
- `xcode-select -p` 必须指向 Xcode.app，而非 `/Library/Developer/CommandLineTools`
- **不单独安装** Xcode Command Line Tools（Xcode.app 已包含一套完整 CLT）

**检查步骤**：
1. 确认 Xcode 安装路径：`ls -d /Applications/Xcode.app`
2. 确认 `xcode-select -p`：应返回 `/Applications/Xcode.app/Contents/Developer`
3. 确认 Xcode 版本：`xcodebuild -version`
4. 确认许可协议已接受：`sudo xcodebuild -license status`（若已接受无提示；否则运行 `sudo xcodebuild -license accept` 接受）

### Xcode 自带工具清单（优先使用）

工具根目录：`/Applications/Xcode.app/Contents/Developer/`

**通用开发工具**（`Developer/usr/bin/`）：

| 工具 | 用途 | 推荐调用方式 |
|---|---|---|
| `clang` / `clang++` | C / C++ 编译器 | `xcrun clang` |
| `make` | 构建工具 | `xcrun make` |
| `lldb` | 调试器 | `xcrun lldb` |
| `otool` / `nm` / `lipo` / `strip` / `install_name_tool` | Mach-O 二进制工具 | `xcrun otool` 等 |
| `ar` / `ranlib` / `ld` | 静态库 / 链接 | `xcrun ld` 等 |
| `dwarfdump` | 调试符号查看 | `xcrun dwarfdump` |

**Xcode 专属工具**：

| 工具 | 用途 | 本项目是否使用 |
|---|---|---|
| `xcrun` | 按 SDK 解析工具路径 | ✅ 作为统一调用入口 |
| `xcodebuild` | 构建 iOS / macOS 项目 | ❌ |
| `xcrun simctl` | iOS 模拟器控制 | ❌ |

**调用规范**：统一通过 `xcrun <tool>` 调用 Xcode 自带工具，避免与 Homebrew / 系统版本混淆。

**例外约定**：
- **Git 不使用 Xcode 自带版本**，仍通过 Homebrew 安装（见 Git 设置章节），原因是 Homebrew 版本更新

---

## Android Studio / Android SDK 环境

### Android Studio（必须由 JetBrains Toolbox 管理）

**规范要求**：
- **必须通过 JetBrains Toolbox 安装和管理** Android Studio，不接受从 Google 官网下载的独立 `.dmg` 安装
- Toolbox 将 IDE 统一安装到用户级目录 `~/Applications/`
- `.app` 名字由 Toolbox 自动生成（格式：`Android Studio <代号> <版本号>.app`，例如 `Android Studio Narwhal 4 Feature Drop 2025.1.4.app`），**不要求固定名字**
- Toolbox 脚本目录 `~/Library/Application Support/JetBrains/Toolbox/scripts` 必须在 PATH 中（Toolbox 首次运行自动写入）
- 启动 / 调用统一使用 `studio` 命令（由 Toolbox 生成的稳定入口，内部自动指向当前版本的 `.app`）
- 当前约定版本：**Android Studio Narwhal 4 Feature Drop 2025.1.x**，`CFBundleShortVersionString = 2025.1`

**检查步骤**：
1. 确认 Toolbox 已安装：`ls -d "$HOME/Library/Application Support/JetBrains/Toolbox"`
2. 确认 Toolbox 脚本目录在 PATH：`echo $PATH | tr ':' '\n' | grep -F 'JetBrains/Toolbox/scripts'`
3. 确认 `studio` 命令可用：`which studio`，应返回 `~/Library/Application Support/JetBrains/Toolbox/scripts/studio`
4. 确认 Android Studio .app 存在（用 glob 匹配版本化名字）：`command ls -d "$HOME/Applications/Android Studio "*.app`
5. 确认版本：`defaults read "$(command ls -d "$HOME/Applications/Android Studio "*.app | head -1)/Contents/Info" CFBundleShortVersionString`，应返回 `2025.1`

> 注：使用 `command ls` 绕过常见的 `ls` alias（例如 `alias ls='gls -lhF ...'`），避免 `$(...)` 捕获到长格式输出导致后续 `defaults read` 失败。

### Android SDK

**规范要求**：
- SDK 路径为 `~/Library/Android/sdk`（Android Studio 默认位置）
- 必须安装：
  - Android SDK Platform-Tools
  - Android SDK Build-Tools
  - Android SDK Command-line Tools
  - 至少一个 Android Platform（SDK Platform API 对应的 `platforms/android-XX/`）

**检查步骤**：
1. 确认 SDK 路径：`ls -d ~/Library/Android/sdk`
2. 确认 platform-tools：`ls ~/Library/Android/sdk/platform-tools/adb`
3. 确认已安装 platforms：`ls ~/Library/Android/sdk/platforms`
4. 确认已安装 build-tools：`ls ~/Library/Android/sdk/build-tools`
5. 确认 cmdline-tools：`ls ~/Library/Android/sdk/cmdline-tools`（⚠️ 存疑：版本路径规范待确认）

**环境变量要求**（在 `~/.bashrc` 中）：
```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
```

> 注：`ANDROID_SDK_ROOT` 已被 Google 于 2019 年弃用（deprecated），只保留 `ANDROID_HOME`。现代 Android Gradle Plugin、Flutter、`sdkmanager` 等工具均优先读 `ANDROID_HOME`；同时设置两者反而会触发 `sdkmanager` 警告。

**检查步骤**：
1. 确认 `ANDROID_HOME`：`echo $ANDROID_HOME`
2. 确认 PATH：`echo $PATH | tr ':' '\n' | grep platform-tools`
3. 确认 `adb` 可用：`adb --version`

**接受 Android SDK 许可**：
```bash
flutter doctor --android-licenses
```

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
- 在项目根目录执行：`cd android && ./gradlew --version`
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
```bash
cd android && ./gradlew buildEnvironment --info
```
查看输出中的仓库 URL，应显示 `maven.aliyun.com` 而非 `dl.google.com` 或 `repo.maven.apache.org`

### ⚠️ 已知限制：仍有部分下载会直连 plugins.gradle.org / dl.google.com

即使 `pluginManagement` + `allprojects.repositories` 都配了阿里云镜像，观察 `./gradlew buildEnvironment --info` 的日志仍可能看到：

```
Downloading https://plugins.gradle.org/m2/org/jetbrains/kotlin/.../...pom ...
Downloading https://dl.google.com/dl/android/maven2/...
```

**两个根因**（叠加导致）：

1. **Flutter SDK 的 `flutter_tools/gradle` 是 includeBuild**，它自己的 `settings.gradle.kts` 硬编码：
   ```kotlin
   // <flutter>/packages/flutter_tools/gradle/settings.gradle.kts
   dependencyResolutionManagement {
       repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
       repositories {
           google()         // dl.google.com
           mavenCentral()   // repo.maven.apache.org
       }
   }
   ```
   Flutter 作为被包含的构建拥有独立的仓库配置，**不走**项目的阿里云镜像。改它意味着改 Flutter SDK 源码，下次 SDK 升级会覆盖，**实质不可改**。

2. **阿里云 `gradle-plugin` 仓库对 plugin portal 的镜像不完整**。当某个 POM / metadata 在镜像里缺失时，Gradle 会回退到 `plugins.gradle.org/m2/` 直连。

**影响范围**：
- 只有少量 POM / metadata 文件（几 KB）会直连
- 真正的大 artifact（jar）仍走镜像
- 首次构建略慢，命中 Gradle 本地缓存后不再重下
- **生产可接受**，不阻塞

### 改进方案（暂未启用，待评估后再决定）

在 `android/settings.gradle.kts` 追加 `dependencyResolutionManagement`，把项目级依赖解析也纳入阿里云镜像：

```kotlin
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
    }
}
```

配合改动：

- `android/build.gradle.kts` 中的 `allprojects { repositories { ... } }` 可以删除（被 `PREFER_SETTINGS` 统一接管）
- 预期效果：项目自身的依赖（非 Flutter SDK 的 included build）全部经阿里云解析，plugins.gradle.org 直连次数进一步减少

**未启用原因**：
- 当前构建可用，不紧急
- `PREFER_SETTINGS` 会改变项目依赖解析行为，需要跑一次完整 `./gradlew assembleDebug` 验证无回归
- 待后续可接受构建风险的迭代中切换

**Flutter SDK 的直连仍然无法通过此方案消除**（原因 1 所述）
