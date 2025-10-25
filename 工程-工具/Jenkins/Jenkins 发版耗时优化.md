# Jenkins 发版耗时优化

## 一、瓶颈分析：

1、文件量级增大，文件处理、图片压缩等耗时较长；

2、大量本地拷贝命令执行低效；

3、拷贝、同步命令使用不当，导致增量同步任务降级为全量同步；

​4、单个、大体量远程同步任务，若受网络波动影响，易大幅拉升任务时长；

## 二、优化处理：

​`git 版本：22a7bb73393a1a2ac630a1d32834a022db1adc6f`​

### 1、rclone 替换 rsync 做本地拷贝、同步：

![image](/assets/ce037db9d1341df503c27043a810b208.png)​

- 安装 rclone：`brew install rclone`​
- 开启并行传输，提升多核 CPU 使用率，大幅缩短任务时长；

  ```bash
  # 将源路径同步到目标路径（目标端会与源端完全一致，删除额外文件）
  rclone sync --transfers=8 src dest

  # 复制源路径到目标路径（不删除目标端额外文件）。
  rclone copy --transfers=8 src dest

  # 移动源路径到目标路径（复制后删除源文件）。
  rclone move --transfers=8 src dest

  # --transfers=8 并行传输文件数量，取决于带宽和磁盘性能，实测混合文件（大小不均）状态下，公司内部网络，8 比较合适
  # --checkers=N 设置并行检查文件的线程数（建议 ≥ --transfers，小文件需更高）
  # ------------------
  # 可平替 rsync 常用参数：
  # -v/--verbose
  # -P/--progress
  # -z/--compress 传输时压缩数据（适合文本类文件，不适合已压缩的图片 / 视频）
  # --checksum 使用校验和（而非时间 / 大小）比对文件，确保内容一致（增加 CPU 开销）
  # --exclude="PATTERN" 排除匹配模式的文件（如 --exclude="*.tmp" 排除临时文件）
  # --include="PATTERN" 仅包含匹配模式的文件（与 --exclude 配合可精确过滤）
  ```

### 2、优化 rsync 命令使用：

- cp -rL 拷贝目录后，会改变文件属性（打开时间、所属群组等），导致 rsync -a 同步目录时降档为全量同步：

  - 启用校验和（而非时间 / 大小）比对文件，确保内容一致（增加 CPU 开销）: `--checksum`​

  - 不传输目录时间戳不传输目录时间戳: `--omit-dir-times`​

  - 强制使用块级增量算法（仅传输文件中发生变化的部分，而非整个文件）: `--no-whole-file`​

    - 通过网络传输（如 SSH）时，rsync 会**自动启用增量模式**（等效于 `--no-whole-file`），但本地传输默认使用 `--whole-file`​
    - ​ **​`--whole-file`​**​ **（整文件传输）** ：比较源文件和目标文件的**大小和修改时间**，若不一致则整文件传输（无论文件多大，差异多小）。
- 启用压缩传输：`-z 压缩 --compress-level=3 压缩等级`​
- 本地-测试资源服：

  ```bash
  time rsync -av --omit-dir-times --partial ../../publish/html5/ $serverDomain:/usr/share/nginx/html/$fbRootPath/
  # 受测试服性能影响，如果使用-z、-c(--checksum)，实测性能跟不上，反而更消耗时间
  ```
- 本地-正式资源服：

  ```bash
  rsync -aczv --omit-dir-times --partial --compress-level=3 --exclude='.DS_Store' ../../publish/html5/ $serverDomain:/home/ec2-user/$fbRootPath/${versionName}/
  # 
  ```

### 3、time 命令监控子任务运行时长：

![image](/assets/40e632f1ce04ddab51c944690ed9503c.png)​

- set -x 打开原始命令 echo
- time 监控命令执行时长：

  ```bash
  rclone sync --transfers=8 --checkers=16 src dest
  1.56s user 1.53s system 527% cpu 0.585 total
  # usr: 命令本身花费时间
  # system：操作系统花费时间
  # cpu：cpu 使用率
  # total：命令开始到结束实际花费时间
  ```

### 4、移除冗余的拷贝、同步命令：

- 前置脚本 `sync_flavor.sh` ​中已经同步过一次

![image](/assets/c654b565c910e63d0782746401268bd7.png)​

## 三、剩余可优化空间：

- #### 图片压缩脚本耗时过长：

  目前在没有新的需要压缩图片的情况下，单纯遍历所有文件，需要 2m30s 左右
