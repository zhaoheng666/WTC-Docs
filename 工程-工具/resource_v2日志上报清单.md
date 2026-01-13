# Resource-V2 日志上报清单

## P0 上报（6处）

1. LoaderRegistry.js:316 - Loader 创建失败
2. DownloadQueue.js:587 - 队列任务永久失败
3. NativeDownloader.js:91 - Native 下载失败
4. CanvasDownloader.js:232 - Canvas 下载失败（image）
5. CanvasDownloader.js:321 - Canvas 下载失败（audio）
6. CanvasDownloader.js:350 - Canvas 下载失败（其他）

## P1 上报（12处）

1. DownloadQueue.js:913 - 后台恢复检查完成
2. ActivityLoader.js:148 - activity 批量加载完成
3. ClubActivityLoader.js:135 - club_activity 批量加载完成
4. PosterLoader.js:105 - poster 批量加载完成
5. CardSystemLoader.js:133 - card_system_chapter 批量加载完成
6. CardSystemLoader.js:209 - card_system_card 批量加载完成
7. CardSystemLoader.js:283 - card_system_resource 批量加载完成
8. SlotLoader.js:175 - slot 批量加载完成
9. StoreLoader.js:109 - store 批量加载完成
10. CouponLoader.js:110 - coupon 批量加载完成
11. LobbyBoardLoader.js:103 - lobby_board 批量加载完成
12. LobbyThemeLoader.js:89/158/253 - lobby_theme 批量加载完成（3次）
13. FeatureLoader.js:324/366 - feature 批量加载完成（2次）
