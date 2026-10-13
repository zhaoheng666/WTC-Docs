---
title: AppCharge 接入 SOP
---

# AppCharge 接入 SOP

> 源自飞书文档 · 最后同步：2026-10-13

> 这是针对“Web/Facebook AppCharge 与 Android 外链 checkout 接入”的标准操作手册。
以 CV 已上线实现为移植基准，先核对来源分支和实例参数，仅做目标产品需要的主题、地址及依赖适配；不要自行重写线上已有行为。

## 0. 实例参数

当前实例为 VegasStar；执行其他产品时，填写相同的参数项，再核对该产品的主题常量、源文件覆盖关系和发布配置。

| 参数 | 当前实例值 |
| --- | --- |
| `TARGET_BRANCH` | `classic_vegas_vs_v272` |
| `FLAVOR` | `res_vegasstar` |
| 接入平台 | `Web/Facebook`、`Android 外链 checkout` |
| `APPCHARGE_THEME`（JavaScript） | `ThemeName.THEME_VEGAS_STAR` |
| `SDK_REF` | `87648740e5193f1129767d279e8a910c1b0b0474` |
| SDK SHA-256 | `2d7b56e20113f79f83570882615885d23b77e64144eda8b95ac802ed197aa42f` |

在目标仓库根目录执行以下变量设置；后续命令使用这些变量：

```
TARGET_BRANCH=classic_vegas_vs_v272
FLAVOR=res_vegasstar
SDK_REF=87648740e5193f1129767d279e8a910c1b0b0474
```

完成定义：Web 登录后按服务端开关初始化 AppCharge，购买时获取 session 并打开 checkout；Android 按独立服务端开关切换外链或原生 IAP。支付完成后沿用目标产品已有的购买校验、发货和领奖流程；本地构建与 Facebook 发布产物都能加载同一份 SDK。

## 1. 固定规则

1. 只在实例参数指定的独立、干净工作树执行。目标分支当前提交的资源版本可能与分支名不同；版本始终读取 ${FLAVOR}/resource_dirs.json，不能从分支名推断。
1. 本 SOP 适用于 Web/Facebook 及 Native 外链 checkout。沿用 CV 的主题、cc.sys.isNative 和服务端开关判定；不要自行增加 OS 限制、严格布尔判定、登录状态重置或异常分流。目标产品需要的差异必须明确说明。
1. AppCharge SDK 使用已批准的在线基线 artifact，只复制 SDK 文件，不复制其他产品的业务源文件。记录来源 ref、文件 hash 和实际发布 URL。
1. 客户端信任服务端平台策略。checkoutPlatformStatus.appcharge 控制 Web SDK；checkoutPlatformStatus.appcharge_android_web 是 CV 已有服务端字段，控制 Native 外链。保留 CV 的原有取值判断，不伪造开关或 token。
1. checkoutUrl 必须按服务端返回值原样传给 SDK。客户端不重新拼接 query、session token 或旧版 URL。
1. 主工程 src 下的新增 JavaScript 遵守 ES5：使用 var、function，不使用 const、let、箭头函数、模板字符串或可选链。独立的 vendor SDK appcharge.js 保留已批准版本的原始语法，不要重写。
1. checkoutSessionToken、appchargeCheckoutToken 不得写入提交、截图或普通日志。Native 外链沿用 CV 的 logUserAction 埋点，不另加打印完整 URL 的调试日志；共享日志和截图时脱敏真实玩家标识。
1. 如果目标分支没有 WebStoreResultController 及其资源，AppCharge 订单完成后沿用目标产品已有的 PurchaseResultController；不要为了本次接入复制另一套 WebStore 领奖 UI。若产品另有专属领奖板需求，另开独立 UI 变更。
## 2. 接入前确认

在目标分支工作树执行：

```
git status --short
# 确认工作树可用后再切换
git fetch origin --prune
git switch "${TARGET_BRANCH}"
git pull --ff-only origin "${TARGET_BRANCH}"
test "$(git branch --show-current)" = "${TARGET_BRANCH}"
```

工作树有不明修改时先停止。不要用 stash 覆盖别人的修改，也不要清理与本任务无关的已有 dirty 状态。

读取目标资源版本和 CDN：

```
jq -r '
  "releaseVersion=\(.releaseInfo.versionName)",
  "releaseFbPackageUrl=\(.releaseInfo.fbPackageUrl)",
  "debugVersion=\(.debugInfo.versionName)",
  "debugPackageUrl=\(.debugInfo.packageUrl)"
' "${FLAVOR}/resource_dirs.json"
```

