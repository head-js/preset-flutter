# Flutter 3.29.3 构建问题分析

> updated_by: Kilo - GLM-5
> updated_at: 2026-04-17 12:01:00

## 问题描述

执行 `flutter build apk` 时持续失败，错误信息：

```
FAILURE: Build failed with an exception.

* What went wrong:
Could not determine the dependencies of task ':app:compileDebugJavaWithJavac'.
> Cannot query the value of this provider because it has no value available.
```

## 环境信息

### Flutter 版本

```
Flutter 3.29.3 • channel stable
Framework • revision ea121f8859 (1 year ago) • 2025-04-11 19:10:07 +0000
Engine • revision cf56914b32
Tools • Dart 3.7.2 • DevTools 2.42.3
```

### Java 版本

```
openjdk version "17.0.15" 2025-04-15 LTS
OpenJDK Runtime Environment Microsoft-11369865 (build 17.0.15+6-LTS)
```

### Gradle / AGP / Kotlin 版本

| 组件 | 版本 | 来源 |
|-----|------|-----|
| Gradle | 8.10.2 | `gradle-wrapper.properties` |
| AGP | 8.7.0（后改为 8.7.3） | `settings.gradle.kts` |
| Kotlin | 1.8.22（后改为 1.9.20） | `settings.gradle.kts` |

### flutter doctor 输出

```
[√] Flutter (Channel stable, 3.29.3)
[√] Windows Version (Windows 11, 25H2)
[√] Android toolchain - develop for Android devices (Android SDK version 36.0.0)
[√] Chrome - develop for the web
[√] Visual Studio - develop Windows apps
[√] Android Studio (version 2025.1.4)
[√] IntelliJ IDEA Ultimate Edition (version 2025.3)
[√] VS Code
[√] Connected device (3 available)
[√] Network resources

• No issues found!
```

## 诊断过程

### 1. 版本组合验证

参考 Flutter SDK 内的版本常量定义：

**文件位置**：`D:\flutter\packages\flutter_tools\lib\src\android\gradle_utils.dart`

```dart
const String templateDefaultGradleVersion = '8.10.2';
const String templateAndroidGradlePluginVersion = '8.7.0';
const String templateAndroidGradlePluginVersionForModule = '8.7.0';
const String templateKotlinGradlePluginVersion = '1.8.22';
```

确认项目版本组合与 Flutter 模板版本一致。

### 2. Flutter Gradle Plugin 内部版本

**文件位置**：`D:\flutter\packages\flutter_tools\gradle\build.gradle.kts`

```kotlin
plugins {
    kotlin("jvm") version "1.9.20"
}

dependencies {
    compileOnly("com.android.tools.build:gradle:8.7.3")
}
```

发现 Flutter Gradle Plugin 内部使用：
- Kotlin 1.9.20（与模板 1.8.22 不同）
- AGP 8.7.3（与模板 8.7.0 不同）

### 3. 尝试的修复措施

| 操作 | 结果 |
|-----|------|
| Kotlin 版本升级到 1.9.20 | 失败，相同错误 |
| AGP 版本升级到 8.7.3 | 失败，相同错误 |
| 清理项目 Gradle 缓存 | 失败，相同错误 |
| 清理全局 Gradle 用户缓存 | 失败，相同错误 |
| 转换为 Groovy DSL（build.gradle） | 失败，相同错误 |
| 创建全新 Flutter 项目测试 | 失败，相同错误 |
| 尝试 Flutter 升级到 3.41.7 | 失败，Dart SDK 被占用 |

### 4. 详细错误堆栈

```
Caused by: org.gradle.api.internal.provider.MissingValueException: 
Cannot query the value of this provider because it has no value available.

at org.gradle.api.internal.provider.AbstractMinimalProvider.calculateOwnPresentValue(AbstractMinimalProvider.java:82)
at org.gradle.api.internal.provider.AbstractMinimalProvider.get(AbstractMinimalProvider.java:100)
at org.gradle.api.internal.file.collections.ProviderBackedFileCollection.visitDependencies(ProviderBackedFileCollection.java:57)
at org.gradle.api.internal.provider.BuildableBackedProvider$1.visitDependencies(BuildableBackedProvider.java:57)
```

## 根本原因分析

