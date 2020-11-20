//
//  XkeysUnitLibrary.m
//  XkeysFramework
//
//  Created by Ken Heglund on 10/25/17.
//  Copyright © 2017 P.I. Engineering. All rights reserved.
//

#import "XkeysHIDConnection.h"
#import "XkeysHIDSystem.h"
#import "XkeysUSBConnection.h"
#import "Xkeys24Unit.h"
#import "Xkeys124TbarUnit.h"
#import "Xkeys3SIUnit.h"

#import "XkeysUnitLibrary.h"

// MARK: XkeysMapEntry

@interface XkeysMapEntry : NSObject

@property (nonatomic, readonly) Class unitClass;
@property (nonatomic, readonly) XkeysModel model;
@property (nonatomic, readonly) BOOL hidConnection;

- (instancetype)initWithClass:(Class)unitClass model:(XkeysModel)model connectViaHID:(BOOL)hidConnection;

@end

// MARK: -

@implementation XkeysMapEntry

+ (instancetype)mapEntryWithClass:(Class)unitClass model:(XkeysModel)model connectViaHID:(BOOL)hidConnection {
    return [[XkeysMapEntry alloc] initWithClass:unitClass model:model connectViaHID:hidConnection];
}

- (instancetype)initWithClass:(Class)unitClass model:(XkeysModel)model connectViaHID:(BOOL)hidConnection {
    
    self = [super init];
    if ( ! self ) {
        return nil;
    }
    
    _unitClass = unitClass;
    _model = model;
    _hidConnection = hidConnection;
    
    return self;
}

@end

// MARK: -

@interface XkeysUnitLibrary ()

@property (nonatomic) id <XkeysHIDSystem> hidSystem;

@end

// MARK: - XkeysUnitLibrary

@implementation XkeysUnitLibrary

+ (NSDictionary<NSNumber *, XkeysMapEntry *> *)pidMap {
    
    static NSDictionary *pidMap = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once( &onceToken, ^{
        pidMap = @{
                   
            // XK-24
            @1027 : [XkeysMapEntry mapEntryWithClass:[Xkeys24Unit class] model:XkeysModelXK24 connectViaHID:YES],
            @1028 : [XkeysMapEntry mapEntryWithClass:[Xkeys24Unit class] model:XkeysModelXK24HWMode connectViaHID:NO],
            @1029 : [XkeysMapEntry mapEntryWithClass:[Xkeys24Unit class] model:XkeysModelXK24 connectViaHID:YES],
            @1249 : [XkeysMapEntry mapEntryWithClass:[Xkeys24Unit class] model:XkeysModelXK24HWMode connectViaHID:NO],
            @1335 : [XkeysMapEntry mapEntryWithClass:[Xkeys24Unit class] model:XkeysModelXK24 connectViaHID:YES],
            @1336 : [XkeysMapEntry mapEntryWithClass:[Xkeys24Unit class] model:XkeysModelXK24 connectViaHID:YES],
            @1337 : [XkeysMapEntry mapEntryWithClass:[Xkeys24Unit class] model:XkeysModelXK24 connectViaHID:YES],
            @1338 : [XkeysMapEntry mapEntryWithClass:[Xkeys24Unit class] model:XkeysModelXK24 connectViaHID:YES],
            @1339 : [XkeysMapEntry mapEntryWithClass:[Xkeys24Unit class] model:XkeysModelXK24 connectViaHID:YES],
            @1340 : [XkeysMapEntry mapEntryWithClass:[Xkeys24Unit class] model:XkeysModelXK24 connectViaHID:YES],
            @1341 : [XkeysMapEntry mapEntryWithClass:[Xkeys24Unit class] model:XkeysModelXK24 connectViaHID:YES],

            // XKE-124 T-bar
            @1275 : [XkeysMapEntry mapEntryWithClass:[Xkeys124TbarUnit class] model:XkeysModelXKE124Tbar connectViaHID:YES],
            @1276 : [XkeysMapEntry mapEntryWithClass:[Xkeys124TbarUnit class] model:XkeysModelXKE124TbarHWMode connectViaHID:NO],
            @1277 : [XkeysMapEntry mapEntryWithClass:[Xkeys124TbarUnit class] model:XkeysModelXKE124TbarHWMode connectViaHID:NO],
            @1278 : [XkeysMapEntry mapEntryWithClass:[Xkeys124TbarUnit class] model:XkeysModelXKE124Tbar connectViaHID:YES],
            
            //All other products are using the "generic" Xkeys3SIUnit class
            // XK-3 Switch Interface
            @1221 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1222 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1223 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1224 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            // XK-12 Switch Interface
            @1192 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1193 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1194 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1195 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            // XKE-128
            @1227 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1228 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1229 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1230 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //XK-80
            @1089 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1090 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1250 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1091 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //XK-60
            @1121 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1122 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1254 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1123 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //XK-68 Jog/Joy
            @1114 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1115 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1116 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1117 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1118 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1119 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //XK-12 Jog/Joy
            @1062 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1063 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1064 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1065 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1066 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1067 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //Matrix Board
            @1030 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1031 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1255 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1032 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //Footpedal
            @1080 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1081 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1256 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1082 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //XK-16 Stick
            @1049 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1050 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1251 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1051 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //XK-4 Stick
            @1127 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1128 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1253 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1129 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //XK-8 Stick
            @1130 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1131 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1252 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1132 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            // XK-32 Rack Mount
            @1279 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1280 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1281 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1282 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            // HD-15 Wire Interface
            @1244 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1245 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1246 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SIHWMode connectViaHID:NO],
            @1247 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //XK-64 Jog Tbar
            @1325 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
           // @1325 : [XkeysMapEntry mapEntryWithClass:[Xkeys124TbarUnit class] model:XkeysModelXKE124Tbar connectViaHID:YES],
            @1326 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1327 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1328 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1329 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1330 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1331 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //XK-16 LCD
            @1316 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1317 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1318 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1319 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1320 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1321 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1322 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //XKE-40 Stick
            @1355 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1356 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1357 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1358 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1359 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1360 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1361 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //XBK-4x6
            @1365 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1366 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1367 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1368 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1369 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1370 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1371 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //XBK-3x6
            @1378 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1379 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1380 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1381 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1382 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1383 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1384 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //XBA-4x3 Jog Shuttle
            @1388 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1389 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1390 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1391 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1392 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1393 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1394 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //XBA-3x6 T-bar
            @1396 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1397 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1398 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1399 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1400 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1401 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1402 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            
            //XK-QWERTY
            @1343 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1344 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1345 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1346 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1347 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1348 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1349 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],

            //KVMs
            @1283 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1235 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1269 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1237 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1239 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1290 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1300 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
            @1302 : [XkeysMapEntry mapEntryWithClass:[Xkeys3SIUnit class] model:XkeysModelXK3SI connectViaHID:YES],
        };
    });
    
    return pidMap;
}