确认目标基线：

```
git grep -n -i -E 'AppchargeCheckout|appchargeCheckout|checkoutPlatformStatus|checkoutServerApi' -- src "${FLAVOR}" scripts || true
jq -e '.dependencies["appcharge-checkout-js-sdk"]' package.json
jq -e '.packages["node_modules/appcharge-checkout-js-sdk"]' package-lock.json
test "$(jq -r '.externalJsList | index("appcharge.js")' "${FLAVOR}/resource_dirs.json")" = "null"
test ! -e appcharge.js
test ! -e "${FLAVOR}/flavor/appcharge.js"
rg -n 'appcharge.js|game.min.js' "${FLAVOR}/flavor/index.template.html" scripts/sync_flavor.sh || true
```

当前实例的预期基线是：

- package.json 和 package-lock.json 已有 SDK 依赖；
- src、目标 flavor 模板和目标 manifest 没有 AppCharge 运行时接入；
- sync_flavor.sh 没有复制 appcharge.js；
- root appcharge.js 在目标分支不存在；
- ServerConfig、PlayerMan、SwitchMan、StoreMan 尚未加入 AppCharge 字段和流程。
更换实例时先重新核对这组基线；如果目标已经有部分接入，逐项比对本文，不能把其他分支的大文件直接覆盖到目标分支。

## 3. 服务端契约

客户端只实现下表契约；接口地址、token 和开关值由服务端提供。

| 位置 | 类型 | 约束 |
| --- | --- | --- |
| serverConfig.checkoutPlatformStatus.appcharge | boolean | true 才允许目标主题的 Web checkout |
| serverConfig.checkoutPlatformStatus.appcharge_android_web | boolean | CV 已有的服务端字段；随 checkoutPlatformStatus 整体透传，按 CV 的 Native 登录分支读取，不新增客户端默认字段 |
| serverConfig.appchargeCheckoutToken | string | 登录响应提供；为空时禁止初始化 |
| serverConfig.checkoutServerApi | string | 创建 checkout session 的 HTTPS 地址；为空时购买失败并提示 |
| session POST playerId | number/string | 使用当前登录玩家 ID |
| session POST productId | string | 使用 ShopProduct.pid |
| session POST productFuncType | number | 使用 ShopProduct.funcType，不能客户端改成固定值 |
| session response code | number | 必须为 200 |
| session response data.url | string | 完整 checkout URL，原样使用 |
| session response data.checkoutSessionToken | string | 非空，原样传给 SDK |
| session response data.purchaseId | string | 非空，传给 SDK 并用于服务端订单关联 |
| 支付完成消息 | S2CVerifyPurchase/S2CConsumePurchase | 沿用目标产品现有校验、consume、领奖链路；不从前端回调直接发货 |

Web checkout 的服务端开关已开启但没有提供有效 token、session URL 或 session 字段时，客户端必须关闭购买指示器、记录脱敏错误并显示通用 checkout 错误提示。不要在客户端生成备用 token 或备用接口地址。Android 外链不在客户端初始化 Web SDK，参数和地址见“Android 外链 checkout”。

## 4. SDK 与资源接入

### 4.1 放入目标 flavor

使用已审核的不可变 SDK artifact。当前审核基线为提交 87648740e5193f1129767d279e8a910c1b0b0474；它的 appcharge.js hash 为 2d7b56e20113f79f83570882615885d23b77e64144eda8b95ac802ed197aa42f。浅克隆找不到该对象时，取同一 hash 的已批准 artifact，不要临时从其他 flavor 拼接：

```
git cat-file -e "${SDK_REF}:appcharge.js"
git show "${SDK_REF}:appcharge.js" > "${FLAVOR}/flavor/appcharge.js"
cp "${FLAVOR}/flavor/appcharge.js" appcharge.js
node --check "${FLAVOR}/flavor/appcharge.js"
node --check appcharge.js
shasum -a 256 "${FLAVOR}/flavor/appcharge.js" appcharge.js
cmp -s "${FLAVOR}/flavor/appcharge.js" appcharge.js
```

如果 SDK 来自已下载的在线发布文件，替换上面的来源命令，但必须保留来源 URL/ref 和 hash 记录。SDK 版本必须具备以下行为：

