# Q3`25-Slots-UI 适配规则梳理-程序

### 一、当前项目使用到的分辨率：

|当前使用中|分辨率|宽高比|宽高比|
| -----------------------------| -------------| --------| -----------|
|CV Canvas|1136 * 640|16:9|1.775|
|DH Canvas|960 * 720|4:3|1.333 ~|
|美术效果图|1680 * 1020|？|1.647～|
|美术效果图-PAD|1360 * 1020|？|1.333～|
|CCB 辅助适配图|1386 * 768|？|1.8046875|
|CCB 辅助适配图-有效区域<br />|1136 * 640|16:9|1.775|
|CCB 辅助适配图-有效区域-pad|1024*768|4:3|1.333 ~|

‍

### 二、**主流设备分辨率参考（横屏游戏）：**

|**设备类型**|**常见分辨率**|**宽高比**|宽高比|**设计分辨率建议**|
| -------------------------| ------------| ------| ---------| --------------|
|主流手机（Android/iOS）|1920×1080|16:9|1.778~|优先选择|
|平板（iPad）|2048×1536|4:3|1.333 ~|扩展安全区域|
|超宽屏手机|2560×1080|21:9|2.333~|增加侧边填充|

‍

### 三、**主流旗舰手机分辨率：**

|**品牌**|**机型**|**分辨率**|宽高比|**屏幕尺寸**|
| -----------------| ----------------------------------| --------------------------------| ------------------------| -------------------------|
|**三星**|Galaxy S25 Ultra|3120×1440 (2K)|2.166～|6.8英寸|
||Galaxy S24 Ultra|3120×1440 (2K)|2.166～|6.8英寸|
|**苹果**|iPhone 16 Pro Max|2796×1290|2.167～|6.9英寸|
||iPhone 15 Pro Max|2796×1290|2.167～|6.69英寸|
|**小米**|小米15 Ultra|3200×1440 (2K)|2.222~|6.73英寸|
||小米15 Pro|2670×1200|2.225|6.36英寸|
|**华为**|Mate 70 Pro+|2832×1316|2.151～|6.9英寸|
||Pura 70 Pro+|2844*1260|2.257～|6.8英寸|
|**OPPO**|Find X8 Ultra|2760×1256|2.197～|6.59英寸|
||Find X7 Ultra|3168×1440 (2K)|2.2|6.82英寸|
|**vivo**|X200 Ultra|3168×1440 (2K)|2.2|6.82英寸|
|**荣耀**|Magic 7 Pro|2800×1280|2.185|6.81英寸|
||GT Pro|2800×1264|2.215～|6.78英寸|
|**一加**|一加13|3216×1440 (2K)|2.233～|6.82英寸|

‍

### 四、目前存在的问题：

##### 1、android 非全屏显示，观感差、不符合当代游戏标准；

##### 2、设计分辨率-效果图分辨率使用标准混乱；

##### 3、部分 UI 界面存在背景图黑边、缩放比例不符合设计效果等现象；

##### 4、UI 布局缺少挂靠、贴边、自适应等支持；部分程序代码定义的元素适配死板；

‍

### 五、android 全面屏实现：

#### 1、配置：

```xml
<style name="AppTheme" parent="@android:style/Theme.NoTitleBar.Fullscreen">
</style>
```

#### 2、布局：

用动态创建的FrameLayout而非XML布局文件

```xml
// 动态布局 - MATCH_PARENT
iewGroup.LayoutParams framelayout_params =
new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,ViewGroup.LayoutParams.MATCH_PARENT);
mFrameLayout = new ResizeLayout(this);
mFrameLayout.setLayoutParams(framelayout_params);
```

#### 3、代码设置：

`cocos/platform/android/java/src/org/cocos2dx/lib/Cocos2dxActivity.java`​

