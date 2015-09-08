//
//	ReaderConstants.h
//	Reader v2.8.1
//
//	Created by Julius Oklamcak on 2011-07-01.
//	Copyright © 2011-2014 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#if !__has_feature(objc_arc)
	//#error ARC (-fobjc-arc) is required to build this code.
#endif

#if __has_feature(objc_arc)

#define PDF_AUTORELEASE(expression) expression

#define PDF_RELEASE(expression)

#define PDF_RETAIN(expression)  expression

#define PDF_SUPER_DEALLOC

#else

#define PDF_AUTORELEASE(expression) [expression autorelease]

#define PDF_RELEASE(expression) [expression release]

#define PDF_RETAIN(expression) [expression retain]

#define PDF_SUPER_DEALLOC      [super dealloc]

#endif


#import <Foundation/Foundation.h>

#define READER_FLAT_UI TRUE
#define READER_SHOW_SHADOWS TRUE
#define READER_ENABLE_THUMBS TRUE
#define READER_DISABLE_RETINA FALSE
#define READER_ENABLE_PREVIEW TRUE
#define READER_DISABLE_IDLE FALSE
#define READER_STANDALONE FALSE                     ///< 是否standalone
#define READER_BOOKMARKS TRUE                       ///< 是否支持书签
#define READER_PAGE_MODE FALSE                      ///< 是否支持翻页模式选择
#define READER_ENABLE_SEARCH TRUE                   ///< 是否支持搜索
#define READER_ENABLE_PAGE_BAR TRUE                 ///< 是否显示页码缩略图