- #### 压缩管道拆分：

  研发管道分离到新打包机，避免抢占性能；

## 四、优化效果

#### Debug 管道：

平均降低任务时长 40%-50%

![image](/assets/664531cd65969fa27637d37d16c77661.png)​

![image](/assets/a0cc1b3b09a8d658d20d312e965297d4.png)​

#### Release 管道：

##### 总耗时（中间值）：↓～50%（36min → 18.5min）

Smoke 阶段：↓ ～30%-60%

Releaase 阶段：↓～10%-25%

Upload 阶段：↓～70%+

![image](/assets/6abc65724bcfeb0bb454637833cbced7.png)​

## 五、线上资源服动态资源管理：

##### 1. 增加动态资源退出清理机制：

    比如新关的宣发，用完从资源服下掉；

##### 2. 整理清除冗余动态资源：

    建议方法：还在用的整理出来，其余的全部干掉，漏的重新发；

##### 3. 后端 publish 脚本 cp 改 rsync：

    资源服上的版本同步不再使用 cp 方式，全部改成 rsync，同步完以后把 upload 目录的当前版本改成 reuse\_version；

##### 4. DH 的 hd 资源要干掉；

    i. 经查，DH 只有少量老旧关卡在用 hd 资源，最近 5 年以上没再出过 hd 资源，且 android 端因接口缺失，hd 资源一直未生效；
    ii. hd 资源处理造成额外耗时、占用额外空间；
    iii. 综合考虑决定直接干掉，hd 资源后续用新的压缩流程取代；

‍

---

## 附一：rsync 进阶指南

### **一、安装教程**

#### **1. macOS**

- **Homebrew 安装**（推荐）：

```
brew install rsync
```

- **升级系统自带版本**（macOS 自带 rsync 版本较低）：

```
# 下载源码并编译安装curl -O https://download.samba.org/pub/rsync/src/rsync-3.1.2.tar.gz tar -xvf rsync-3.1.2.tar.gzcd rsync-3.1.2./configuremakesudo make install  # 安装到/usr/local/bin
```

需打补丁以支持 macOS 特有属性（如 HFS 压缩、文件标志位）。

#### **2. Linux**

- **Debian/Ubuntu**：

```
sudo apt update && sudo apt install rsync
```

- **CentOS/RHEL**：

```
sudo yum install rsync
```

- **Arch Linux**：

```
sudo pacman -S rsync
```

> **注意**：同步双方均需安装 rsync。

### **二、基础语法与核心功能**

#### **1. 命令结构**

```
rsync [选项] 源路径 目标路径
```

