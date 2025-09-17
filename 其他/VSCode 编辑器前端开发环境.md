# VSCode 编辑器前端开发环境

> 目的：更方便的使用 AI，提升 AI - 开发工程的融合程度，为以后项目“强 AI 辅助”打基础；
>
> 可以基于项目共享 AI context、rules、mcp 配置等；
>
> 12312312321

---

## AI 编辑器选择

---

1. 没有必须使用 webstorm 的需求：
   i. webstorm 较为耗费性能，存在使用不流畅的情况；
   ii. webstorm 自带的 AI 工具不够通用，且收费较高；
2. 目前大部分 AI 编辑器都是以 VSCode 为基础的二次开发，eg：TraeCN、Cursor、Windsurf；
3. 选定以 vscode 配置为迁移目标；
   i. 仅使用 vscode 支持的方式，以支持同系 AI 编辑器；
   ii. 不改动、污染现有项目脚本、环境；

---

## 实现方案

---

### 策略：

1. 用 express 搭建项目内部资源托管 web；
2. 基于 vscode-tasks 作为脚本封装工具；
3. 用 vscode-launch 作为工具启动器；
4. 使用插件做扩展按钮；

---

### 实现：

---

#### 内部资源托管 web：

- 安装 express ：`npm install express --save-dev`
- 搭建 web：`.vscode/local_server/server.js `

  ```javascript
  const express = require('express');
  const app = express();

  // 获取命令行参数
  const port = process.argv[2] || 8080;
  const isHelp = process.argv.includes('--help');

  if (isHelp) {
    console.log('Usage: node server.js [port]');
    console.log('Example: node server.js 3000');
    process.exit(0);
  }

  // 添加CORS中间件
  app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    next();
  });

  app.use(express.static('../../'));
  // app.use('/src', express.static('./src'));
  // app.use('/res_oldvegas', express.static('./res_oldvegas'));

  app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
    console.log(`PID: ${process.pid}`);
  });
  ```
- 端口配置：`.vscode/local_server/config.json`
- 启动脚本：`.vscode/local_server/start_local_server.sh`

#### Tasks 配置：.vscode/tasks.json

1. `start_local_server`：自启动任务，打开项目目录触发

   ```json
   {
         "label": "start_local_server",
         "type": "process",
         "command": "./start_local_server.sh",
         "isBackground": true,
         "options": {
           "cwd": "${workspaceFolder}/.vscode/local_server"
         },
         "runOptions": {
           "runOn": "folderOpen"
         },
         "group": {
           "kind": "test"
         },
         "hide": true
       }
   ```
2. `open_dev_chrome`：启动浏览器

   ```json
   {
         "label": "open_dev_chrome",
         "type": "process",
         "command": "./open_chrome.sh",
         "isBackground": true,
         "options": {
           "cwd": "${workspaceFolder}/.vscode/local_server"
         },
         "group": {
           "kind": "test"
         },
         "hide": true
       }
   ```
3. `build_local_cv`：编译 cv 环境

   ```json
   {
         "label": "build_local_cv",
         "type": "shell",
         "icon": {
           "id": "rocket",
           "path": "assets/rocket.svg",
           "tooltip": "build_local_cv",
           "preserveAspectRatio": true,
           "backgroundColor": "#00000000"
         },
         "command": "./build_local_app.sh res_oldvegas",
         "options": {
           "cwd": "${workspaceFolder}/scripts"
         },
         "group": {
           "kind": "build"
         },
         "hide": true
       }
   ```
4. `run_cv`：运行 cv

   ```json
   {
         "label": "run_cv",
         "type": "shell",
         "icon": {
           "id": "rocket",
           "path": "assets/rocket.svg"
         },
         "dependsOn": [
           "build_local_cv",
           "open_dev_chrome"
         ],
         "dependsOrder": "sequence",
         "group": {
           "kind": "test"
         },
         "hide": false
       }
   ```
5. `hotfix`：推热更

   ```json
   {
         "label": "hotfix",
         "type": "shell",
         "icon": {
           "id": "tools",
           "color": "terminal.ansiGreen"
         },
         "command": "python",
         "args": [
           "build_local_hotfix.py",
           "${relativeFile}"
         ],
         "options": {
           "cwd": "${workspaceFolder}/scripts"
         },
         "group": {
           "kind": "build"
         }
       }
   ```
