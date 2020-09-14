# 蓝牙管理器-iOS

[![CI Status](https://img.shields.io/travis/学宝/BHBluetooth.svg?style=flat)](https://travis-ci.org/学宝/BHBluetooth)
[![Version](https://img.shields.io/cocoapods/v/BHBluetooth.svg?style=flat)](https://cocoapods.org/pods/BHBluetooth)
[![License](https://img.shields.io/cocoapods/l/BHBluetooth.svg?style=flat)](https://cocoapods.org/pods/BHBluetooth)
[![Platform](https://img.shields.io/cocoapods/p/BHBluetooth.svg?style=flat)](https://cocoapods.org/pods/BHBluetooth)

## 简介

1. 蓝牙中心设备检索外围蓝牙设备
2. 连接外围设备

## 特点
1. 检索到的外围设备列表，支持过滤外围蓝牙名称为空的设备
2. 支持连接不同类型的外围蓝牙设备
2. 通过自定义的类型标签，获取已连接的外围设备
3. 支持Delegate和Notification

## 使用

```ruby
pod 'BHBluetooth'
```

##### 设置监听

```
[BHCentralManager shareInstance].delegate = self; //设置回调
//[BHCentralManager shareInstance].ignorePeripheralIfUnnamed = YES; //配置是否忽略外围设备名称为空的设备
```

##### 发现外围设备(蓝牙已打开)

```
- (void)centralManager:(BHCentralManager *)centralManager didUpdateState:(BHCentralManagerState)state {
    if (state == BHCentralManagerStatePoweredOn) {
        [[BHCentralManager shareInstance] startScan];//开始扫描
    }
}
```
##### 连接

```
- (void)centralManager:(BHCentralManager *)centralManager didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    if (你确定外围设备keyboardtype的逻辑) {
    [[BHCentralManager shareInstance] connectPeripheral:peripheral options:nil typeIdentifier:@"keyboardtype"];
    }
}
```
注：连接逻辑根据自己的业务定。


## 作者
学宝  zhanxuebao@outlook.com


**写出你能看懂的代码，而不只是机器能读懂的代码。**


