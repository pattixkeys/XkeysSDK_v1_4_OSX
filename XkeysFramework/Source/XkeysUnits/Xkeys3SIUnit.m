//
//  Xkeys3SIUnit.m
//  XkeysFramework
//
//  Created by Ken Heglund on 10/25/17.
//  Copyright © 2017 P.I. Engineering. All rights reserved.
//

#import <XkeysKit/XkeysTypes.h>

#import "XkeysConnection.h"
#import "XkeysHIDSystem.h"
#import "XkeysIdentifiers.h"
#import "XkeysLEDOutput.h"
#import "XkeysBiColorButton.h"
#import "XkeysSliderInput.h"

#import <objc/message.h> //for os version

#import "Xkeys3SIUnit.h"

void Xkeys3SIInputReportCallback( void *context, IOReturn result, void *sender, IOHIDReportType type, uint32_t reportID, uint8_t *report, CFIndex reportLength);

static const uint8_t XK_REPORT_ID = 0;
static const uint8_t XK_GREEN_LED_INDEX = 6;
static const uint8_t XK_RED_LED_INDEX = 7;
static const uint8_t XK_INPUT_REPORT_LENGTH = 36;
//static const uint8_t XK_OUTPUT_COMMAND_LENGTH = 35;
static const uint8_t XK_GENERATE_DATA_COMMAND = 177;
static const uint8_t XK_GENERATE_DATA_REPLY = 2; //could be 3 if program switch is held down
static const uint8_t XK_DESCRIPTOR_COMMAND = 214;
static const uint8_t XK_DESCRIPTOR_REPLY = 214;
static const uint8_t XK_SET_LED_COMMAND = 179;
static const uint8_t XK_SET_BACKLIGHT_COMMAND = 181;
static const uint8_t XK_SET_BACKLIGHT_ROW_COMMAND = 182;
static const uint8_t XK_SET_BACKLIGHT_INTENSITY_COMMAND = 187;
static const uint8_t XK_WRITE_BACKLIGHT_STATE = 199;
static const uint8_t XK_SET_UNITID_COMMAND = 189;
static const uint8_t XK_SET_PID_COMMAND = 204;

static const uint8_t XK_MIN_BLUE_BL_INTENSITY = 0x6B;
static const uint8_t XK_MIN_RED_BL_INTENSITY = 0x4A;
static const uint8_t XK_DEFAULT_BL_INTENSITY = 0x80;

static const uint8_t XK_BUTTON_COUNT = 128;//124; doesn't work if change to 128
uint8_t _firsttime=0; //v1.4



NSInteger thismajor2;
NSInteger thisminor2;
NSInteger thispatch2;

typedef struct {
    NSInteger majorVersion;
   NSInteger minorVersion;
   NSInteger patchVersion;
} MyOperatingSystemVersion;

static const uint8_t XK_BUFFER_LENGTH = XK_INPUT_REPORT_LENGTH;

// MARK: - Xkeys3SIUnit private interface

@interface Xkeys3SIUnit ()

@property (nonatomic) XkeysUnitID hardwareUnitID;

@property (nonatomic) XkeysLEDOutput *greenLED;
@property (nonatomic) XkeysLEDOutput *redLED;

@property (nonatomic, readwrite) NSArray<XkeysLEDOutput *> *leds;

@property (nonatomic) NSArray<XkeysLEDOutput *> *backlights;
@property (nonatomic) NSArray<XkeysBiColorButton *> *buttons;
@property (nonatomic) XkeysInput *tbar;
@property (nonatomic) NSArray<XkeysInput *> *allControls;

@property (nonatomic, copy) XkeysBlueRedButtonCallback onButtonChangeCallback;
@property (nonatomic, copy) XkeysControlCallback onTbarChangeCallback;

@end

// MARK: -

@implementation Xkeys3SIUnit {
    
    uint8_t _reportBuffer[XK_BUFFER_LENGTH];
}

