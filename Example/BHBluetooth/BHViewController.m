//
//  BHViewController.m
//  BHBluetooth
//
//  Created by XB-Paul on 02/22/2019.
//  Copyright (c) 2019 XB-Paul. All rights reserved.
//

#import "BHViewController.h"
#import <BHBluetooth/BHCentralManager.h>

@interface BHViewController ()<BHCentralManagerDelegate,UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation BHViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"123rr"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [BHCentralManager shareInstance].delegate = self;
        [[BHCentralManager shareInstance] startScan];
    });
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChangeNotification:) name:BHCentralManagerStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peripheralConnectNotification:) name:BHCentralManagerPeripheralConnectDidChangeNotification object:nil];
}

- (void)stateChangeNotification:(NSNotification *)notification {
    NSLog(@"stateChangeNotification:%@",notification.userInfo);
    BHCentralManagerState state = (BHCentralManagerState)[notification.userInfo[BHCentralManagerStateNotificationStateKey] integerValue];
    switch (state) {
        case BHCentralManagerStatePoweredOn:
            [[BHCentralManager shareInstance] startScan];
            break;
            
        default:
            [self.tableView reloadData];
            break;
    }
}

- (void)peripheralConnectNotification:(NSNotification *)notification {
    NSLog(@"peripheralConnectNotification:%@",notification.userInfo);
    [self.tableView reloadData];
}


- (void)centralManager:(BHCentralManager *)centralManager didUpdateState:(BHCentralManagerState)state {
    
}

- (void)centralManager:(BHCentralManager *)centralManager didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    [self.tableView reloadData];
}

- (void)centralManager:(BHCentralManager *)centralManager didConnectPeripheral:(CBPeripheral *)peripheral {}

- (void)centralManager:(BHCentralManager *)centralManager didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{}

- (void)centralManager:(BHCentralManager *)centralManager didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    [self.tableView reloadData];
}


#pragma mark-
#pragma makr-TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [BHCentralManager shareInstance].discoveredPeripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"123rr" forIndexPath:indexPath];
    CBPeripheral *peripheral = [BHCentralManager shareInstance].discoveredPeripherals[indexPath.row];
    cell.textLabel.text = peripheral.name;
    if (peripheral.state == CBPeripheralStateConnected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CBPeripheral *peripheral = [BHCentralManager shareInstance].discoveredPeripherals[indexPath.row];
    [[BHCentralManager shareInstance] connectPeripheral:peripheral options:nil typeIdentifier:@"testType"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
