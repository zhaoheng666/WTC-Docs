### Python 2.7 安装 Pillow 失败

#### 报错信息

```
ERROR: Command errored out with exit status 1
...
The headers or library files could not be found for zlib,
a required dependency when compiling Pillow from source.
```

#### 环境信息

##### 系统：macOS (Apple Silicon / ARM64)

##### Python 版本：2.7.18

##### pip 版本：20.3.4

### 问题原因：

##### 1、Python 2.7 已于 2020 年 1 月 1 日停止支持，新版本的 Pillow (>6.x) 不再支持 Python 2.7；

##### 2、在 ARM64 macOS 上没有 Python 2.7 的预编译 wheel 包，需要从源码编译；

##### 3、编译 Pillow 需要系统级别的 zlib 和 libjpeg 依赖库，但 macOS 上这些库是 keg-only 的（不会自动链接）；

### 解决方案：

##### 1、安装系统依赖：

```bash
brew install zlib libjpeg
```

##### 2、使用环境变量指定库路径安装 Pillow 6.2.2（最后一个支持 Python 2.7 的版本）：

```bash
LDFLAGS="-L/opt/homebrew/opt/zlib/lib -L/opt/homebrew/opt/jpeg/lib" \
CPPFLAGS="-I/opt/homebrew/opt/zlib/include -I/opt/homebrew/opt/jpeg/include" \
pip install "Pillow==6.2.2"
```

##### 3、验证安装：

```bash
python -c "import PIL; print(PIL.__version__)"
# 输出: 6.2.2
```

### 补充说明：

##### 如果后续需要安装其他需要编译的 Python 包，可以将环境变量导出到 shell 配置文件中：

```bash
export LDFLAGS="-L/opt/homebrew/opt/zlib/lib -L/opt/homebrew/opt/jpeg/lib"
export CPPFLAGS="-I/opt/homebrew/opt/zlib/include -I/opt/homebrew/opt/jpeg/include"
```

##### 注意：强烈建议升级到 Python 3.x，Python 2.7 已经停止维护多年。

### 相关信息：

##### 日期：2025-10-21

##### 影响范围：使用 Python 2.7 的 macOS ARM64 开发环境