- (instancetype)initWithHIDSystem:(id<XkeysHIDSystem>)hidSystem device:(IOHIDDeviceRef)hidDevice connection:(id<XkeysConnection>)connection {
    
    self = [super initWithHIDSystem:hidSystem device:hidDevice connection:connection];
    if ( ! self ) {
        return nil;
    }
    
    uint32_t targetUsagePage = kHIDPage_Consumer;
    uint32_t targetUsage = kHIDUsage_Csmr_ConsumerControl;
    
    if ( ! connection.receivesData ) {
        // macOS does not create a Consumer Control HID Device for the devices in Hardware Mode pids (no consumer input but with a consumer output).  Therefore, accept a reference to the Keyboard interface.  (All HID devices have the same underlying USB device.)
        targetUsagePage = kHIDPage_GenericDesktop;
        //targetUsage = kHIDUsage_GD_Keyboard; //some devices don't have keyboard endpoint
        targetUsage = kHIDUsage_GD_Mouse; //currently all devices in a hardware mode pid have a mouse endpoint
    }
    
    if ( ! [hidSystem device:hidDevice conformsToUsagePage:targetUsagePage usage:targetUsage] ) {
        return nil;
    }
    else if (targetUsagePage==kHIDPage_Consumer && self.writeLength<10){
        //for devices with both a consumer and multimedia endpoint we want to skip the multimedia endpoint
        return nil;
    }
    
    _greenLED = [[XkeysLEDOutput alloc] initWithDevice:self color:XkeysLEDColorGreen controlIndex:0];
    _redLED = [[XkeysLEDOutput alloc] initWithDevice:self color:XkeysLEDColorRed controlIndex:1];
    
    _backlights = [self buildBacklights];
    _buttons = [self buildButtonInputs];
    
    NSString *tbarName = NSLocalizedString(@"T-bar", @"User-visible name of the t-bar control on the XKE-124");
    _tbar = [[XkeysSliderInput alloc] initWithDevice:self cookie:33 name:tbarName controlIndex:0];
    _allControls = [(NSArray<XkeysInput *> *)_buttons arrayByAddingObject:_tbar];
    
    _leds = [@[_greenLED, _redLED] arrayByAddingObjectsFromArray:_backlights];
    
    return self;
}

- (void)printDebugDescription {
    
    NSLog(@"%@ <%p>: %@ \"%@\"", NSStringFromClass([self class]), self, self.identifier, self.name);
    
    for ( NSObject *led in self.leds ) {
        NSLog(@"\n  %@", [led debugDescription]);
    }
    
    for ( NSObject *control in self.allControls ) {
        NSLog(@"\n  %@", [control debugDescription]);
    }
}

// MARK: - XkeysDevice implementation

- (NSString *)name {
    //return NSLocalizedString(@"Xkeys XKE-124 T-bar", @"Marketing name of the Xkeys XKE-124 T-bar");
    return self.productName;
}

- (void)setProductID:(NSInteger)productID {
    
   // NSArray *validPIDs = @[ @1275, @1276, @1277, @1278 ]; //is this an array of 0,1,2,3?
    NSArray *validPIDs = @[ @1325, @1326, @1327, @1328, @1329, @1330, @1331, @1332];
    //NSAssert( [validPIDs containsObject:@(productID)], @"Xkeys XKE-124 Tbar PIDs must be 1275-1278 (not %ld)", productID);
    //if ( ! [validPIDs containsObject:@(productID)] ) {
    //    return;
    //}
    
    if ( ! self.isOpen ) {
        return;
    }
    
    [super setProductID:productID];
    //not sure what is going on here, mode is 0, 1, 2 and can go as high as 7 for newer psoc4l devices, no need to know the PID, where 0=the first pid, 1=second pid, etc
    uint8_t mode = (uint8_t)[validPIDs indexOfObject:@(productID)];
    [self sendReportWithByte0:XK_SET_PID_COMMAND byte1:mode byte2:0];
}

- (XkeysUnitID)unitID {
    return self.hardwareUnitID;
}

- (void)setUnitID:(XkeysUnitID)unitID {
    
    if ( ! self.isOpen ) {
        return;
    }
    
    if ( unitID == self.hardwareUnitID ) {
        return;
    }
    
    self.hardwareUnitID = unitID;
    [self sendReportWithByte0:XK_SET_UNITID_COMMAND byte1:unitID byte2:0];
}

- (XkeysDeviceIdentifier)identifier {
    return [XkeysIdentifiers identifierForUnit:self];
}

- (CGFloat)defaultBlueBacklightIntensity {
    return (CGFloat)(XK_DEFAULT_BL_INTENSITY - XK_MIN_BLUE_BL_INTENSITY) / (CGFloat)(0xFF - XK_MIN_BLUE_BL_INTENSITY);
}

- (CGFloat)defaultRedBacklightIntensity {
    return (CGFloat)(XK_DEFAULT_BL_INTENSITY - XK_MIN_RED_BL_INTENSITY) / (CGFloat)(0xFF - XK_MIN_RED_BL_INTENSITY);
}

