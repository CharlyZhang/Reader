//
//  ViewController.m
//  PDFKernelDemo
//
//  Created by CharlyZhang on 15/9/6.
//  Copyright (c) 2015年 Founder. All rights reserved.
//

#import "ViewController.h"
#import <PDFKernel/PDFKernel.h>
#import <PDFKernel/PDFViewController.h>

@interface ViewController ()
{
    PDFViewController *pdfCtrl;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSArray *pdfs = [[NSBundle mainBundle] pathsForResourcesOfType:@"pdf" inDirectory:nil];
    
    NSString *filePath = [pdfs firstObject];
    
    pdfCtrl = [[PDFViewController alloc]initWithPath:filePath with:nil];
    
    [self addChildViewController:pdfCtrl];
    [self.view addSubview:pdfCtrl.view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