- AppchargeCheckout 使用服务端返回的完整 checkout URL；
- postMessage 只接受 new URL(checkoutUrl).origin；
- checkout 关闭时移除 message listener 并移除 iframe；
- AppchargeCheckoutInit 的 environment 在 Release 使用 prod，Local/Debug 使用 sandbox。
不要把 npm 包 import 到 src；该包是依赖元数据，页面运行时加载的是 appcharge.js。

### 4.2 HTML 模板

编辑 "${FLAVOR}/flavor/index.template.html"，在 game.min.js 后加入：

```
<script src="#{RESOURCEPATH}game.min.js"></script>
<script src="#{RESOURCEPATH}appcharge.js"></script>
```

不要手改 "${FLAVOR}/flavor/index.html"。它由 scripts/index_replace.sh 根据 LOCAL、DEBUG、RELEASE 和 resource_dirs.json 生成。

### 4.3 资源清单

编辑 "${FLAVOR}/resource_dirs.json" 的 externalJsList，在两个 Facebook SDK 后加入 appcharge.js：

```
"externalJsList": [
  "libZenSDK/thirdparty/web/facebook_sdk.js",
  "libZenSDK/platform/web/social/zen_facebook.js",
  "appcharge.js"
]
```

build_fb.sh 会按该清单从仓库根目录复制外部脚本；缺少这一项时，发布目录不会有 appcharge.js。

将 resource_dirs.json 作为核心配置纳入版本控制，并随接入代码提交 externalJsList 中的 appcharge.js；不得将整个文件作为构建产物排除。构建结束后，只恢复不属于本次任务的临时环境开关和版本变化，保留功能配置及本次明确要求的发布配置变更。

### 4.4 flavor 同步脚本

编辑 scripts/sync_flavor.sh，在 flavor CSS/project 文件同步附近加入：

```
if [ -f "../${resPath}/flavor/appcharge.js" ]; then
    rsync -av "../${resPath}/flavor/appcharge.js" ../
fi
```

然后执行：

```
cd scripts
./sync_flavor.sh "${FLAVOR}"
cd ..
cmp -s appcharge.js "${FLAVOR}/flavor/appcharge.js"
```

root appcharge.js 要纳入本次接入提交；它是构建脚本读取的根目录外部脚本，不是可以长期留在工作树的临时文件。

## 5. 客户端接入

先检查 ${FLAVOR}/flavor/js_src/ 是否覆盖本文涉及的源文件：有覆盖时修改 flavor 源文件；没有覆盖时修改 src 原文件。否则 sync_flavor 会覆盖接入代码。当前实例的四个业务文件均以 src 为修改位置。保留原文件的严格模式，并为新增非平凡方法补 JSDoc。

### 5.1 ServerConfig：读取登录配置

文件：src/common/entity/ServerConfig.js

在构造函数中加入默认值：

```
this.appchargeCheckoutToken = null;
this.checkoutServerApi = null;
this.checkoutPlatformStatus = {
    appcharge: false
};
```

在 unmarshal 末尾加入：

```
if (jsonObj.hasOwnProperty("checkoutPlatformStatus")) {
    this.checkoutPlatformStatus = jsonObj["checkoutPlatformStatus"] || {
        appcharge: false
    };
}
if (jsonObj.hasOwnProperty("appchargeCheckoutToken")) {
    this.appchargeCheckoutToken = jsonObj["appchargeCheckoutToken"] || null;
}
if (jsonObj.hasOwnProperty("checkoutServerApi")) {
    this.checkoutServerApi = jsonObj["checkoutServerApi"] || null;
}
```

不要把服务端缺少字段解释为开启。默认必须保持关闭。

### 5.2 StoreMan：增加状态和网络依赖

文件：src/store/model/StoreMan.js

在现有 require 区加入：

```
var HttpClient = require("../../common/net/HttpClient");
```

在 StoreMan 类字段区加入：

```
checkoutPlatformStatus: {
    appcharge: false
},
appchargeCheckoutToken: null,
appchargeCheckoutSessionUrl: null,
```

沿用 CV 的登录字段处理和支付分流，Android 外链状态由 PlayerMan.isForceUseCheckoutOnAndroid 保存，不以 Web SDK 初始化结果代替 Native 服务端开关。

### 5.3 SwitchMan：按主题和平台限制

文件：src/common/model/SwitchMan.js

先在 SwitchMan.js 的 ThemeName require 后声明实例主题。以下声明对应第 0 节的实例参数，其他产品替换常量值：

```
var APPCHARGE_THEME = ThemeName.THEME_VEGAS_STAR;
```

