## PDFKernelDemo
展示pdf内核封装成framework

## testKernel
封装framework的工程，包含3个target：
 
1. testKernel：参考[iOS开发——创建你自己的Framework](http://www.cocoachina.com/ios/20150127/11022.html) ，尝试到利用脚本打包；
2. PDFKernel：参考[Xcode 6制作动态及静态Framework](http://www.cocoachina.com/ios/20141126/10322.html)，制作framework；
3. PDFKernelResource：参考[iOS开发——创建你自己的Framework](http://www.cocoachina.com/ios/20150127/11022.html) ，打包图片资源。

## 注意
1. 引用框架时必须import框架的伞头文件<PDFKernel/PDFKernel.h>
2. 伞头文件引用的头文件必须属于某个框架，也就是说必须是`import<>`形式，并且所有间接引用的头文件也要遵守这条规则。