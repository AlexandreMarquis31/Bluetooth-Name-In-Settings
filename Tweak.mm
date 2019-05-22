@import UIKit;

@interface BluetoothManager : NSObject
+(BluetoothManager*)sharedInstance;
-(NSArray*)connectedDevices;
-(BOOL)powered;
@end

@interface BluetoothDevice : NSObject
@property (nonatomic,retain) NSString* name;
@end

@interface PSUIPrefsListController
@property(nonatomic,retain) UITableView* table;
@end

static BluetoothManager* manager;
static UITableView* tableTarget;

UITableView* tableView(UITableViewCell* tableCell){
    id tableView= [tableCell superview];
    while(![tableView isKindOfClass:[UITableView class]]){
        tableView= [tableView superview];
    }
    return (UITableView*)tableView;
}

void changeBluetoothNameInCell(UITableViewCell* tableCell){
    if(![manager connectedDevices].count){
        tableCell.detailTextLabel.text=((BluetoothDevice*)[manager connectedDevices].firstObject).name;
    }
    else if ([manager powered]){
        if ([NSLocalizedString(@"On",@"On") isEqualToString:@"oui"]){
            tableCell.detailTextLabel.text=@"Oui";
        }
        else{
            tableCell.detailTextLabel.text=NSLocalizedString(@"On",@"On");
        }
    }
}

%hook PreferencesAppController
//get Bluetooth manager instance
-(void)applicationDidBecomeActive:(id)arg1{
    %orig;
    manager =[BluetoothManager sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothAvailabilityChanged:) name:@"BluetoothAvailabilityChangedNotification" object:nil];
}

%new
//add bluetooth name in cell if a device was connected before opening of the app
- (void)bluetoothAvailabilityChanged:(NSNotification *)notification{
    for (UITableViewCell* cell in tableTarget.visibleCells){
        if ([cell.textLabel.text isEqualToString:NSLocalizedString(@"BTMACAddress",@"Bluetooth")] && tableTarget==tableView(cell)){
            changeBluetoothNameInCell(cell);
        }
    }
}
%end

%hook PSUIPrefsListController
-(void)viewDidLoad{
    %orig;
    tableTarget= self.table;
}
%end

%hook UITableViewCell
//add device name to the cell
-(void)layoutSubviews{
    %orig;
    if ([self.textLabel.text isEqualToString:NSLocalizedString(@"BTMACAddress",@"Bluetooth")] && tableTarget==tableView(self)){
        changeBluetoothNameInCell(self);
    }
}
%end

%hook BluetoothManager
//change device name in cell when device just connected/disconnected
-(void)_connectedStatusChanged{
    %orig;
    for (UITableViewCell* cell in tableTarget.visibleCells){
        if ([cell.textLabel.text isEqualToString:NSLocalizedString(@"BTMACAddress",@"Bluetooth") ] && tableTarget==tableView(cell)){
            changeBluetoothNameInCell(cell);
        }
    }
}
%end