- (id<XkeysBlueRedButton> _Nullable)buttonWithButtonNumber:(NSInteger)buttonNumber {
    
    for ( XkeysBiColorButton *button in self.buttons ) {
        
        if ( button.buttonNumber == buttonNumber ) {
            return button;
        }
    }
    
    return nil;
}

- (id<XkeysControl> _Nullable)controlWithIdentifier:(XkeysControlIdentifier)identifier {
    
    for ( XkeysBiColorButton *button in self.buttons ) {
        
        if ( [XkeysIdentifiers identifier:identifier matchesInput:button] ) {
            return button;
        }
    }
    
  //  if ( [XkeysIdentifiers identifier:identifier matchesInput:self.tbar] ) {
  //      return self.tbar;
  //  }
    
    return nil;
}

- (id<XkeysLED> _Nullable)ledWithIdentifier:(XkeysControlIdentifier)identifier {
    
    for ( XkeysLEDOutput *led in self.leds ) {
        
        if ( [XkeysIdentifiers identifier:identifier matchesLED:led] ) {
            return led;
        }
    }
    
    return nil;
}

- (BOOL)matchesIdentifier:(XkeysIdentifier)identifier {
    return [XkeysIdentifiers identifier:identifier matchesUnit:self];
}

- (void)setAllBacklightsWithColor:(XkeysLEDColor)color toState:(XkeysLEDState)state {
    
    NSArray *validColors = @[ @(XkeysLEDColorBlue), @(XkeysLEDColorRed) ];
    NSAssert( [validColors containsObject:@(color)], @"Backlight color must be XkeysLEDColorBlue or XkeysLEDColorRed (not %ld)", color );
    if ( ! [validColors containsObject:@(color)] ) {
        return;
    }
    
    if ( ! self.isOpen ) {
        return;
    }
    
    uint8_t bankNumber = (uint8_t)[validColors indexOfObject:@(color)];
    uint8_t bankValue = ( state == XkeysLEDStateOn ? 0xFF : 0x00 );
    [self sendReportWithByte0:XK_SET_BACKLIGHT_ROW_COMMAND byte1:bankNumber byte2:bankValue];
    
    for ( XkeysLEDOutput *ledOutput in self.backlights ) {
        
        if ( ledOutput.color == color ) {
            ledOutput.ledState = state;
        }
    }
}

- (void)setCalibratedIntensityOfBacklightsToBlue:(CGFloat)blueFraction red:(CGFloat)redFraction {
    
    CGFloat blueComponent = MIN(MAX(blueFraction, 0.0), 1.0);
    CGFloat redComponent = MIN(MAX(redFraction, 0.0), 1.0);
    
    uint8_t blueRange = (0xFF - XK_MIN_BLUE_BL_INTENSITY);
    uint8_t rawBlueValue = lround((CGFloat)blueRange * blueComponent) + XK_MIN_BLUE_BL_INTENSITY;
    
    uint8_t redRange = (0xFF - XK_MIN_RED_BL_INTENSITY);
    uint8_t rawRedValue = lround((CGFloat)redRange * redComponent) + XK_MIN_RED_BL_INTENSITY;
    
    [self setRawIntensityOfBacklightsToBlue:rawBlueValue red:rawRedValue];
}

- (void)setRawIntensityOfBacklightsToBlue:(uint8_t)blueValue red:(uint8_t)redValue {
    [self sendReportWithByte0:XK_SET_BACKLIGHT_INTENSITY_COMMAND byte1:blueValue byte2:redValue];
}

- (void)writeBacklightStateToEEPROM {
    [self sendReportWithByte0:XK_WRITE_BACKLIGHT_STATE byte1:1 byte2:0];
}

- (void)writeGenericOutput:(nonnull uint8_t *)reportBuffer ofLength:(size_t)bufferLength { 
    [self.connection sendReportBytes:reportBuffer ofLength:bufferLength];
}


// MARK: - Xkeys3SI implementation

- (void)onAnyButtonValueChangePerform:(XkeysBlueRedButtonCallback _Nullable)callback {
    self.onButtonChangeCallback = callback;
}

- (void)onTbarValueChangePerform:(XkeysControlCallback _Nullable)callback {
    self.onTbarChangeCallback = callback;
}

// MARK: - XkeysUnit overrides

- (NSArray<XkeysInput *> *)controlInputs {
    return self.allControls;
}