- **源路径结尾加/** ：仅同步目录内容（不创建源目录本身）**示例**：rsync -a source\_dir/ dest\_dir/
- **源路径结尾不加/** ：同步整个目录（在目标路径创建同名目录）**示例**：rsync -a source\_dir dest\_dir/

#### **2. 核心特性**

- **增量同步**：仅传输修改部分（基于文件大小和修改时间）。
- **属性保留**：支持权限、时间戳、所有者等元数据同步。
- **压缩传输**：减少网络带宽消耗（-z 参数）。

### **三、常用参数详解**

#### **1.**   **基础同步参数**

|**参数**|**作用**|**示例**|
| -----------| ---------------------------------------------------------------------| ---------------------------------|
|-a(archive)|归档模式（等效 -rlptgoD），递归同步并保留权限、时间戳、属主等所有属性|rsync -a /src/ /backup/|
|-r|递归同步子目录（若未用 -a 需单独指定）|rsync -r \~/docs server:/backup|
|-R|使用相对路径（保持源目录结构）|rsync -R project/ server:/backup/|
|-x|不跨越文件系统边界（避免同步挂载的磁盘）|rsync -ax /mnt/disk1/ /mnt/disk2/|

#### **2.**   **文件属性保留**

|**参数**|**作用**|**示例**|
| --| -------------------------------| -----------------------------------|
|-p|保留文件权限（如 rwxr-xr-x）|rsync -p configs/ server:/etc/|
|-t|保留修改时间|rsync -t photos/ cloud:/albums/|
|-o|保留文件所有者（需 root 权限）|rsync -o root: /etc/ server:/backup|
|-g|保留文件属组|rsync -g www-data: /var/www backup|
|-H|保留硬链接|rsync -H src/ dest/|
|-X|保留扩展属性（macOS/Linux ACL）|rsync -X src/ dest/|

#### **3.**   **传输控制与优化**

|**参数**|**作用**|**示例**|
| --------------| ------------------------------------------------| -----------------------------------------|
|-z|传输时压缩（减少带宽）|rsync -az largefile remote:/data/|
|-P|显示进度 + 断点续传（等效 --partial --progress）|rsync -aP video.mp4 nas:/media/|
|--bwlimit\=KBPS|限制传输带宽（单位 KB/s）|rsync --bwlimit\=1000 src/ dest/|
|-c|基于文件内容校验（默认仅校验大小和时间）|rsync -c db.sql backup:/dbs/|
|-S|优化稀疏文件传输（节省空间）|rsync -S disk.img dest/|
|--partial|保留未完成传输的文件（用于中断后继续）|rsync --partial largefile remote:/backup/|

#### **4.**   **文件过滤与排除**

|**参数**|**作用**|**示例**|
| -------------------| ----------------------------------------| ------------------------------------------------------|
|--exclude\=PATTERN|排除匹配的文件/目录（支持通配符）|rsync -a --exclude\='\*.log' src/dest/|
|--include\=PATTERN|包含匹配的文件/目录（与 --exclude 配合）|rsync -a --include\='\*.txt' --exclude\='\*' src/ dest/|
|--exclude-from\=FILE|从文件读取排除规则|rsync -a --exclude-from\=ignore.list src/ dest/|
|--delete|删除目标端多余文件（严格同步）|rsync -a --delete src/ dest/|
|--delete-excluded|同时删除目标端被排除的文件|rsync -a --exclude\='tmp/' --delete-excluded src/ dest/|

#### **5.**   **高级功能**

|**参数**|**作用**|**示例**|
| --------------------| ------------------------------------------| -----------------------------------------------------------|
|--link-dest\=DIR|增量备份硬链接优化（未修改文件引用旧备份）|rsync -a --link-dest\=/backup/yesterday/ src/ /backup/today/|
|-essh|指定 SSH 协议（支持自定义端口/密钥）|rsync -av -e 'ssh -p 2222 -i key.pem' src/ user@host:dest/|
|--password-file\=FILE|从文件读取密码（守护进程模式认证）|rsync -av src/ user@host::module/ --password-file\=pass.txt|
|-n(--dry-run)|模拟执行（测试命令效果）|rsync -anv src/ dest/|
|--stats|显示传输统计信息（文件数量、传输量等）|rsync -a --stats src/ dest/|

### **四、高级用法**

#### **1. 增量备份与硬链接优化**

```
rsync -a --link-dest=/path/to/previous_backup src/ /new_backup/
```

-  **--link-dest**：对未修改文件创建硬链接，节省磁盘空间（适用于每日备份）。

#### **2. 实时同步方案**

- **结合 cron 定时任务**（非实时但自动化）：

```
# 编辑crontab：crontab -e* * * * * rsync -az /path/src user@remote:/path/dest
```

- **实时工具扩展**：使用 lsyncd 监控文件变化并触发 rsync（需额外安装）。

#### **3. macOS 特有属性同步**

```
rsync -aNHAXx --hfs-compression --fileflags src/ dest/
```

- **关键参数**：

  -N（创建时间）、--hfs-compression（HFS 压缩文件）、-X（扩展属性）、--fileflags（文件标志位）。

#### **4. 守护进程模式（Rsync Daemon）**

- **服务端配置**（/etc/rsyncd.conf）：

```
[backup]path = /data/backupread only = noauth users = rsync_usersecrets file = /etc/rsyncd.secrets
```

- **客户端同步**：

```
rsync -av src/ rsync_user@host::backup/ --password-file=/path/passwd
```

适用于大规模内网同步，无需 SSH 但需配置认证。

### **五、性能优化技巧**

1. **禁用压缩与简化加密**（高速局域网适用）：

    ```bash
    export RSYNC_RSH="ssh -T -c aes128-ctr -o Compression=no -x" rsync -av src/ dest/
    ```

    -T 禁用伪终端、aes128-ctr 为轻量加密算法。
2. **带宽限制**（避免拥塞）：

    ```bash
    rsync --bwlimit=1000 src/ dest/  # 限制为1000KB/s
    ```
3. **稀疏文件处理：**

    ```bash
    rsync -S src/ dest/  # 优化空文件块传输
    ```
4. **并行传输**（大数据场景）：

    ```bash
    # 使用parallel工具拆分任务
    find src/ -type f | parallel -j 4 rsync -a {} dest/
    ```
5. **校验和检测**（确保数据一致性）：

    ```bash
    rsync -c src/ dest/  # 基于文件内容校验（默认仅校验大小和时间）
    ```

### **六、常见问题**

1. **SSH 免密登录**：

    ```bash
    ssh-keygen  # 本地生成密钥ssh-copy-id user@remote  # 上传公钥
    ```

    避免每次同步输入密码。
2. **权限错误**：

    macOS：若同步系统文件需关闭 SIP（不推荐）或使用 sudo。

    Linux：确保目标目录可写（chmod 调整权限）。
3. **部分文件同步失败**：

    使用--partial 保留中断传输的部分文件，下次继续传输。

### 七、关键注意事项

#### 1. **路径结尾斜杠**：

- src/ 同步目录**内容**（不创建 src 目录本身）
- src 同步**整个目录**（在目标路径创建 src 目录）。

#### 2. **权限问题**：

- Linux：目标目录需可写（chmod 调整）。
- macOS：同步系统文件需 sudo 或关闭 SIP（不推荐）。

#### 3. **守护进程模式**：

- 服务端需配置 /etc/rsyncd.conf，定义模块路径、认证用户等。
- 客户端同步格式：rsync user@host::module/path（双冒号分隔）。

#### 4. **实时同步方案**：

- **定时任务**：cron 定期执行（如 \* \* \* \* \* rsync -az /src dest）。
- **实时监控**：lsyncd 监听文件变化并触发 rsync（需额外安装）。

---

## 附三、rsync 并发方案

#### 1. 使用 xargs 实现并发

通过 `find` 命令生成文件列表，再利用 `xargs` 的 `-P` 参数指定并发数：

```bash
find /source/dir -type f -print0 | \
  xargs -0 -I{} -P 10 rsync -avz {} user@host:/target/dir/$(dirname {})
```

**参数说明**：

- ​`-P 10`：启用 10 个并发进程
- ​`-print0`/`-0`：使用 null 分隔文件名，避免空格等特殊字符问题

#### 2. 使用 GNU Parallel 工具

GNU Parallel 是专门设计的并行执行工具，语法更简洁：

```bash
# 安装（Ubuntu/Debian）
sudo apt-get install parallel

# 并行同步目录
find /source/dir -type d -print0 | \
  parallel -0 -j 5 rsync -avz {}/ user@host:/target/dir/{/}/
```

**参数说明**：

- ​`-j 5`：指定 5 个并行任务
- ​`{/}`：提取目录名（不包含完整路径）

#### 3. 基于文件列表的并发同步

先创建需要同步的文件列表，再分块处理：

```bash
# 生成文件列表
find /source/dir -type f > filelist.txt

# 分割文件列表并并行处理
split -l 100 filelist.txt chunk_
for chunk in chunk_*; do
  (while read file; do
    rsync -avz "$file" user@host:/target/"$file"
  done < "$chunk") &
done
wait
```

#### 4. 针对大文件的并发传输优化

对于大文件较多的场景，可以结合 `split` 和 `rsync` 分段并行传输：

```bash
# 分割大文件并同步
split -b 1G large_file.iso large_file.part.
for part in large_file.part.*; do
  rsync -avz "$part" user@host:/target/dir/ &
done
wait

# 在目标端合并文件
cd /target/dir/
cat large_file.part.* > large_file.iso
```

‍

---

## 附二： rclone 进阶指南

### 一、安装与配置

#### **1. 多平台安装**

- **Linux/macOS** 推荐使用脚本安装（支持稳定版/测试版）：

```
curl https://rclone.org/install.sh  | sudo bash        # 稳定版curl https://rclone.org/install.sh  | sudo bash -s beta     # 测试版
```

手动安装（适用于自定义路径）：

```
curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip unzip rclone-*.zipsudo cp rclone-*/rclone /usr/bin/
```

- **Windows** 官网下载 rclone.exe 并添加至 PATH，或通过包管理器安装：

```
winget install Rclone.Rclone    # Wingetchoco install rclone       # Chocolatey
```

#### **2. 配置云存储**

- 交互式配置：运行 rclone config，按提示选择存储类型（如 s3、webdav）并输入认证信息（API 密钥、令牌等）。
- 配置文件路径：
- Linux/macOS： \~/.config/rclone/rclone.conf
- Windows： C:/Users/用户名/AppData/Roaming/rclone/rclone.conf
- **示例（阿里云 OSS 配置）** ：

```
[oss]type = s3provider = Alibabaaccess_key_id = YOUR_ACCESS_KEYsecret_access_key = YOUR_SECRET_KEYendpoint = oss-cn-hangzhou.aliyuncs.comacl = private
```

### 二、核心语法解析

#### **1. 命令结构**

```
rclone [全局选项] 子命令 [子命令选项] 源路径 目标路径
```

- **全局选项**： --config（指定配置文件）、-v（详细日志）、--dry-run（模拟运行）。
- **路径格式**： \<配置名\>:\<路径\>（如 mygdrive:/docs），本地路径直接使用绝对或相对路径。

#### **2. 常用子命令**

|**命令**|**作用**|**示例**|
| -----| ----------------------------| ------------------------------------|
|copy|复制文件（跳过已存在文件）|rclone copy /local remote:backup|
|sync|单向同步（目标与源完全一致）|rclone sync src remote:dst --dry-run|
|move|移动文件（源文件删除）|rclone move src remote:dst|
|mount|挂载为本地磁盘|rclone mount remote: /mnt/cloud|
|size|统计存储占用|rclone size remote:path|
|check|校验源与目标一致性|rclone check src remote:dst|

#### 3. 命令参数详解

- ##### **传输控制与性能优化参数**

|**参数**|**说明**|**默认值**|**使用示例**|
| -----------------------| -------------------------------------------------------------| ----| ----------------------------------|
|--transfers N|并行传输的文件数，影响带宽占用和内存消耗|4|rclone copy src dst --transfers 16|
|--checkers N|并行校验文件的线程数（如哈希计算、大小比对）|8|rclone sync src dst --checkers 32|
|--bwlimit UP:DOWN|分时段限速（单位：B/k/M/G），支持时间区间|无|--bwlimit "08:00,10M 22:00,off"|
|--fast-list|单次 API 调用获取全部文件列表（减少请求次数，但增加内存占用）|关闭|rclone ls remote: --fast-list|
|--no-traverse|跳过目标端遍历（目标文件极多时提速显著）|关闭|rclone copy src dst --no-traverse|
|--s3-upload-cutoff SIZE|分片上传阈值（超过此大小自动分片）|200M|--s3-upload-cutoff 5G|
|--s3-chunk-size SIZE|分片大小（增大可提升吞吐，但需更高内存）|5M|--s3-chunk-size 256M|
|--s3-upload-concurrency|并发上传的分片数|4|--s3-upload-concurrency 16|
|--cache-chunk-size SIZE|缓存块大小（影响挂载模式下的读写性能）|5M|--cache-chunk-size 10M|

- ##### **数据校验与过滤参数**

|**参数**|**说明**|**示例**|
| -----------------------| ----------------------------------------------------| -------------------------------------------|
|--checksum|通过哈希值（MD5/SHA1）校验文件变更（确保数据一致性）|rclone sync src dst --checksum|
|--size-only|仅根据文件大小判断变更（忽略修改时间）|rclone copy src dst --size-only|
|--update|仅同步修改时间更新的文件（目标端文件较旧时覆盖）|rclone sync src dst --update|
|--max-age TIME|仅同步指定时间内修改的文件（如 24h、30d）|rclone copy src dst --max-age 48h|
|--exclude "PATTERN"|排除匹配的文件/目录（支持通配符 \* 和 {}）|--exclude "\*.tmp"|
|--include "PATTERN"|仅包含匹配的文件/目录（与 --exclude 组合使用）|--include "\*.{jpg,png}"|
|--create-empty-src-dirs|同步空目录（默认忽略）|rclone sync src dst --create-empty-src-dirs|

- ##### **日志与安全参数**

|**参数**|**说明**|**示例**|
| ------------------| ----------------------------------------| -----------------------------------|
|-P / --progress|实时显示传输进度（500ms 刷新）|rclone copy src dst -P|
|-v / --verbose|输出详细日志（调试时建议使用）|rclone sync src dst -v|
|--log-file FILE|保存日志到文件|--log-file\=/var/log/rclone.log|
|--dry-run|模拟运行（不实际执行操作，用于验证命令）|rclone delete remote:path --dry-run|
|--password-command|从外部命令获取密码（避免明文存储）|--password-command "pass rclone"|
|--retries N|失败重试次数（网络波动时必备）|rclone copy src dst --retries 5|

- ##### **挂载专用参数**

|**参数**|**说明**|**示例**|
| ---------------------| ------------------------------------------------------------------------------| -------------------------------------------|
|--vfs-cache-mode MODE|缓存模式：off（禁用）、minimal（仅读缓存）、writes（写缓存）、full（读写缓存）|--vfs-cache-mode writes|
|--allow-other|允许非挂载用户访问（需系统支持）|rclone mount remote: /mnt --allow-other|
|--allow-non-empty|允许挂载到非空目录|rclone mount remote: /mnt --allow-non-empty|
|--daemon|后台运行挂载进程|rclone mount remote: /mnt --daemon|

- ##### **特殊场景参数**

|**参数**|**说明**|**示例**|
| --------------------| ---------------------------------------------------------| -------------------------------------------------------|
|--copy-links|解析符号链接（复制链接指向的文件内容）|rclone copy src dst --copy-links|
|--delete-excluded|同步时删除目标端被排除的文件（sync 命令专用）|rclone sync src dst --exclude "\*.log" --delete-excluded|
|--use-server-modtime|使用服务端时间戳（解决部分存储如 Swift 的时间戳兼容问题）|rclone sync src dst --use-server-modtime|

### 三、基础操作

#### **1. 文件同步与备份**

- **增量备份**：

```
rclone sync /data remote:backup --checksum  # 通过哈希校验仅同步变更文件
```

- **加密备份**： 使用 crypt 模块加密后同步：

```
rclone sync /data crypt_remote:backup --crypt-remote=crypt:
```

#### **2. 数据恢复与迁移**

- **云到云迁移**：

```
rclone copy s3_remote:bucket oss_remote:bucket --fast-list
```

- **恢复加密数据**：

```
rclone copy crypt_remote:backup /restore --crypt-remote=crypt:
```

### 四、高级应用场景

#### **1. 挂载为本地文件系统**

```
rclone mount remote:path /mnt/cloud --vfs-cache-mode writes --allow-other --daemon          # 允许其他用户访问 --allow-other                  
# 启用写缓存 --vfs-cache-mode writes
# 后台运行 --daemon
```

**参数说明**：

- --vfs-cache-mode full：提升读写性能（需更多内存）。
- **开机自启**：通过 systemd 创建服务（示例见 ）。

#### **2. 双向同步（Bisync）**

```bash
rclone bisync /local remote:path --resync --check-access                
# 首次全量同步              # 验证读写权限
```

适用于需双向更新的场景（如团队协作目录）。

#### **3. 自动化任务**

结合 cron 定时同步：

```bash
0 2 * * * rclone sync /backup remote:daily_backup --log-file=/var/log/rclone.log
```

### 五、性能优化技巧

#### **1. 传输并发控制**

- --transfers N：并行传输文件数（默认 4，建议根据带宽调整）：

```
rclone copy src remote:dst --transfers 16   # 增加并行数加速大文件传输
```

- --checkers N：并行校验文件数（默认 8，小文件多时可提高）：

```
rclone sync src remote:dst --checkers 32    # 加速哈希校验
```

#### **2. 内存与 API 优化**

- --fast-list：单次 API 调用列出所有文件（减少请求次数，但增加内存占用）：

```
rclone ls remote: --fast-list   # 适合交易付费或小规模存储
```

- --no-traverse：跳过目标目录遍历（目标文件多时显著提速）：

```
rclone copy src remote:dst --no-traverse
```

#### **3. 大文件传输调优**

```
rclone copy largefile remote:dst --s3-upload-cutoff 5G --s3-chunk-size 256M --s3-upload-concurrency 16
# 分片上传阈值（默认200M） --s3-upload-cutoff 5G
# 分片大小（默认5M） --s3-chunk-size 256M
# 并发上传分片数 --s3-upload-concurrency 16
```

> **注**：v1.64+ 版本重构多线程传输，云到云传输速度提升 3 倍。

### 六、注意事项与最佳实践

1. **数据安全**：

- sync 和 delete 会删除目标端文件，操作前务必用 --dry-run 预览。
- 敏感信息（如密钥）避免明文存储，使用环境变量或加密配置。

2. **版本兼容性**：

- 定期更新至最新版（rclone selfupdate），修复性能问题和传输错误。

3. **传输稳定性**：

- 网络波动时添加 --retries 10 自动重试。
- 使用 --bwlimit 08:00,100M 22:00,off 分时段限速。

4. **特殊场景处理**：

- **符号链接**：添加 --copy-links 解析链接（默认忽略）。
- **时间戳保留**：部分存储（如 Swift）需启用 --use-server-modtime。
