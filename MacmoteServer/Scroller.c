//
//  Scroller.c
//  MacmoteServer
//
//  Created by Griffin Prechter on 4/18/18.
//  Copyright © 2018 Griffin Prechter. All rights reserved.
//

#include "Scroller.h"
#include <ApplicationServices/ApplicationServices.h>

void createScrollWheelEvent(int amm) {
    CGEventRef upEvent = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitLine, amm, 1, 1);
    CGEventSetIntegerValueField(NULL, kCGScrollWheelEventDeltaAxis1, amm);
    CGEventPost(kCGHIDEventTap, upEvent);
    CFRelease(upEvent);
}
