//
//  BHCentralManager.m
//  BHBluetooth
//
//  Created by 学宝 on 2019/2/22.
//

#import "BHCentralManager.h"

NSString * const BHCentralManagerStateDidChangeNotification = @"com.xuebao.centralmanager.state.change";
NSString * const BHCentralManagerStateNotificationStateKey = @"BHCentralManagerNotification_StateKey";

NSString * const BHCentralManagerPeripheralConnectDidChangeNotification = @"com.xuebao.centralmanager.peripheralconnect.change";
NSString * const BHCentralManagerPeripheralConnectNotificationPeripheralKey = @"BHCentralManagerNotification_PeripheralKey";
NSString * const BHCentralManagerPeripheralConnectNotificationPeripheralTypeIdentifierKey = @"BHCentralManagerNotification_PeripheralTypeIdentifierKey";


@interface CBPeripheral (BHExtend)

@property (nonatomic, strong) NSString *typeIdentifier;

@end

@interface BHCentralManager ()<CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;

@property (nonatomic, strong) NSMutableArray *discoveredPeripheralArray;

@property (nonatomic, strong) NSMutableDictionary *connectPeripheralDict;

@property (nonatomic, assign, readwrite) BHCentralManagerState state;

@end

@implementation BHCentralManager

+ (instancetype)shareInstance {
    static BHCentralManager *centralManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        centralManager = [[self alloc] init];
    });
    return centralManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _discoveredPeripheralArray = [[NSMutableArray alloc] init];
        _connectPeripheralDict = [[NSMutableDictionary alloc] init];
        _ignorePeripheralIfUnnamed = NO;
    }
    return self;
}

- (void)startScan {
    [self startScanForPeripheralsWithServices:nil options:nil];
}

- (void)startScanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options {
    if (!self.isScanning) {
        [self.discoveredPeripheralArray removeAllObjects];
        if (self.state != BHCentralManagerStatePoweredOn) {
            return;
        }
        [self.centralManager scanForPeripheralsWithServices:serviceUUIDs options:options];
    }else {
        NSLog(@"BHBluetooth：重复调用扫描(scan)，正在扫描中...\n");
    }
}

- (void)stopScan {
    if (self.isScanning) {
        [self.centralManager stopScan];
    }
}



- (void)connectPeripheral:(CBPeripheral *)peripheral options:(nullable NSDictionary<NSString *, id> *)options typeIdentifier:(NSString *)typeIdentifier {
    if (peripheral == nil) {
        return;
    }
    if (typeIdentifier == nil) {
        NSLog(@"BHBluetooth：请为要连接的设备添加类型标示\n");
        return;
    }
    peripheral.typeIdentifier = typeIdentifier;
    [self.centralManager connectPeripheral:peripheral options:options];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral options:(NSDictionary<NSString *,id> *)options typeIdentifier:(NSString *)typeIdentifier timeout:(NSTimeInterval)timeout {
    [self connectPeripheral:peripheral options:options typeIdentifier:typeIdentifier];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (peripheral.state == CBPeripheralStateConnecting) {
            [self.centralManager cancelPeripheralConnection:peripheral];
        }
    });
}

- (CBPeripheral *)connectedPeripheralForTypeIdentifier:(NSString *)typeIdentifier {
    CBPeripheral *peripheral = [self.connectPeripheralDict objectForKey:typeIdentifier];
    return peripheral.state == CBPeripheralStateConnected ? peripheral : nil;
}

- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral {
    [self.centralManager cancelPeripheralConnection:peripheral];
}

- (void)resetDiscoveredPeripherals {
    [self.discoveredPeripheralArray removeAllObjects];
}

#pragma mark-
#pragma mark-Getter

- (BOOL)isScanning {
    return self.centralManager.isScanning;
}

- (NSArray <CBPeripheral *>*)discoveredPeripherals {
    return self.discoveredPeripheralArray;
}

- (CBCentralManager *)centralManager {
    if (_centralManager == nil) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_queue_create("com.xuebao.bh.centralmanager.queue", NULL) options:@{CBCentralManagerOptionShowPowerAlertKey : @(YES)}];
    }
    return _centralManager;
}

