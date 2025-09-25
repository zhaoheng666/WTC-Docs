### 初始Link图标排布

### editable\_config\_xxx.json

**"initializeSymbolSequence"**: \[  
 \[  
   \[  
     1005,  
     1201,  
     1005  
   \],  
   \[  
     1004,  
     1,  
     1004  
   \],  
   \[  
     1006,  
     1202,  
     1006  
   \],  
   \[  
     1004,  
     1,  
     1004  
   \],  
   \[  
     1005,  
     1203,  
     1005  
   \]  
 \],  
 \[  
   \[  
     1011,  
     1011,  
     1011  
   \],  
   \[  
     1011,  
     1011,  
     1011  
   \],  
   \[  
     1011,  
     1011,  
     1011  
   \],  
   \[  
     1011,  
     1011,  
     1011  
   \],  
   \[  
     1011,  
     1011,  
     1011  
   \]  
 \],  
 \[  
   \[  
     1011,  
     1011,  
     1011  
   \],  
   \[  
     1011,  
     1011,  
     1011  
   \],  
   \[  
     1011,  
     1011,  
     1011  
   \],  
   \[  
     1011,  
     1011,  
     1011  
   \],  
   \[  
     1011,  
     1011,  
     1011  
   \],  
   \[  
     1011,  
     1011,  
     1011  
   \],  
   \[  
     1011,  
     1011,  
     1011  
   \],  
   \[  
     1011,  
     1011,  
     1011  
   \],  
   \[  
     1011,  
     1011,  
     1011  
   \],  
   \[  
     1011,  
     1011,  
     1011  
   \]  
 \]  
\]

### 按策划需求显示 link 图标上的信息

在 getSpinExtraData 中写逻辑组装数据，用 isNotSpinedAfterEnterRoom 区分是否是首屏图标  
getSpinExtraData: **function** (panelId, col, row, symbolId) {  
   **var** randomList \= LinkMultipleRandomList;  
   **game**.**util**.shuffle2(randomList);  
   **var** multi \= randomList\[0\];

   **if** (**this**.isNotSpinedAfterEnterRoom()) {  
       **if** (symbolId && \[1201, 1202, 1203\].indexOf(symbolId) \> \-1) {  
           **var** jpList \= {  
               1201: multi,  
               1202: \[1001, 1002, 1003\]\[**game**.**util**.randomNextInt(3)\],  
               1203: multi  
           };  
           multi \= jpList\[symbolId\];  
       }  
   }

   **return** {  
       **"index"**: \-1,  
       **"pos"**: {  
           **"col"**: col,  
           **"row"**: row  
       },  
       **"posIndex"**: col \* 3 \+ (3 \- 1 \- row),  
       **"multi"**: multi  
   };  
},