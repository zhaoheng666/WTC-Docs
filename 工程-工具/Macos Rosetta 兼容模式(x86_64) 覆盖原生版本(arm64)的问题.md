# Macos Rosetta 兼容模式(x86_64) 覆盖原生版本(arm64)的问题

## 什么是 Rosetta 模式

macOS 的 **Rosetta 模式**，特别是其第二代技术 **Rosetta 2**，是苹果公司为了平滑过渡从 Intel x86-64 芯片到自研 Apple Silicon (ARM架构) 芯片而开发的一项**动态二进制翻译技术**。它的核心作用是作为一个“翻译官”，让那些原本为 Intel Mac 编译的应用程序，无需任何修改就能在搭载 M系列芯片（如 M1, M2, M3）的新 Mac 上运行

我们的 cocosbuilder 是基于 x86_64 编译的，还能继续在 Apple Silicon Mac 上运行，就得益于 Rosetta 兼容；

‍

## 检查 Rosetta 环境

- ### 查看软件包是否是 x86_64 位版本

![image](/assets/1760679359268_c4984ef3.png)

![image](/assets/1760679359269_52445dac.png)

- ### 查看是否以安装支持 Rosetta，那些应用运行在 Rosetta 兼容模式下：

![image](/assets/1760679359270_41c4fac4.png)


## Rosetta 模式的影响

- ### 无法发挥 Apple Silicon 芯片的性能，运行效率下降明显：

  例如，当 shell 环境配置文件添加了 nvm、pyenv 等需要初始化的依赖时， Rosetta 模式下的 终端.app 启动速度下降严重，耗时比 Arm64 原生环境长数倍；

  如果怀疑自己某个软件包运行莫名其妙的慢，可以看看是否用错了版本；
- ### 环境不一致带来莫名其妙的问题：

  #### 典型案例：

  在 ARM64 (Apple Silicon) Mac 上运行包含 rollup 的构建脚本时出现指令集不兼容错误。

  - **表现：**

    1. 编译错误时有时无；
    2. 不同终端运行编译命令结果不一致；比如在终端、 vscode、Trae 内置终端运行，有成功有失败；
    3. 不同解释器下运行编译命令结果不一致；比如 zsh 成功 bash 失败，反之亦然；
    4. 编译命令所处层级较深时，过程中出现环境切换，工具 - 终端 - 脚本，最终编译时的环境 CPU 架构不确定，每次都要重新卸载重装当前需要的 Rollup 包；

  - **根本原因：**

    系统最初启用了 Rosetta 2 转换层，并且在 Rosetta 模式下安装了 Homebrew：

    1. **Homebrew 安装为 x86_64 版本** - 最早的基础软件都是 Intel 架构
    2. **连锁反应** - 后续通过 Homebrew 安装的 Node.js、npm 等都是 x86_64 版本
    3. **npm 包架构不匹配** - 安装的 npm 包（包括 rollup）都编译为 x86_64 架构
    4. **混合架构冲突** - 某些场景下 ARM64 和 x86_64 代码混合执行导致崩溃

  - **解决方案：**

    1. 彻底关闭 Rosetta：  
        重启 - 进入 recovery 模式 - 关闭 SIP（系统安全策略）- 重启 - 删除 Rosetta 相关文件；
    2. 重装关键环境和包管理器：

        检查并卸载重装 homebrew 、 npm、 golang 、gem 等包管理器；

        检查重装各个包管理器下的软件包；

