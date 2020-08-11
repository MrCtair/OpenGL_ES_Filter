//
//  ViewController.m
//  OpenGL_ES_Filter
//
//  Created by trs on 2020/8/11.
//  Copyright © 2020 Ctair. All rights reserved.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>
#import "FilterViewController.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) NSArray * dataSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareForData];
    [self prepareForView];
    [self prepareForAction];
}

- (void)prepareForData{
    _dataSource = @[@"分屏滤镜", @"灰度/马赛克滤镜"];
}
- (void)prepareForView{
    [self.view addSubview:self.tableView];
    self.navigationItem.title = @"OpenGL_ES_Filter";
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.top.equalTo(self.view);
    }];
}

/// Description
- (void)prepareForAction{
    
}

#pragma mark -- UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _dataSource.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"UITableViewCell"];
    }
    cell.textLabel.text = _dataSource[indexPath.row];
    
    return cell;
}
#pragma mark -- UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    FilterViewController * filterVC = [[FilterViewController alloc] init];
    filterVC.fiterType = indexPath.row;
    [self.navigationController pushViewController:filterVC animated:YES];
}

#pragma mark --lazy init
- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}


@end