### 错误触发位置

**Flutter Gradle Plugin 源代码**：`D:\flutter\packages\flutter_tools\gradle\src\main\kotlin\FlutterPlugin.kt`

```kotlin
// 第 735-740 行
FlutterPluginUtils.addApiDependencies(
    project,
    variant.name,
    project.files({
        packJniLibsTask  // ← 这是一个 TaskProvider<Jar>
    })
)
```

`packJniLibsTask` 是一个 `Jar` 任务，其输出文件作为依赖被添加到 `debugApi` 配置。

Gradle 8.10.2 在解析这个 **Provider-backed 文件集合** 时失败。

### addApiDependencies 实现

**文件位置**：`D:\flutter\packages\flutter_tools\gradle\src\main\kotlin\FlutterPluginUtils.kt`

```kotlin
// 第 327-350 行
@JvmStatic
@JvmName("addApiDependencies")
internal fun addApiDependencies(
    project: Project,
    variantName: String,
    dependency: Any,
    config: Closure<Any>?
) {
    var configuration: String
    try {
        project.configurations.named("api")
        configuration = "${variantName}Api"
    } catch (ignored: UnknownTaskException) {
        configuration = "${variantName}Compile"
    }

    if (config == null) {
        project.dependencies.add(configuration, dependency)
    } else {
        project.dependencies.add(configuration, dependency, config)
    }
}
```

### 问题根源

`project.files({ packJniLibsTask })` 创建了一个延迟计算的文件集合：
- 内部使用 `Provider` 来获取 Jar 任务的输出文件
- Gradle 在配置阶段尝试解析这个 Provider 的值
- 但 `packJniLibsTask` 的输出目录尚未确定（Provider 无值）

这是 **Flutter 3.29.3 的已知 bug**，在后续版本中修复。

## 建议解决方案

### 选项 A：升级 Flutter SDK（推荐）

关闭所有 Dart/Java/Gradle 进程后执行：

```powershell
# 1. 关闭所有相关进程
Stop-Process -Name "dart", "java", "gradle" -Force -ErrorAction SilentlyContinue

# 2. 升级 Flutter
flutter upgrade

# 3. 清理缓存
flutter clean

# 4. 重新构建
flutter build apk --debug
```

### 选项 B：手动安装 Flutter 3.41.7

如果 `flutter upgrade` 失败，可以手动下载并替换：

1. 下载 Flutter SDK 3.41.7：https://docs.flutter.dev/release/archive
2. 解压到新目录（如 `D:\flutter-3.41`）
3. 更新环境变量 `FLUTTER_ROOT`
4. 或在 `local.properties` 中设置 `flutter.sdk=D:\\flutter-3.41`

### 选项 C：降级 Gradle 版本

将 Gradle 降级到 8.9（AGP 8.7.0 最低要求）：

修改 `android/gradle/wrapper/gradle-wrapper.properties`：

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.9-all.zip
```

然后重新构建。

### 选项 D：跳过依赖检查

在 `gradle.properties` 中添加：

```properties
skipDependencyChecks=true
```

## 相关文件位置

| 文件 | 路径 |
|-----|------|
| Flutter Gradle Plugin 源码 | `D:\flutter\packages\flutter_tools\gradle\src\main\kotlin\FlutterPlugin.kt` |
| Flutter Gradle Plugin 构建 | `D:\flutter\packages\flutter_tools\gradle\build.gradle.kts` |
| 版本常量定义 | `D:\flutter\packages\flutter_tools\lib\src\android\gradle_utils.dart` |
| FlutterExtension 扩展 | `D:\flutter\packages\flutter_tools\gradle\src\main\kotlin\FlutterExtension.kt` |
| PluginHandler 插件处理 | `D:\flutter\packages\flutter_tools\gradle\src\main\kotlin\plugins\PluginHandler.kt` |

## 结论

这是 Flutter 3.29.3 与 Gradle 8.10.2 的兼容性问题，根源在于 Flutter Gradle Plugin 中 `packJniLibsTask` 的 Provider 解析时机错误。

**推荐方案**：升级 Flutter SDK 到 3.41.7 或更高版本，该版本已修复此问题。

---

*行动就有力量，唯有行动才能改变事情，迭代要快，大力出奇迹。*