- (void)initialUnitStateConfigured {
    
    Xkeys3SIUnit * __weak weakSelf = self;
    
    self.greenLED.onStateChange = ^(XkeysLEDState state){
        Xkeys3SIUnit *unit = weakSelf;
        [unit sendReportWithByte0:XK_SET_LED_COMMAND byte1:XK_GREEN_LED_INDEX byte2:state];
    };
    
    self.redLED.onStateChange = ^(XkeysLEDState state){
        Xkeys3SIUnit *unit = weakSelf;
        [unit sendReportWithByte0:XK_SET_LED_COMMAND byte1:XK_RED_LED_INDEX byte2:state];
    };
    
    [super initialUnitStateConfigured];
}

- (void)open {
    
    [super open];
    
    if ( self.connection.receivesData ) {
        _firsttime=0; //v1.4
        [self startListeningForInputReports];
        [self sendGeneralDataReportRequest];
    }
    else {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self initialUnitStateConfigured];
        });
    }
}

- (NSArray<XkeysLEDOutput *> *)buildBacklights {
    
    NSMutableArray *backlightOutputs = [NSMutableArray array];
    
    __weak Xkeys3SIUnit *weakSelf = self;
    
    const NSInteger numberOfBacklightBanks = 2;
    const NSInteger numberOfButtonRows = 8;
    const NSInteger numberOfButtonColumns = 16;
    
    
    
    // Index of the Red backlight is offset by 128 from the Blue backlight on a given button
    //const NSInteger backlightBankOffset = 128;
    
    // Index of the Red backlight is offset by 128 from the Blue backlight on a given button
    NSInteger backlightBankOffset = 128; //changes depending on product
    if  (self.productID==1089 || self.productID==1090||self.productID==1091||self.productID==1250) //XK-80
        backlightBankOffset = 80;
    else if (self.productID==1121 || self.productID==1122 || self.productID==1123 || self.productID==1254) //XK-60
        backlightBankOffset = 80;
    else if (self.productID==1114 || self.productID==1115 || self.productID==1116 || self.productID==1117 || self.productID==1118 || self.productID==1119) //XK-68 Joy and XK-68 Jog
        backlightBankOffset = 80;
    else if (self.productID==1279 || self.productID==1280 || self.productID==1281 || self.productID==1282) //XKE-32 Rack Mount
        backlightBankOffset = 32;
    else if (self.productID==1062 || self.productID==1063 || self.productID==1064 || self.productID==1065 || self.productID==1066 || self.productID==1067) //XK-12 Jog and Joy
        backlightBankOffset = 32;
    else if (self.productID>1324 && self.productID<1333) //XKE-64 Jog Tbar
        backlightBankOffset = 80;
    else if (self.productID>1355 && self.productID<1362) //XKE-40
        backlightBankOffset = 40; //v1.4
    else if (self.productID>1061 && self.productID<1068) //XK-12 Jog/Joy
        backlightBankOffset = 32;
    else if (self.productID>1388 && self.productID<1396) //XBA-Jog Shuttle
        backlightBankOffset = 32; //v1.4
    else if (self.productID>1396 && self.productID<1404) //XBA-T-bar
        backlightBankOffset = 32; //v1.4
    else if (self.productID>1365 && self.productID<1373) //XBK-4x6
        backlightBankOffset = 32; //v1.4
    else if (self.productID>1378 && self.productID<1386) //XBK-3x6
        backlightBankOffset = 32; //v1.4
    
    for ( NSInteger bankIndex = 0 ; bankIndex < numberOfBacklightBanks ; bankIndex++ ) {
        
        XkeysLEDColor color = ( bankIndex == 0 ? XkeysLEDColorBlue : XkeysLEDColorRed );
        
        for ( NSInteger columnIndex = 0 ; columnIndex < numberOfButtonColumns ; columnIndex++ ) {
            
            for ( NSInteger rowIndex = 0 ; rowIndex < numberOfButtonRows ; rowIndex++ ) {
                
               if ( columnIndex == 13 && rowIndex >= 4 ) {
                    // On the XKE124Tbar, the T-bar occupies the 14th column of buttons in the last four rows.
                //    continue;
                  // NSInteger stop=0;
                }
                
                NSInteger buttonNumber = ( columnIndex * numberOfButtonRows ) + rowIndex;
                NSInteger backlightIndex = ( bankIndex * backlightBankOffset ) + buttonNumber;

                // Indexes 0 and 1 are the device's green and red LEDs respectively
                NSInteger controlIndex = backlightIndex + 2;
                
                XkeysLEDOutput *ledOutput = [[XkeysLEDOutput alloc] initWithDevice:self color:color controlIndex:controlIndex];
                
                ledOutput.onStateChange = ^(XkeysLEDState state){
                    Xkeys3SIUnit *unit = weakSelf;
                    [unit sendReportWithByte0:XK_SET_BACKLIGHT_COMMAND byte1:backlightIndex byte2:state];
                };
                
                [backlightOutputs addObject:ledOutput];
            }
        }
    }
    
    return backlightOutputs;
}

