#ifndef TOUCH_H
#define TOUCH_H

#include "headers/IOHIDEvent.h"
#include "headers/IOHIDEventData.h"
#include "headers/IOHIDEventTypes.h"
#include "headers/IOHIDEventSystemClient.h"
#include "headers/IOHIDEventSystem.h"

#include <mach/mach_time.h>

#define TOUCH_UP 0
#define TOUCH_DOWN 1
#define TOUCH_MOVE 2

const int TOUCH_DATA_LEN = 13;
extern CGFloat device_screen_width;
extern CGFloat device_screen_height;

int getTouchCountFromDataArray(UInt8* dataArray);
int getTouchTypeFromDataArray(UInt8* dataArray, int index);
int getTouchIndexFromDataArray(UInt8* dataArray, int index);
float getTouchXFromDataArray(UInt8* dataArray, int index);
float getTouchYFromDataArray(UInt8* dataArray, int index);
void performTouchFromData(UInt8 *eventData);

IOHIDEventRef generateChildEventTouchDown(int index, float x, float y);
IOHIDEventRef generateChildEventTouchMove(int index, float x, float y);
IOHIDEventRef generateChildEventTouchUp(int index, float x, float y);

void postIOHIDEvent(IOHIDEventRef event);
void setSenderIdCallback(void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event);
void startSetSenderIDCallBack();
void initSenderId();

void initTouchGetScreenSize();

int getTouchCountFromRawDataArray(UInt8* dataArray);
int getTouchTypeFromRawDataArray(UInt8* dataArray, int index);
int getTouchIndexFromRawDataArray(UInt8* dataArray, int index);
int getTouchXFromRawDataArray(UInt8* dataArray, int index);
int getTouchYFromRawDataArray(UInt8* dataArray, int index);
void performTouchFromRawData(UInt8 *eventData);
void performKeyboardEventFromRawData(UInt8 *eventData);
IOHIDEventRef generateChildEventTouchDownWith(int index, float x, float y);
IOHIDEventRef generateChildEventTouchMoveWith(int index, float x, float y);
IOHIDEventRef generateChildEventTouchUpWith(int index, float x, float y);

#endif