- (BHCentralManagerState)state {
    if (@available(iOS 10.0, *)) {
        switch (self.centralManager.state) {
            case CBManagerStateUnknown:
                return BHCentralManagerStateUnknown;
                break;
            case CBManagerStatePoweredOn:
                return BHCentralManagerStatePoweredOn;
                break;
            case CBManagerStatePoweredOff:
                return BHCentralManagerStatePoweredOff;
                break;
            default:
                return BHCentralManagerStateUnsupported;
                break;
        }
    }else {
        switch (self.centralManager.state) {
            case CBCentralManagerStateUnknown:
                return BHCentralManagerStateUnknown;
                break;
            case CBCentralManagerStatePoweredOn:
                return BHCentralManagerStatePoweredOn;
                break;
            case CBCentralManagerStatePoweredOff:
                return BHCentralManagerStatePoweredOff;
                break;
            default:
                return BHCentralManagerStateUnsupported;
                break;
        }
    }
}
#pragma mark-
#pragma mark- CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    BHCentralManagerState state = [self state];
    if (state != BHCentralManagerStatePoweredOn) {
        [self.discoveredPeripheralArray removeAllObjects];
    }
    NSDictionary *userInfo = @{BHCentralManagerStateNotificationStateKey: @(state)};
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:BHCentralManagerStateDidChangeNotification object:nil userInfo:userInfo];
        if ([self.delegate respondsToSelector:@selector(centralManager:didUpdateState:)]) {
            [self.delegate centralManager:self didUpdateState:state];
        }
    });

}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(nonnull CBPeripheral *)peripheral advertisementData:(nonnull NSDictionary<NSString *,id> *)advertisementData RSSI:(nonnull NSNumber *)RSSI {
    if (peripheral.name == nil && self.ignorePeripheralIfUnnamed) {
        
    }else {
        [self updateDiscoverPeripheralArrayWithNewPeripheral:peripheral];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:)]) {
                [self.delegate centralManager:self didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
            }
        });
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self.connectPeripheralDict setValue:peripheral forKey:peripheral.typeIdentifier];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:BHCentralManagerPeripheralConnectDidChangeNotification object:nil userInfo:[self notificationUserInfoWithPeripheral:peripheral]];
        if ([self.delegate respondsToSelector:@selector(centralManager:didConnectPeripheral:)]) {
            [self.delegate centralManager:self didConnectPeripheral:peripheral];
        }
    });
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(centralManager:didFailToConnectPeripheral:error:)]) {
            [self.delegate centralManager:self didFailToConnectPeripheral:peripheral error:error];
        }
    });
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self.connectPeripheralDict removeObjectForKey:peripheral.typeIdentifier];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:BHCentralManagerPeripheralConnectDidChangeNotification object:nil userInfo:[self notificationUserInfoWithPeripheral:peripheral]];
        if ([self.delegate respondsToSelector:@selector(centralManager:didDisconnectPeripheral:error:)]) {
            [self.delegate centralManager:self didDisconnectPeripheral:peripheral error:error];
        }
    });
}

#pragma mark-
#pragma mark-Private

- (void)updateDiscoverPeripheralArrayWithNewPeripheral:(CBPeripheral *)peripheral {
    for (NSUInteger i=0; i<self.discoveredPeripheralArray.count; i++) {
        CBPeripheral *oldPeripheral = self.discoveredPeripheralArray[i];
        if ([[peripheral.identifier UUIDString] isEqualToString:[oldPeripheral.identifier UUIDString]]) {
            [self.discoveredPeripheralArray replaceObjectAtIndex:i withObject:peripheral];
            return;
        }
    }
    [self.discoveredPeripheralArray addObject:peripheral];
}


- (NSDictionary *)notificationUserInfoWithPeripheral:(CBPeripheral *)peripheral {
    NSDictionary *userInfo = @{
                               BHCentralManagerPeripheralConnectNotificationPeripheralKey : peripheral,
                               BHCentralManagerPeripheralConnectNotificationPeripheralTypeIdentifierKey : peripheral.typeIdentifier
                               };
    return userInfo;
}
@end


#import <objc/runtime.h>

static char const * kTypeIdentifierChar = "com.xuebao.peripheral.type.key";

@implementation CBPeripheral (BHExtend)

- (void)setTypeIdentifier:(NSString *)typeIdentifier {
    objc_setAssociatedObject(self, kTypeIdentifierChar, typeIdentifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (NSString *)typeIdentifier {
    return objc_getAssociatedObject(self, kTypeIdentifierChar);
}

@end