- (NSArray<XkeysBiColorButton *> *)buildButtonInputs {
    
    NSAssert(self.backlights.count == (XK_BUTTON_COUNT * 2), @"Backlights are expected to be created before the buttons");
    if ( self.backlights.count != (XK_BUTTON_COUNT * 2) ) {
        return @[];
    }
    
    NSMutableArray *controlInputs = [NSMutableArray array];
    
    NSString *backlightNameFormat = NSLocalizedString(@"%@ %@ Backlight", @"Format of the name of a colored LED that illuminates a button from beneath in the form 'Button #3 Red Backlight'");
    NSString *blueColorName = [XkeysLEDOutput nameForColor:XkeysLEDColorBlue];
    NSString *redColorName = [XkeysLEDOutput nameForColor:XkeysLEDColorRed];

    NSInteger backlightIndex = 0;
    
    const NSInteger numberOfButtonRows = 8;
    const NSInteger numberOfButtonColumns = 16;
    
    // The state of the buttons are reported in a series of HID elements, each element containing the state one column of buttons.
    //const IOHIDElementCookie elementCookieOfFirstColumn = 7;
    IOHIDElementCookie elementCookieOfFirstColumn = 7; //v1.4 removed const
    if ( [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion >= 15 ) {
        elementCookieOfFirstColumn += 2;
    }
    
    for ( NSInteger columnIndex = 0 ; columnIndex < numberOfButtonColumns ; columnIndex++ ) {
        
        for ( NSInteger rowIndex = 0 ; rowIndex < numberOfButtonRows ; rowIndex++ ) {
            
            if ( columnIndex == 13 && rowIndex >= 4 ) {
                // On the XKE124Tbar, the T-bar occupies the 14th column of buttons in the last four rows.
              //  NSInteger stop=0;
               // continue;
            }
            
            NSInteger buttonNumber = ( columnIndex * numberOfButtonRows ) + rowIndex;
            
            IOHIDElementCookie cookie = (IOHIDElementCookie)columnIndex + elementCookieOfFirstColumn;
            
            XkeysBiColorButton *button = [[XkeysBiColorButton alloc] initWithDevice:self cookie:cookie bitIndex:rowIndex controlIndex:buttonNumber];
            
            NSInteger blueBacklightIndex = backlightIndex;
            NSInteger redBacklightIndex = blueBacklightIndex + XK_BUTTON_COUNT;
            backlightIndex += 1;
            
            XkeysLEDOutput *blueBacklight = self.backlights[blueBacklightIndex];
            blueBacklight.name = [NSString stringWithFormat:backlightNameFormat, button.name, blueColorName];
            button.blueLED = blueBacklight;
            
            XkeysLEDOutput *redBacklight = self.backlights[redBacklightIndex];
            redBacklight.name = [NSString stringWithFormat:backlightNameFormat, button.name, redColorName];
            button.redLED = redBacklight;
            
            [controlInputs addObject:button];
        }
    }
    
    return controlInputs;
}

- (void)handleInputValue:(CFIndex)value fromCookie:(IOHIDElementCookie)cookie {
    
    for ( XkeysBiColorButton *button in self.buttons ) {
        
        if ( button.cookie != cookie ) {
            continue;
        }
        
        if ( ! [button handleInputValue:value] ) {
            continue;
        }
        
        [self invokeOnAnyButtonCallbackWithButton:button];
        [self invokeControlValueChangeCallbacksWithControl:button];
    }
    
    if ( self.tbar.cookie != cookie ) {
       return;
    }
    
    if ( ! [self.tbar handleInputValue:value] ) {
       return;
    }
    
    [self invokeOnTbarChangeWithTbar:self.tbar];
    [self invokeControlValueChangeCallbacksWithControl:self.tbar];
}

// MARK: - Xkeys3SIUnit internal

- (void)startListeningForInputReports {
    
    void *context = (__bridge void *)self;
    
    [self.hidSystem device:self.hidDevice registerInputReport:_reportBuffer length:self.readLength callback:Xkeys3SIInputReportCallback context:context]; //v1.4
}

- (void)stopListeningForInputReports {
    [self.hidSystem device:self.hidDevice registerInputReport:_reportBuffer length:self.readLength callback:NULL context:NULL]; //v1.4
}

- (void)sendGeneralDataReportRequest {
    [self sendReportWithByte0:XK_GENERATE_DATA_COMMAND byte1:0 byte2:0];
}

- (void)sendDescriptorRequest {
    [self sendReportWithByte0:XK_DESCRIPTOR_COMMAND byte1:0 byte2:0];
}

- (void)sendReportWithByte0:(uint8_t)byte0 byte1:(uint8_t)byte1 byte2:(uint8_t)byte2 {
    
    if ( ! self.isOpen ) {
        return;
    }
  //  self.writeLength
    bzero(_reportBuffer, sizeof(_reportBuffer));
    
    _reportBuffer[0] = byte0;
    _reportBuffer[1] = byte1;
    _reportBuffer[2] = byte2;
    
    [self.connection sendReportBytes:_reportBuffer ofLength:self.writeLength];
}

- (void)invokeOnAnyButtonCallbackWithButton:(XkeysBiColorButton *)button {
    
    XkeysControlCallback callback = self.onButtonChangeCallback;
    if ( callback == NULL ) {
        return;
    }
    
    if ( ! callback(button) ) {
        self.onButtonChangeCallback = NULL;
    }
}

- (void)invokeOnTbarChangeWithTbar:(XkeysInput *)tbar {
    
    XkeysControlCallback callback = self.onTbarChangeCallback;
    if ( callback == NULL ) {
        return;
    }
    
    if ( ! callback(tbar) ) {
        self.onTbarChangeCallback = NULL;
    }
}

@end

// MARK: - Private functions

void Xkeys3SIInputReportCallback( void *context, IOReturn result, void *sender, IOHIDReportType type, uint32_t reportID, uint8_t *report, CFIndex reportLength) {
    
    Xkeys3SIUnit *unit = (__bridge Xkeys3SIUnit *)context;
    NSCAssert([unit isKindOfClass:[Xkeys3SIUnit class]], @"");
    if ( ! [unit isKindOfClass:[Xkeys3SIUnit class]] ) {
        return;
    }
    
    NSCAssert(report != NULL, @"");
    if ( report == NULL ) {
        return;
    }
    
    NSCAssert(reportID == XK_REPORT_ID, @"%u", reportID);
    if ( reportID != XK_REPORT_ID ) {
        return;
    }
    
   // NSCAssert(reportLength == unit.writeLength, @"%ld", reportLength);
    //if ( reportLength != 36 ) {
     //   return;
    //}
    
    uint8_t replyDataType = report[1];
    
    NSString *joinString=@"";
   for (int i=0;i<reportLength;i++)
    {
        NSString *thisbyte=[NSString stringWithFormat:@"%02X", report[i]]; //2 digit hex string
        joinString=[NSString stringWithFormat:@"%@|%@",joinString,thisbyte];
    }
    unit.rawInput=joinString;
    unit.hardwareUnitID = (NSInteger)report[0];
  //  [unit invokeOnAnyButtonCallbackWithButton:0]; //for raw data to show if send d6, e0 or other output reports that send back a response. //removed v1.4
    
    if ( replyDataType == XK_GENERATE_DATA_REPLY ) {
        
        unit.hardwareUnitID = (NSInteger)report[0];
        [unit.tbar handleInputValue:(CFIndex)report[28]];
        if (_firsttime==0)
        [unit sendDescriptorRequest];
    }
    else if ( replyDataType == XK_DESCRIPTOR_REPLY ) {
        
        uint8_t ledStatus = report[9];
        
        unit.greenLED.state = ( (ledStatus & (1 << XK_GREEN_LED_INDEX)) == 0 ? XkeysLEDStateOff : XkeysLEDStateOn );
        unit.redLED.state = ( (ledStatus & (1 << XK_RED_LED_INDEX)) == 0 ? XkeysLEDStateOff : XkeysLEDStateOn );
       if (_firsttime==0)
       {
           _firsttime=1;
           [unit stopListeningForInputReports];
           [unit initialUnitStateConfigured];
           
           
           
          MyOperatingSystemVersion version = ((MyOperatingSystemVersion(*)(id, SEL))objc_msgSend_stret)([NSProcessInfo processInfo], @selector(operatingSystemVersion));
            thismajor2=version.majorVersion;
            thisminor2=version.minorVersion;
            thispatch2=version.patchVersion;
           
           
       }
    }
    
}