6. `run_adb`：同步到 android 设备
7. ```json
   {
          "label": "run_adb",
          "type": "shell",
          "icon": {
            "id": "tools",
            "color": "terminal.ansiGreen"
          },
          "command": "./adb_sync_native.sh",
          "args": [
            "${input:adb_command}",
            // "${relativeFile}" // adb_async_native.sh 脚本同步指定资源有问题，暂时取消指定资源
          ],
          "options": {
            "cwd": "${workspaceFolder}/scripts"
          },
          "group": {
            "kind": "build"
          }
        }
   ```

#### launch 配置：.vscode/launch.json

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "CV",
      "type": "node",
      "request": "attach",
      "preLaunchTask": "run_cv",
      "timeout": 100
    },
    {
      "name": "DH",
      "type": "node",
      "request": "attach",
      "preLaunchTask": "run_dh",
      "timeout": 100
    },
    {
      "name": "Hotfix",
      "type": "node",
      "request": "attach",
      "preLaunchTask": "hotfix",
      // 防止 task 执行结束后，launch 延迟退出，导致频繁操作提示实例重复
      "autoAttachChildProcesses": false,
      "restart": false,
      "timeout": 100
    },
    {
      "name": "ADB",
      "type": "node",
      "request": "attach",
      "preLaunchTask": "run_adb",
      "timeout": 100
    },
    {
      // 除非local_server 意外停止或未启动，否则不用手动启动
      "name": "LocalServer",
      "type": "node",
      "request": "launch",
      "skipFiles": [
        "<node_internals>/**",
        "${workspaceFolder}/node_modules/**"
      ],
      "preLaunchTask": "start_local_server"
    }
  ]
}
```

#### 插件配置：

1. 选用 VSCode 市场插件：`Shortcut Menu Bar`
2. 项目设置（用户区）：

   ```json
   // ShortcutMenuBar 插件配置
   "ShortcutMenuBar.openFilesList": false,
   "ShortcutMenuBar.toggleTerminal": false,
   "ShortcutMenuBar.userButton01Command": "workbench.action.tasks.runTask|hotfix",
   "ShortcutMenuBar.userButton02Command": "workbench.action.tasks.runTask|run_cv",
   "ShortcutMenuBar.userButton03Command": "workbench.action.tasks.runTask|run_dh",
   ```
3. 可视化配置：

   `Command+Shift+P` ->  setting(打开设置) -> 扩展 -> Shortcut Menu Bar

   ![image](/images/其他/image-20250519161151-up71al6.png)

   ![image](/images/其他/image-20250519161527-653ggko.png)
4. ‍

---

### 依赖设置：

1. 允许自动运行任务：

   ```json
   "task.allowAutomaticTasks": "on"
   ```
2. 状态栏始终显示调试菜单：

   ![image](/images/其他/image-20250519173459-tde4u0z.png)

   ```json
   "debug.showInStatusBar": "always",
   ```
3. 启动代码片段导航

   ![image](/images/其他/image-20250519173559-pvvbq14.png)

   ```json
   "editor.snippetSuggestions": "top"
   ```

---

## 使用说明：

---

1. 更新 .vscode 目录;
2. 安装依赖库：`npm install`
3. 方式一：命令触发 Command+Shift+P -> task

   ![image](/images/其他/image-20250519162210-72srn82.png)
4. 方式二：状态栏 -> 调试运行菜单

   ![image](/images/其他/image-20250519162419-jgubsu7.png)

   ![image](/images/其他/image-20250519162434-uyq90pa.png)
5. 方式三：运行调试菜单

   ![image](/images/其他/image-20250519162527-cklcuu7.png)
6. 方式四：插件按钮

   ![image](/images/其他/image-20250519162607-klfazdk.png)
7. 自定义插件按钮图标：

   - 目前工程中添加了 user action 1（热更），user action 2（CV），user action 3（DH），可以通过脚本替换生效：

   ```shell
   cd WorldTourCasino/.vscode/scripts/
   ./replace_shortcut-menu-bar_icons.sh
   ```

   - 想自定义的话，可以自己做 svg 图，放到 `WorldTourCasino/.vscode/scripts/replace_shortcut-menu-bar_icons/icons`

   ![image](/images/其他/image-20250912115144-adr58ft.png)

‍