在支付相关开关附近加入两个方法：

```
isEnableAppchargeCheckoutInit: function () {
    if (cc.sys.isNative) {
        return false;
    }
    if (!SwitchMan.isHitTheme(APPCHARGE_THEME)) {
        return false;
    }
    return typeof AppchargeCheckoutInit === "function";
},

isEnableAppchargeCheckout: function () {
    if (cc.sys.isNative) {
        return false;
    }
    if (!SwitchMan.isHitTheme(APPCHARGE_THEME)) {
        return false;
    }
    if (typeof AppchargeCheckoutInit !== "function") {
        return false;
    }
    return game.StoreMan.getInstance().checkoutPlatformStatus.appcharge === true;
},
```

不要把开关加入已有的其他主题数组。目标产品以主题、平台、SDK 函数和服务端开关四项同时满足为准。

### 5.4 PlayerMan：登录后初始化

文件：src/common/model/PlayerMan.js

对照 CV 上线版本的 _onLogin，在 DebugMan.initDebug() 后保留其执行顺序：

1. 为目标产品扩展 CV/DH 主题条件；Native 收到 checkoutPlatformStatus.appcharge_android_web 开启值时，设置 isForceUseCheckoutOnAndroid 并 return。
1. Web 按原有 appcharge 开关初始化 SDK，保存 checkoutServerApi。
1. 保留来源实现的 ckoChargePublicKey、ckoChargeServerApi、triple、checkout 字段处理。
isForceUseCheckoutOnAndroid 的类字段初始值为 false。不要额外加入每次登录清空支付状态、严格布尔校验或 Android OS 判断；这些都属于行为变更，不是本次移植所需的产品适配。

### 5.5 StoreMan：购买分流

目标分支 buyProduct 的结构是：

1. 记录商品和 extraInfo；
1. 处理本地模拟购买；
1. 调用一次 _onPurchaseStart；
1. Native 分支；
1. Facebook Web 分支。
在第 3 步之后、Native 分支之前插入 AppCharge 分支。不要再调用第二次 _onPurchaseStart：

```
if (!cc.sys.isNative && game.switchMan.isEnableAppchargeCheckout()) {
    this.getAppchargeCheckoutSession(
        shopProduct.pid,
        shopProduct.funcType,
        function (checkoutUrl, checkoutSessionToken, purchaseId) {
            this.applyAppchargeCheckout(
                this.appchargeCheckoutToken,
                checkoutUrl,
                checkoutSessionToken,
                purchaseId
            );
        }.bind(this),
        function (error) {
            this._onPurchaseQuit();
            LogMan.getInstance().logAppErrorInfo(
                "AppchargeCheckoutError",
                JSON.stringify(error)
            );
            PopupMan.popupCommonDialogWithConf(
                "UI_MESSAGE_APPCHARGE_CHECKOUT_GET_SESSION_ERROR"
            );
        }.bind(this)
    );
    this.inactivateMultiPurchase();
    return;
}
```

这样可以保证：AppCharge 请求失败不会落入 Facebook payment；Native 不会误进入 iframe；多倍购买状态会被释放。

### 5.6 StoreMan：获取 session

在 StoreMan 类中加入以下职责等价的 ES5 方法。方法名和字段名必须保持一致，方便日志和排障：

```
getAppchargeCheckoutSession: function (productId, productFuncType, onSucceed, onFailed) {
    var headers = {
        "Content-Type": "application/json;charset=UTF-8"
    };
    var url = this.appchargeCheckoutSessionUrl;
    if (!url) {
        if (cc.isFunction(onFailed)) {
            onFailed({reason: "checkout session url is empty"});
        }
        return;
    }

    var data = {
        playerId: game.PlayerMan.getInstance().playerId,
        productId: productId,
        productFuncType: productFuncType
    };

    HttpClient.doPost(
        url,
        JSON.stringify(data),
        headers,
        function (error, responseText) {
            if (error || !responseText) {
                if (cc.isFunction(onFailed)) {
                    onFailed({reason: "checkout session http error", status: error});
                }
                return;
            }

            var response = null;
            try {
                response = JSON.parse(responseText);
            } catch (e) {
                if (cc.isFunction(onFailed)) {
                    onFailed({reason: "checkout session json error"});
                }
                return;
            }

            if (!response || response.code !== 200 ||
                !response.data ||
                !response.data.url ||
                !response.data.checkoutSessionToken ||
                !response.data.purchaseId) {
                if (cc.isFunction(onFailed)) {
                    onFailed({reason: "checkout session response invalid"});
                }
                return;
            }

            if (cc.isFunction(onSucceed)) {
                onSucceed(
                    response.data.url,
                    response.data.checkoutSessionToken,
                    response.data.purchaseId
                );
            }
        }
    );
},
```

