# 图标drum动画组件 SymbolDrumAction

所有配置已在生成关卡脚本中添加默认属性。  
![image1](/assets/9e72327f0a61845d41f9e093fe1ea6b2.png)

## 组件开关

this.machineConfig.supportSymbolDrumMode \= false; // 默认关闭

## 相关配置指南

1、drumSymbolGroupList \= \[ \[1, 1101, 1102\], \[2\], …\];  
      二维数组，多组配置同时生效，每组之间配置互不干扰drum表现。

2、drumOnWinLineList \= \[true, false, …\];  
      drum表现时，是否需要有效图标组合在一条赢钱线上。

3、drumNeedSymbolCountList \= \[null, 2, …\];  
      仅对不需要在赢钱线上，只以落定数量为判断条件的drum需求生效。  
      例如sc图标或bonus图标。  
      即当drumOnWinLineList相应位置为false时需要设置数量。

4、needSameSymbolList \= \[false, true, …\];  
      是否必须是同一symbolId。  
      false：只要图标是配置的symbolIdList中的有效图标，即可进行随意id组合drum。  
      true：必须是symbolIdList中的有效图标，且组合drum的图标id必须一致。

## 使用场景

假定：  
特殊wild 100X图标id：1104  
Bonus图标id：1000  
Sc图标id：2  
Wild图标id：1、1101、1102、1103……  
常规图标id：1001、1002、1003、1004、1005、1006……

场景一：  
	需求：  
drum1：任意wild连线即可drum。  
drum2：sc图标落定2两个即可drum。

使用配置：  
this.machineConfig.drumSymbolGroupList \= \[\[1, 1101, 1102\], \[2\]\];  
this.machineConfig.drumOnWinLineList \= \[true, false\];  
this.machineConfig.drumNeedSymbolCountList \= \[null, 2\];  
this.machineConfig.needSameSymbolList \= \[false, true\];

场景二：  
	场景一的变式，请结合场景一需求进行理解。  
		需求的唯一区别：drum1：共有三种wild图标，只有相同的wild图标连线才能drum  
	  
	使用配置  
this.machineConfig.drumSymbolGroupList \= \[\[1, 1101, 1102\], \[2\]\];  
this.machineConfig.drumOnWinLineList \= \[true, false\];  
this.machineConfig.drumNeedSymbolCountList \= \[null, 2\];  
this.machineConfig.needSameSymbolList \= \[true, true\]; // 仅此处变更即可

场景三：  
	需求：  
		drum1：任意图标与100X图标连线。  
		drum2：sc图标落定两个。  
		drum3：bonus图标落定两个。  
	  
	使用配置：  
		由于100X与任意常规图标的需求特殊性，只能根据常规图标的数量，相应添加多组配置。  
this.machineConfig.drumSymbolGroupList \= \[  
\[1104, 1001\],  
\[1104, 1002\],  
\[1104, 1003\],  
\[1104, 1004\],  
\[1104, 1005\],  
\[1104, 1006\],  
\[2, 1000\] // 一个配置即可解决sc和bonus的相同数量drum需求  
\];  
this.machineConfig.drumOnWinLineList \= \[true, true, true, true, true, true, false\];  
this.machineConfig.drumNeedSymbolCountList \= \[null, null, null, null, null, null, 2\];  
this.machineConfig.needSameSymbolList \= \[false, false, false, false, false, false, true\]; // 最后一项必须配置为true，才能保证sc、bonus的数量判断互不干扰，否则会用两种图标的总数量做判断，导致落定一个bonus \+ 一个sc时也会drum

