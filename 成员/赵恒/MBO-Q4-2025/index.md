### Target 1 资源加载优化重构
#### 重构方案：
- [其他/优化重构/resource-v2/活动资源优化-后置加载方案](/其他/优化重构/resource-v2/活动资源优化-后置加载方案)
#### 实施记录：
- [其他/优化重构/resource-v2/WTC-res-load-improve.md](/其他/优化重构/resource-v2/WTC-res-load-improve.md)
#### 关键节点：
- [其他/优化重构/resource-v2/ResourceManV2内存优化.md](/其他/优化重构/resource-v2/ResourceManV2内存优化.md)
- [其他/优化重构/resource-v2/ActivityMan资源依赖检查优化.md](/其他/优化重构/resource-v2/ActivityMan资源依赖检查优化.md) 
- [其他/优化重构/resource-v2/活动补单-回调未执行导致进度卡住.md](/其他/优化重构/resource-v2/活动补单-回调未执行导致进度卡住.md)

### Target 2 优化关卡入口资源加载
- 风险分离，不与 Target 1 捆绑
- 依托 Target 1 中的资源管理机制