不要把 token 放进请求 body；token 由登录响应提供，session API 由服务端完成 AppCharge 鉴权。

### 5.7 StoreMan：初始化和打开 checkout

在 StoreMan 类中加入初始化方法：

```
InitAppchargeCheckout: function (appchargeCheckoutToken) {
    if (!appchargeCheckoutToken ||
        typeof AppchargeCheckoutInit !== "function") {
        LogMan.getInstance().logAppErrorInfo(
            "AppchargeCheckoutError",
            JSON.stringify({reason: "checkout init unavailable"})
        );
        return;
    }

    try {
        AppchargeCheckoutInit({
            environment: Config.isRelease() ? "prod" : "sandbox",
            checkoutToken: appchargeCheckoutToken
        });
    } catch (e) {
        LogMan.getInstance().logAppErrorInfo(
            "AppchargeCheckoutError",
            JSON.stringify({reason: "checkout init failed"})
        );
        return;
    }

    this.appchargeCheckoutToken = appchargeCheckoutToken;
    this.checkoutPlatformStatus.appcharge = true;
},
```

加入打开 checkout 方法：

```
applyAppchargeCheckout: function (appchargeCheckoutToken, checkoutUrl,
                                   checkoutSessionToken, purchaseId) {
    var hasQuitPurchase = false;
    var quitPurchase = function () {
        if (hasQuitPurchase) {
            return;
        }
        hasQuitPurchase = true;
        game.StoreMan.getInstance()._onPurchaseQuit();
    };

    if (!appchargeCheckoutToken || !checkoutUrl ||
        !checkoutSessionToken || !purchaseId ||
        typeof AppchargeCheckout !== "function") {
        quitPurchase();
        LogMan.getInstance().logAppErrorInfo(
            "AppchargeCheckoutError",
            JSON.stringify({reason: "checkout params invalid"})
        );
        PopupMan.popupCommonDialogWithConf(
            "UI_MESSAGE_APPCHARGE_CHECKOUT_PARAM_ERROR"
        );
        return;
    }

    try {
        AppchargeCheckout({
            checkoutUrl: checkoutUrl,
            sessionToken: checkoutSessionToken,
            purchaseId: purchaseId,
            checkoutToken: appchargeCheckoutToken,
            onClose: quitPurchase,
            onInitialLoad: quitPurchase,
            onOrderCompletedFailed: function (params) {
                LogMan.getInstance().logAppErrorInfo(
                    "AppchargeCheckoutError",
                    JSON.stringify({reason: "order failed"})
                );
            },
            onPaymentIntentFailed: function (params) {
                LogMan.getInstance().logAppErrorInfo(
                    "AppchargeCheckoutError",
                    JSON.stringify({reason: "payment intent failed"})
                );
            }
        });
    } catch (e) {
        quitPurchase();
        LogMan.getInstance().logAppErrorInfo(
            "AppchargeCheckoutError",
            JSON.stringify({reason: "checkout open failed"})
        );
        PopupMan.popupCommonDialogWithConf(
            "UI_MESSAGE_APPCHARGE_CHECKOUT_PARAM_ERROR"
        );
    }
},
```

onOrderCompletedSuccessfully 只用于观测；不能在浏览器回调中直接发货。发货以服务端的 S2CVerifyPurchase/S2CConsumePurchase 为准。

### 5.8 订单完成与错误提示

目标分支的 S2CVerifyPurchase 和 S2CConsumePurchase 已经承载 productFuncType 字段；本次最小接入不新增 PurchaseProductType.APP_CHARGE，不改 PopupMan，不复制 WebStoreResultController。AppCharge 订单完成后继续走目标分支已有的 PurchaseResultController、consume 和活动通知流程，发货以服务端协议为准。

如果服务端明确要求 productFuncType=19 对应独立领奖板，先停止发布并另开 UI 变更，移植 controller、ccb 资源和 manifest 后再接入；不要把另一套 WebStore UI 混入本 SOP。

文件：${FLAVOR}/config/common_tips_list.json

在 common_dialog 中加入以下 Web 错误提示：