- (instancetype)initWithHIDSystem:(id <XkeysHIDSystem>)hidSystem {
    
    self = [super init];
    if ( ! self ) {
        return nil;
    }
    
    _hidSystem = hidSystem;
    
    return self;
}

- (XkeysUnit<XkeysDevice> *)makeUnitForHIDDevice:(IOHIDDeviceRef)hidDevice {
    
    NSInteger productID = [self.hidSystem deviceProductID:hidDevice];
    
    XkeysMapEntry *mapEntry = [XkeysUnitLibrary pidMap][@(productID)];
    if ( ! mapEntry ) {
        return nil;
    }
    
    Class unitClass = mapEntry.unitClass;
    BOOL hasProperInitializer = [unitClass instancesRespondToSelector:@selector(initWithHIDSystem:device:connection:)];
    NSAssert(hasProperInitializer, @"");
    if ( ! hasProperInitializer ) {
        return nil;
    }
    
    id<XkeysConnection> connection = nil;
    if ( mapEntry.hidConnection ) {
        connection = [[XkeysHIDConnection alloc] initWithHIDSystem:self.hidSystem device:hidDevice reportID:0];
    }
    else {
        connection = [[XkeysUSBConnection alloc] initWithHIDDevice:hidDevice interfaceNumber:0];
    }
    
    id unit = [[unitClass alloc] initWithHIDSystem:self.hidSystem device:hidDevice connection:connection];
    if ( unit == nil ) {
        return nil;
    }
    
    BOOL hasCorrectSuperclass = [unit isKindOfClass:[XkeysUnit class]];
    NSAssert(hasCorrectSuperclass, @"");
    if ( ! hasCorrectSuperclass ) {
        return nil;
    }
    
    BOOL conformsToCorrectProtocol = [unit conformsToProtocol:@protocol(XkeysDevice)];
    NSAssert(conformsToCorrectProtocol, @"");
    if ( ! conformsToCorrectProtocol ) {
        return nil;
    }
    
    return unit;
}

+ (XkeysModel)modelFromProductID:(NSInteger)productID {
    
    XkeysMapEntry *mapEntry = [XkeysUnitLibrary pidMap][@(productID)];
    if ( ! mapEntry ) {
        return XkeysModelUnknown;
    }
    
    return mapEntry.model;
}

@end
