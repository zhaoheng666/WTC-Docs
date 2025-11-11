---
title: Adjust 买量前广告接入需求
date: '2025-11-11 11:20:58'
head: []
outline: deep
sidebar: false
prev: false
next: false
---



# Adjust 买量前广告接入需求

## RevWorks - Adjust 广告收入解决方案
---

### 🛠️ 一、[用户级广告收入](https://help.adjust.com/en/article/ad-revenue-solution#user-level-ad-revenue) 三种方案：


- #### 1、**[广告聚合平台收入 API 关联](https://help.adjust.com/zh/article/ad-revenue-api)**

  这个是各广告平台后台关联设置，有客户经理账号，自行配置即可
- #### 2、**[平台收入 SDK 连接](https://help.adjust.com/en/article/ad-revenue-sdk)**

  ![image](/assets/image-20251111112648-5p6j916.png)

  - 我们当前 sdk 版本已经满足：![image](/assets/image-20251111112714-ri29l22.png)

  - 开启 [Enable background recording](https://dev.adjust.com/en/sdk/android/configuration/#enable-background-recording) 即可

    ![image](/assets/image-20251111112141-85x0pzg.png)

- #### 3、**[网络收入 S2S 连接](https://help.adjust.com/en/article/ad-revenue-s2s)**

  服务器接入API 主动上报；
‍

### 🔗 二、[网络级别的聚合广告收入](https://help.adjust.com/en/article/ad-revenue-solution#network-level-aggregated-ad-revenue)

- **[Aggregated ad revenue via network API](https://help.adjust.com/en/article/ad-revenue-network-api)**

  - adjust 后台做 connect 即可；

  - 只能检索“汇总”的广告收入数据并记录移动广告收入；
    Network-level ad revenue pulled from network APIs is aggregated and not user- or impression-level‍


## 发送广告收入信息
---

[https://dev.adjust.com/zh/sdk/android/features/ad-revenue/](https://dev.adjust.com/zh/sdk/android/features/ad-revenue/)

![image](/assets/image-20251111114548-s9orlp6.png)

![image](/assets/image-20251111114602-e4w4o7m.png)

#### 接口已经有了、明确下缺哪个补哪个就行了