```
"UI_MESSAGE_APPCHARGE_CHECKOUT_GET_SESSION_ERROR": {
  "TITLE": "Notice",
  "CONTENT": ["Sorry!", "A server issue occurred", "during checkout."],
  "BTN_YES": "OK"
},
"UI_MESSAGE_APPCHARGE_CHECKOUT_PARAM_ERROR": {
  "TITLE": "Notice",
  "CONTENT": ["Oops!", "We encountered a checkout error."],
  "BTN_YES": "OK"
}
```

Android 外链还须加入 UI_MESSAGE_APPCHARGE_CHECKOUT_URI_ERROR，提示无法打开 checkout 并允许重试。

### 5.9 Android 外链 checkout

以 CV 的完整调用链为准核对：

- 服务端字段 appcharge_android_web 随 ServerConfig.checkoutPlatformStatus 整体透传；CV PlayerMan 已有此字段的读取，不在 ServerConfig 中另补默认字段。
- PlayerMan 的主题条件在 CV/DH 基础上加入 VS，保留 Native 判定、开关读取和设置状态后 return 的顺序。
- StoreMan.buyProduct 在模拟购买之后、_onPurchaseStart 和 Native IAP 之前检查 isForceUseCheckoutOnAndroid，调用 questAppchargeCheckoutOnAndroid 后 return。
- questAppchargeCheckoutOnAndroid 保留 CV 的地址映射、参数拼接、日志、事件和 openURL 顺序。只增加 VS 的 Debug/正式 URI；productFuncType 优先使用入口参数（包括 0），undefined 时回退 ShopProduct.funcType。
- 补齐 CommonEvent.APPCHARGE_CHECKOUT_ON_ANDROID，并在 ActivityBaseController.onEnter 中原样注册：
```
  this.addListener(game.commonEvent.APPCHARGE_CHECKOUT_ON_ANDROID, this.AppChargeCHECKOUTLINK, this);
```

- AppChargeCHECKOUTLINK 由有需要的活动子类实现。SmartCCBController.addListener 会忽略空 handler；基类没有默认回调不代表可以省略监听，也不要擅自给所有活动添加关闭动作。
- URI 映射缺失时沿用 UI_MESSAGE_APPCHARGE_CHECKOUT_URI_ERROR。订单仍由现有 S2CVerifyPurchase/S2CConsumePurchase 校验与发货，不另设前端发货逻辑。
VS 使用用户提供的实际中转地址：