```java
public void init() {
    // FrameLayout
    ViewGroup.LayoutParams framelayout_params =
        new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                                   ViewGroup.LayoutParams.MATCH_PARENT);

    mFrameLayout = new ResizeLayout(this);

    mFrameLayout.setLayoutParams(framelayout_params);

    // Cocos2dxEditText layout
    ViewGroup.LayoutParams edittext_layout_params =
        new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                                   ViewGroup.LayoutParams.WRAP_CONTENT);
    Cocos2dxEditBox edittext = new Cocos2dxEditBox(this);
    edittext.setLayoutParams(edittext_layout_params);


    mFrameLayout.addView(edittext);

    // Cocos2dxGLSurfaceView
    this.mGLSurfaceView = this.onCreateView();

    // ...add to FrameLayout
    mFrameLayout.addView(this.mGLSurfaceView);

    // Switch to supported OpenGL (ARGB888) mode on emulator
    if (isAndroidEmulator())
       this.mGLSurfaceView.setEGLConfigChooser(8, 8, 8, 8, 16, 0);

    this.mGLSurfaceView.setCocos2dxRenderer(new Cocos2dxRenderer());
    this.mGLSurfaceView.setCocos2dxEditText(edittext);

    // Set framelayout as the content view
    setContentView(mFrameLayout);

    //region 全面屏显示优化 ====================================
    // 原来被注释的配置代码导致：
    // 1. 未启用LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
    // 2. 未设置沉浸式全屏标志
    // 3. 未调整窗口装饰视图的可见区域

    // 解决方案：取消注释并修改为
    WindowManager.LayoutParams lp = getWindow().getAttributes();
    try {
        // 允许内容延伸到刘海区域
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                Field field = WindowManager.LayoutParams.class.getDeclaredField("layoutInDisplayCutoutMode");
                int cutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
                field.setInt(lp, cutoutMode);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        // 组合沉浸式全屏标志
        int flag = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 12+ 推荐方案
            getWindow().getInsetsController().hide(WindowInsets.Type.systemBars());
        } else {
            getWindow().getDecorView().setSystemUiVisibility(flag);
        }

        // 更新窗口参数
        getWindow().setAttributes(lp);
    } catch (Exception e) {
        e.printStackTrace();
    }
    //endregion 全面屏显示优化 ====================================
}
```

#### 4、效果对比：

##### 全屏后

![image](http://localhost:5173/WTC-Docs/assets/1758174599815_e66ac64f.png)

##### 全屏前

![image](http://localhost:5173/WTC-Docs/assets/1758174599829_449bb5b3.png)

### 六、全屏后需要做的适配调整：

1. splash 视图全屏适配；
2. loading 页全屏适配；
3. 大厅背景图等比缩放；
4. 大厅 top-title、bottom-bar 背景九宫格横向拉伸；
5. 调整大厅 top-title、bottom-bar 元素排布，需要拆分、调整现有节点树；
6. theme 相关 top-title、bottom-bar 适配；
7. 大厅侧边栏、翻页按钮位置调整；
8. 关卡背景拉伸适配；
9. 关卡 spinUI 背景拉伸适配；

### 七、设计图-效果图规格统一：

1. 设计分辨率：

    - CV：**1136 * 640** （16:9）
    - DH：**960 * 720** （4:3）
    - PAD：**960 * 720**（4:3）
2. CCB 辅助适配图尺寸：

    - CV：**1386 * 640**  
      目前能适配的极限是 iphone16 promax（2796×1290）  
      1290 / 640 * 1386 ~= 2794  
      如后续苹果设备继续提高宽高比，该辅助尺寸将不再适用（宽度不够）；

      支持超宽屏（21:9）适配: （**1494 * 640**）  
      width = 21 / 9 * 640 ~= 1494;
    - DH：**1024*768**
    - PAD：**1024*768**
3. CCB 辅助适配图-有效区域：（不同设备经适配后，保持等比、完全显示的区域）等同于设计分辨率

    - CV：**1136 * 640**

    - DH：**960* 720**
    - PAD：**960* 720**
4. 效果图：

    - CV：**1386 * 768**
    - DH、PAD 单独适配（出单独的 CCB）：**1024 * 768**
    - DH、PAD 移植效果图：**1024 * 768**

      在 CV 的基础上等比放大 min(768 / 640 = 1.2,1136 / 1024 = 1.109375) = **1.109375** 后，切成 （1024 * 768）

‍

‍

‍
