//
//  BHCentralManager.h
//  BHBluetooth
//
//  Created by 学宝 on 2019/2/22.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN


/**
 中心设备的蓝牙状态

 - BHCentralManagerStateUnknown: 未知，一般应用刚启动时，获取的状态 (CBManagerStateUnknown)
 - BHCentralManagerStateUnsupported: 设备不支持蓝牙 (CBManagerStateResetting | CBManagerStateUnsupported | CBManagerStateUnauthorized)
 - BHCentralManagerStatePoweredOff: 蓝牙已关闭（CBManagerStatePoweredOff）
 - BHCentralManagerStatePoweredOn: 蓝牙已打开（CBManagerStatePoweredOn）
 */
typedef NS_ENUM(NSInteger, BHCentralManagerState) {
    BHCentralManagerStateUnknown,
    BHCentralManagerStateUnsupported,
    BHCentralManagerStatePoweredOff,
    BHCentralManagerStatePoweredOn,
};

@protocol BHCentralManagerDelegate;
@interface BHCentralManager : NSObject

+ (instancetype)shareInstance;

@property (nonatomic, weak) id<BHCentralManagerDelegate> delegate;

@property (nonatomic, assign, readonly) BOOL isScanning;

/**
 已发现的外围设备（此数据中的成旧数据会存在未及时更新，可调用- (void)resetDiscoveredPeripherals 进行重置）
 */
@property (nonatomic, strong, readonly) NSArray <CBPeripheral *>*discoveredPeripherals;

@property (nonatomic, assign, readonly) BHCentralManagerState state;


/**
 是否忽略没有名称的外围设备(peripheral.name == nil)，默认为NO
 */
@property (nonatomic, assign) BOOL ignorePeripheralIfUnnamed;

- (void)startScan;

- (void)startScanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options;

- (void)stopScan;



/**
 连接外围设备

 @param peripheral 外围设备
 @param options 参考连接方法的配置说明
 @param typeIdentifier 为外围设备定义类型
 */
- (void)connectPeripheral:(CBPeripheral *)peripheral options:(nullable NSDictionary<NSString *, id> *)options typeIdentifier:(NSString *)typeIdentifier;

- (void)connectPeripheral:(CBPeripheral *)peripheral options:(nullable NSDictionary<NSString *, id> *)options typeIdentifier:(NSString *)typeIdentifier timeout:(NSTimeInterval)timeout;

- (CBPeripheral *)connectedPeripheralForTypeIdentifier:(NSString *)typeIdentifier;

- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral;


/**
 重置已发现的外围设备数据
 */
- (void)resetDiscoveredPeripherals;
@end

@protocol BHCentralManagerDelegate <NSObject>


/// 蓝牙管理器检测中心设备蓝牙状态变化的回调
/// @param centralManager 蓝牙管理器
/// @param state 中心设备蓝牙状态
- (void)centralManager:(BHCentralManager *)centralManager didUpdateState:(BHCentralManagerState)state;


/// 蓝牙管理器检索到外围设备的回调
/// @param centralManager 蓝牙管理器
/// @param peripheral 外围设备
/// @param advertisementData 外围设备广播的信息
/// @param RSSI 外围设备的信号强度
- (void)centralManager:(BHCentralManager *)centralManager didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI;

/// 蓝牙管理器检测到已连接到外围设备的回调
/// @param centralManager 蓝牙管理器
/// @param peripheral 外围设备
- (void)centralManager:(BHCentralManager *)centralManager didConnectPeripheral:(CBPeripheral *)peripheral;

/// 蓝牙管理器检测到连接外围设备失败的回调
/// @param centralManager 蓝牙管理器
/// @param peripheral 外围设备
/// @param error 错误信息
- (void)centralManager:(BHCentralManager *)centralManager didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

/// 蓝牙管理器检测到失去了外围设备连接的回调
/// @param centralManager 蓝牙管理器
/// @param peripheral 外围设备
/// @param error 错误信息
- (void)centralManager:(BHCentralManager *)centralManager didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error;


@end


FOUNDATION_EXPORT NSString * const BHCentralManagerStateDidChangeNotification;
FOUNDATION_EXPORT NSString * const BHCentralManagerStateNotificationStateKey;

FOUNDATION_EXPORT NSString * const BHCentralManagerPeripheralConnectDidChangeNotification;
FOUNDATION_EXPORT NSString * const BHCentralManagerPeripheralConnectNotificationPeripheralKey;
FOUNDATION_EXPORT NSString * const BHCentralManagerPeripheralConnectNotificationPeripheralTypeIdentifierKey;

NS_ASSUME_NONNULL_END