| 环境 | 中转地址 |
| --- | --- |
| Debug | [https://slots-team-test-server-v0.me2zengame.com/appcharge_bridge_vs/](https://slots-team-test-server-v0.me2zengame.com/appcharge_bridge_vs/) |
| 非 Debug | [https://slots-vegasstar-gate.me2zengame.com/appcharge_bridge_vs/](https://slots-vegasstar-gate.me2zengame.com/appcharge_bridge_vs/) |

## 6. 构建与发布

所有命令从仓库根目录进入 scripts 执行。脚本会覆盖根目录 index.html、project.json、main.css、src 的 flavor 覆盖文件以及 Android build.gradle；必须使用目标产品独立工作树。

### 6.1 本地构建与语法检查

```
cd scripts
./build_local_check.sh "${FLAVOR}"
cd ..
```

检查结果：

```
test -s appcharge.js
test -s ${FLAVOR}/flavor/appcharge.js
cmp -s appcharge.js ${FLAVOR}/flavor/appcharge.js
node --check appcharge.js
node --check src/common/entity/ServerConfig.js
node --check src/common/model/PlayerMan.js
node --check src/common/model/SwitchMan.js
node --check src/store/model/StoreMan.js
jq -e '.externalJsList | index("appcharge.js")' ${FLAVOR}/resource_dirs.json
rg -n 'appcharge.js' ${FLAVOR}/flavor/index.html
git diff --check
```

build_local_check.sh 会先执行 build_local_app.sh，后者会执行 LOCAL 配置替换、sync_flavor、gen_res_list 和 browserify。构建后若要继续 RELEASE 流程，必须重新执行 RELEASE 配置替换。

### 6.2 Debug Facebook 构建

```
cd scripts
./js_configs_replace.sh "${FLAVOR}" DEBUG
./sync_flavor.sh "${FLAVOR}"
python gen_res_list.py "${FLAVOR}"
./build_fb.sh "${FLAVOR}"
test -s ../publish/html5/appcharge.js
cd ..
```

确认生成入口使用 debugInfo.packageUrl 和 debugInfo.versionName，不要手改目标 flavor 的 index.html。

### 6.3 Release Facebook 构建

```
cd scripts
./js_configs_replace.sh "${FLAVOR}" RELEASE
./sync_flavor.sh "${FLAVOR}"
python gen_res_list.py "${FLAVOR}"
./build_fb.sh "${FLAVOR}"
test -s ../publish/html5/appcharge.js
cd ..
```

发布版本从资源配置读取：

```
VERSION=$(jq -r '.releaseInfo.versionName' ${FLAVOR}/resource_dirs.json)
FB_ROOT=$(jq -r '.releaseInfo.fbPackageUrl' ${FLAVOR}/resource_dirs.json)
echo "$VERSION"
echo "$FB_ROOT"
```

按仓库既有权限执行上传：

```
cd scripts/deploy_normal
./deploy_fb.sh "${FLAVOR}"
cd ../..
```

deploy_fb.sh 使用 scripts/config/project_config.json 中的目标产品发布配置。没有发布权限时只交付 publish/html5，不要自行修改发布服务器配置。

## 7. 验收

### 7.1 静态验收

- [ ] 目标分支是 ${TARGET_BRANCH}。
- [ ] ${FLAVOR}/flavor/appcharge.js 和 root appcharge.js hash 相同。
- [ ] ${FLAVOR}/resource_dirs.json 的 externalJsList 含 appcharge.js。
- [ ] index.template.html 引用 appcharge.js，生成 index.html 由脚本产生。
- [ ] ServerConfig、PlayerMan、SwitchMan、StoreMan 的新增代码通过 node --check。
- [ ] src 新增代码保持 ES5。
- [ ] git diff --check 通过。
- [ ] 未修改其他产品 flavor、Native bridge、支付中转服务代码或 WebStoreResultController。
### 7.2 Web 功能验收

使用 Debug 或受控 Release 资源，在浏览器 Network 和 Console 验证：

1. 服务端开关 false：登录不创建 handshake iframe，点击购买仍走现有 Facebook payment。
1. 开关 true 且 token/API 有效：登录完成后调用 AppchargeCheckoutInit；不要在日志打印 token。
1. 点击商品：POST body 只有 playerId、productId、productFuncType；响应 code 必须为 200。
1. session 响应的完整 url 被原样赋给 iframe src；checkoutSessionToken 和 purchaseId 被原样传入 SDK。
1. checkout 页面关闭或首次加载后，购买指示器关闭，iframe 可再次打开。
1. 非 200、空 url、空 checkoutSessionToken、空 purchaseId、非法 JSON：指示器关闭，显示 GET_SESSION_ERROR 或 PARAM_ERROR。
1. 来自非 checkout URL origin 的 message 不触发订单回调；关闭 checkout 后旧 listener 不再触发。
1. AppCharge 支付成功后，等待服务端 S2CVerifyPurchase/S2CConsumePurchase；确认金币、VIP、活动和目标产品原有领奖流程与普通购买一致。
1. 首次 Native 登录未开启外链时仍走原 IAP；服务端开启外链时打开对应中转页，不创建 iframe、不重复调用原生 IAP。平台策略沿用 CV 的服务端控制。
### 7.3 Android 外链验收

- [ ] 按 CV 登录条件开启 Native 外链，Web 不受该开关影响；首次登录开关关闭或缺失时保持 IAP。
- [ ] VS Debug/正式 URI 与用户提供的实际地址一致；CV/DH 原有映射保留。
- [ ] 入口 productFuncType（包括 0）和 undefined 回退正确；不重复调用 IAP 或 Web session。
- [ ] ActivityBaseController 注册原有事件；子类回调被触发，退出后清理，重新进入不重复注册；没有回调的活动保持正常。
- [ ] URI 映射缺失时显示原有错误提示，不打开浏览器。
- [ ] 在 Android 真机核对后台切换、支付返回、服务端发货及领奖；本地模拟不能代替真实支付验收。
### 7.4 CDN 验收

Release 上传后，按 resource_dirs.json 计算实际 URL：

```
VERSION=$(jq -r '.releaseInfo.versionName' ${FLAVOR}/resource_dirs.json)
CDN_ROOT=$(jq -r '.releaseInfo.fbPackageUrl' ${FLAVOR}/resource_dirs.json)
curl -fsSL "$CDN_ROOT/$VERSION/appcharge.js" -o /tmp/appcharge.js
shasum -a 256 /tmp/appcharge.js ${FLAVOR}/flavor/appcharge.js
```

两者 hash 必须相同。再打开该版本 index.html，确认 script URL 与同一版本目录一致。不要用覆盖旧版本文件的方式规避 CDN 缓存。

## 8. 故障定位

| 现象 | 检查顺序 |
| --- | --- |
| AppchargeCheckoutInit is not defined | index.html 的 script URL → CDN appcharge.js → externalJsList → publish/html5/appcharge.js |
| 登录后没有 handshake | serverConfig 开关、token、SwitchMan 主题/Native 判断、SDK 是否在页面先加载 |
| session 请求未发出 | buyProduct 分支顺序、checkoutPlatformStatus.appcharge、本地模拟购买条件 |
| session 请求失败 | checkoutServerApi、CORS、POST 三字段、HTTP 状态、JSON code |
| checkout 白屏 | response.data.url 是否为完整 HTTPS URL；是否被客户端改写；CDN SDK hash 是否正确 |
| checkout 打开后卡住 | onInitialLoad/onClose 是否调用 _onPurchaseQuit；是否重复调用 _onPurchaseStart |
| 支付成功但未发货 | 只查服务端订单和 S2CVerify/S2CConsume；不要把前端成功回调当作发货凭据 |
| message 没回调 | 比较 message.origin 与 new URL(checkoutUrl).origin；不要临时放宽 origin |
| 发布后仍是旧 SDK | index.html 版本路径、远端 appcharge.js hash、CDN 缓存和实际发布目录 |

## 9. 回滚

未提交时，先查看本次脚本实际改动，再只恢复本 SOP 涉及的目标文件和生成文件；不要执行全仓库 reset：

```
git status --short
git restore \
  index.html \
  project.json \
  main.css \
  src/common/util/Config.js \
  scripts/sync_flavor.sh \
  ${FLAVOR}/flavor/index.html \
  ${FLAVOR}/flavor/project.json \
  ${FLAVOR}/flavor/js_src/common/util/Config.js \
  ${FLAVOR}/flavor/index.template.html \
  ${FLAVOR}/resource_dirs.json \
  ${FLAVOR}/config/common_tips_list.json \
  src/common/entity/ServerConfig.js \
  src/common/model/PlayerMan.js \
  src/common/model/SwitchMan.js \
  src/store/model/StoreMan.js
git diff --name-only -- "${FLAVOR}" | sort
# 将上条命令列出的本次生成 resource_list、manifest 等文件逐个 git restore
rm -f appcharge.js ${FLAVOR}/flavor/appcharge.js
```

如果已提交，使用只包含本实例接入的提交执行 git revert。线上先将 checkoutPlatformStatus.appcharge 置为 false，再切回上一份已验证的目标产品资源版本；不要删除服务端字段，也不要覆盖仍被旧 index.html 引用的版本目录。

## 10. 交付清单

源码与核心配置交付清单：

- root appcharge.js；
- ${FLAVOR}/flavor/appcharge.js；
- ${FLAVOR}/flavor/index.template.html；
- ${FLAVOR}/resource_dirs.json（externalJsList 包含 appcharge.js）；
- ${FLAVOR}/config/common_tips_list.json；
- scripts/sync_flavor.sh；
- src/common/entity/ServerConfig.js；
- src/common/events/CommonEvent.js（Android 外链事件）；
- src/task/controller/ActivityBaseController.js（活动事件监听）；
- src/common/model/PlayerMan.js；
- src/common/model/SwitchMan.js；
- src/store/model/StoreMan.js；
提交前检查 ${FLAVOR}/resource_dirs.json 的差异，确保 externalJsList 增补已纳入提交；仅清理构建验证临时引入且不属于本次任务的 isRelease、版本值变化，保留本次明确要求的发布配置变更。

构建验收使用脚本生成的 ${FLAVOR}/flavor/index.html、flavor Config.js、project.json 与 resource_list；按项目规则，不把这些生成文件纳入源码提交。验收后逐项恢复临时构建修改；保留源码模板与必要发布配置。

交付前再次执行第 6.1 节检查，并记录：

```
targetBranch=$TARGET_BRANCH
flavor=$FLAVOR
releaseVersion=<${FLAVOR}/resource_dirs.json 中的 releaseInfo.versionName>
sdkSourceRef=${SDK_REF}
sdkSha256=<${FLAVOR}/flavor/appcharge.js hash>
sessionApi=<服务端接口标识，不写 token>
releaseUrl=<实际 Facebook 版本 URL>
```
