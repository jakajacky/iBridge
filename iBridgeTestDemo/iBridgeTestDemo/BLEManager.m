#import "BLEManager.h"
#import "BLEService.h"
#import "BLEGATTService.h"

/*#import "HRPService.h"
#import "CSCPService.h"
#import "HTPService.h"
#import "GLPService.h"
#import "FMPService.h"
#import "BLPService.h"
#import "OXIService.h"*/

NSString * kAdvDataLocalName = @"kCBAdvDataLocalName";
NSString * kAdvDataServiceUUIDs = @"kCBAdvDataServiceUUIDs";

@interface BLEManager () <CBCentralManagerDelegate> {
	CBCentralManager    *centralManager;
    BLEService *bleService;
}

@end

@implementation BLEManager


#pragma mark -
#pragma mark Init
/****************************************************************************/
/*									Init									*/
/****************************************************************************/
+ (id) sharedInstance
{
	static BLEManager	*this	= nil;

	if (!this)
		this = [[BLEManager alloc] init];

	return this;
}


- (id) init
{
    self = [super init];
    if (self) {
		centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    }
    return self;
}


- (void) dealloc
{
    // We are a singleton and as such, dealloc shouldn't be called.
    assert(NO);
}

- (BLEService *) getBLEService {
    return bleService;
}

#pragma mark -
#pragma mark Discovery
/****************************************************************************/
/*								Discovery                                   */
/****************************************************************************/
- (void) scanForPeripherals:(NSString *)uuidString
{
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    NSArray	*uuidArray = nil;
    if (uuidString) {
        uuidArray	= [NSArray arrayWithObjects:[CBUUID UUIDWithString:uuidString], nil];
    }
    [centralManager scanForPeripheralsWithServices:uuidArray options:options];
}

- (void) stopScan
{
	[centralManager stopScan];
}

- (NSArray<CBPeripheral *> *)retrievePeripheralsWithIdentifiers:(NSArray<NSUUID *> *)identifiers {
    return [centralManager retrievePeripheralsWithIdentifiers:identifiers];
}

#pragma mark -
#pragma mark Connection/Disconnection
/****************************************************************************/
/*						Connection/Disconnection                            */
/****************************************************************************/
- (void) connect:(CBPeripheral*)peripheral
{
    [centralManager connectPeripheral:peripheral options:nil];
}

- (void) disconnect:(CBPeripheral*)peripheral
{
	[centralManager cancelPeripheralConnection:peripheral];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    [_delegate didUpdateState:central.state];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString * name = [advertisementData valueForKey:kAdvDataLocalName];
    NSLog(@"[iBridgeLib]found a peripheral: %s.RSSI:%s", [name cStringUsingEncoding:NSUTF8StringEncoding], [[RSSI stringValue] cStringUsingEncoding:NSUTF8StringEncoding]);
    [self printAdvertiseData:advertisementData];

    [_delegate didPeripheralFound:peripheral advertisementData:advertisementData RSSI:RSSI];
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"[iBridgeLib]peripheral: %s connected", [[peripheral name] cStringUsingEncoding:NSUTF8StringEncoding]);
    [_delegate didConnectPeripheral:peripheral];
}


- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"[iBridgeLib]attempted connection to peripheral %@ failed: %@", [peripheral name], [error localizedDescription]);
    [_delegate didFailToConnectPeripheral:peripheral error:error];
}


- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"[iBridgeLib]peripheral %@ disconnect, error : %@", [peripheral name], [error description]);
    [_delegate didDisconnectPeripheral:peripheral error:error];
}

- (void) printAdvertiseData:(NSDictionary *) data {
    NSArray * array = [data allKeys];
    NSLog(@"[iBridgeLib]advertising data:");
    NSLog(@"+++++++++++++++++++++++++++++++++++++++++++++");
    for (int i=0;i<[array count];i++) {
        id key = [array objectAtIndex:i];
        NSString * keyName = (NSString *) key;
        NSObject * value = [data valueForKey:key];
        if ([value isKindOfClass:[NSArray class]]) {
            NSLog(@"key: %s", [keyName cStringUsingEncoding:NSUTF8StringEncoding]);
            NSArray * values = (NSArray *) value;
            for (int j=0;j<[values count];j++) {
                NSObject * aValue = [values objectAtIndex:j];
                NSLog(@"value: %s", [[aValue description] cStringUsingEncoding:NSUTF8StringEncoding]);
                //NSLog(@"is NSData:%d", [aValue isKindOfClass:[NSData class]]);
            }
        } else {
            const char * valueString = [[value description] cStringUsingEncoding:NSUTF8StringEncoding];
            NSLog(@"key: %s", [keyName cStringUsingEncoding:NSUTF8StringEncoding]);
            NSLog(@"value: %s", valueString);
        }
    }
   NSLog(@"-----------------------------------------------");
}

- (NSArray *) getAdvertiseUUIDs:(NSDictionary *) data {
    NSArray * array = [data valueForKey:kAdvDataServiceUUIDs];
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSLog(@"[iBridgeLib]advertising uuids:");
    NSLog(@"+++++++++++++++++++++++++++++++++++++++++++++");
    for (int i=0;i<[array count];i++) {
        NSObject * obj = [array objectAtIndex:i];
        if ([obj isKindOfClass:[CBUUID class]]) {
            CBUUID * uuid = (CBUUID *) obj;
            unsigned char * bytes = (unsigned char *) [uuid.data bytes];
            NSString * uuidStr = [NSString stringWithFormat:@"%02x%02x", bytes[0], bytes[1]];
            NSLog(@"uuid: %@",uuidStr);
            [result addObject:uuidStr];
        }
    }
    NSLog(@"-----------------------------------------------");
    return result;
}

@end
