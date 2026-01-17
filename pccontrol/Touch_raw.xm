#include "Touch.h"
#include "Common.h"
#include "Screen.h"
#include "AlertBox.h"
#include "Task.h"
#import "headers/IOHIDUsageTables.h"

#define MAX_FINGER_INDEX 20

#define NOT_VALID 0
#define VALID 1
#define VALID_AT_NEXT_APPEND 2

#define EVENT_VALID_INDEX 0
#define EVENT_TYPE_INDEX 1
#define EVENT_X_INDEX 2
#define EVENT_Y_INDEX 3
#define EVENT_MASK 4

// valid type x y
static int eventsToAppend[MAX_FINGER_INDEX][5];

/*
get count from data array
*/
int getTouchCountFromRawDataArray(UInt8* dataArray)
{
	int count = (dataArray[0] - '0');
	return count;
}

/*
get type from data array
*/
int getTouchTypeFromRawDataArray(UInt8* dataArray, int index)
{
	int type = (dataArray[1 + index * TOUCH_DATA_LEN] - '0');
	return type;
}

/*
get index from data array
*/
int getTouchIndexFromRawDataArray(UInt8* dataArray, int index)
{
	int touchIndex = 0;
	for (int i = 2; i <= 3; i++)
	{
		touchIndex += (dataArray[i + index * TOUCH_DATA_LEN] - '0') * pow(10, 3 - i);
	}
	return touchIndex;
}

/*
get x from data array
*/
int getTouchXFromRawDataArray(UInt8* dataArray, int index)
{
	int x = 0;
    BOOL isNegative = dataArray[4] == '-';
    int i = 0;
    if (isNegative) {
        i = 5;
    } else {
        i = 4;
    }
	for (; i <= 10; i++)
	{
		x += (dataArray[i + index * TOUCH_DATA_LEN] - '0') * pow(10, 10 - i);
	}
	return isNegative ? -x : x;
}


/*
get y from data array
*/
int getTouchYFromRawDataArray(UInt8* dataArray, int index)
{
	int y = 0;
    BOOL isNegative = dataArray[11] == '-';
    int i = 0;
    if (isNegative) {
        i = 12;
    } else {
        i = 11;
    }
	for (; i <= 17; i++)
	{
		y += (dataArray[i + index * TOUCH_DATA_LEN] - '0') * pow(10, 17 - i);
	}
	return isNegative ? -y : y;
}

/*
get parent event mask from data array
*/
int getTouchParentEventMaskFromRawDataArray(UInt8* dataArray, int index)
{
    int y = 0;
    for (int i = 18; i <= 25; i++)
    {
        y += (dataArray[i + index * TOUCH_DATA_LEN] - '0') * pow(10, 25 - i);
    }
    return y;
}

/*
get child event mask from data array
*/
int getTouchChildEventMaskFromRawDataArray(UInt8* dataArray, int index)
{
    int y = 0;
    for (int i = 26; i <= 33; i++)
    {
        y += (dataArray[i + index * TOUCH_DATA_LEN] - '0') * pow(10, 33 - i);
    }
    return y;
}

/*
get home button event from data array
*/
int getKeyboardIsDownFromRawDataArray(UInt8* dataArray)
{
    int isDown = (dataArray[1] - '0');
    return isDown;
}

/*
Get the child event of touching down.
index: index of the finger
x: coordinate x of the screen (before conversion)
y: coordinate y of the screen (before conversion)
*/
IOHIDEventRef generateChildEventTouchDownWith(int index, int mask, float x, float y)
{
	IOHIDEventRef child = IOHIDEventCreateDigitizerFingerEvent(kCFAllocatorDefault, mach_absolute_time(), index, 3, mask, x, y, .0f, .0f, .0f, 1, 1, 0);
    IOHIDEventSetFloatValue(child, 0xb0014, 0.04f); //set the major index getRandomNumberFloat(0.03, 0.05)
    IOHIDEventSetFloatValue(child, 0xb0015, 0.04f); //set the minor index
	return child;
}

/*
Get the child event of touching move. 
index: index of the finger
x: coordinate x of the screen (before conversion)
y: coordinate y of the screen (before conversion)
*/
IOHIDEventRef generateChildEventTouchMoveWith(int index, int mask, float x, float y)
{
	IOHIDEventRef child = IOHIDEventCreateDigitizerFingerEvent(kCFAllocatorDefault, mach_absolute_time(), index, 3, mask, x, y, .0f, .0f, .0f, 1, 1, 0);
    IOHIDEventSetFloatValue(child, 0xb0014, 0.04f); //set the major index
    IOHIDEventSetFloatValue(child, 0xb0015, 0.04f); //set the minor index
	return child;
}

/*
Get the child event of touching up.
index: index of the finger
x: coordinate x of the screen (before conversion)
y: coordinate y of the screen (before conversion)
*/
IOHIDEventRef generateChildEventTouchUpWith(int index, int mask, float x, float y)
{
	IOHIDEventRef child = IOHIDEventCreateDigitizerFingerEvent(kCFAllocatorDefault, mach_absolute_time(), index, 3, mask, x, y, .0f, .0f, .0f, 0, 0, 0);
    IOHIDEventSetFloatValue(child, 0xb0014, 0.04f); //set the major index
    IOHIDEventSetFloatValue(child, 0xb0015, 0.04f); //set the minor index
	return child;
}

/**
Append child event to parent
*/
static void appendChildEventWith(IOHIDEventRef parent, int type, int index, int mask, float x, float y)
{
    switch (type)
    {
        case TOUCH_MOVE:
			IOHIDEventAppendEvent(parent, generateChildEventTouchMoveWith(index, mask, x, y));
            break;
        case TOUCH_DOWN:
            IOHIDEventAppendEvent(parent, generateChildEventTouchDownWith(index, mask, x, y));
            break;
        case TOUCH_UP:
            IOHIDEventAppendEvent(parent, generateChildEventTouchUpWith(index, mask, x, y));
            break;
        default:
            NSLog(@"com.zjx.springboard: Unknown touch event type in appendChildEvent, type: %d", type);
    }
}


/**
Perform touch events with data received from socket
*/
void performTouchFromRawData(UInt8 *eventData)
{
    // generate a parent event
	IOHIDEventRef parent = IOHIDEventCreateDigitizerEvent(kCFAllocatorDefault, mach_absolute_time(), 3, 99, 1, 0, 0, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0, 0, 0); 
    IOHIDEventSetIntegerValue(parent , 0xb0019, 1); //set flags of parent event   flags: 0x20001 -> 0xa0001
    IOHIDEventSetIntegerValue(parent , 0x4, 1); //set flags of parent event   flags: 0xa0001 -> 0xa0011

    int p_eventMask = 0x23;
    IOHIDFloat event_x = 0;
    IOHIDFloat event_y = 0;
    int event_range = 0;
    int event_touch = 0;
    // count目前固定是1，每个child event都是单独的一行数据，数据写入和读取的时候实际上都没有适配多个child的情况
    int count = getTouchCountFromRawDataArray(eventData);
    for (int i = 0; i < count; i++)
    {
        int touchType = getTouchTypeFromRawDataArray(eventData, i);
        int index = getTouchIndexFromRawDataArray(eventData, i);
        int x = getTouchXFromRawDataArray(eventData, i);
        int y = getTouchYFromRawDataArray(eventData, i);
        p_eventMask = getTouchParentEventMaskFromRawDataArray(eventData, i);
        int c_eventMask = getTouchChildEventMaskFromRawDataArray(eventData, i);
        //NSLog(@"### com.zjx.springboard: get data. index: %d. type: %d. touchIndex: %d. x: %d. y: %d", i, touchType, index, x, y);


        event_x = x / SIZE_FACTOR;
        event_y = y / SIZE_FACTOR;
        appendChildEventWith(parent, touchType, index, c_eventMask, event_x, event_y); // append child event to parent

        switch (touchType)
        {
            case TOUCH_MOVE:
                eventsToAppend[index][EVENT_VALID_INDEX] = VALID_AT_NEXT_APPEND;
                eventsToAppend[index][EVENT_TYPE_INDEX] = TOUCH_MOVE;
                eventsToAppend[index][EVENT_X_INDEX] = x;
                eventsToAppend[index][EVENT_Y_INDEX] = y;
                eventsToAppend[i][EVENT_MASK] = c_eventMask;
                event_range = 1;
                event_touch = 1;
                break;
            case TOUCH_DOWN:
                eventsToAppend[index][EVENT_VALID_INDEX] = VALID_AT_NEXT_APPEND;
                eventsToAppend[index][EVENT_TYPE_INDEX] = TOUCH_DOWN;
                eventsToAppend[index][EVENT_X_INDEX] = x;
                eventsToAppend[index][EVENT_Y_INDEX] = y;
                eventsToAppend[i][EVENT_MASK] = c_eventMask;
                event_range = 1;
                event_touch = 1;
                break;
            case TOUCH_UP:
                eventsToAppend[index][EVENT_VALID_INDEX] = NOT_VALID;
                break;
        }

    }

    for (int i = 0; i < MAX_FINGER_INDEX; i++)
    {
        if (eventsToAppend[i][EVENT_VALID_INDEX] == VALID)
        {
            //NSLog(@"com.zjx.springboard: appending event for finger: %d. type: %d. x: %d. y: %d", i, eventsToAppend[i][EVENT_TYPE_INDEX], eventsToAppend[i][EVENT_X_INDEX], eventsToAppend[i][EVENT_Y_INDEX]);
            appendChildEventWith(parent, eventsToAppend[i][EVENT_TYPE_INDEX], i, eventsToAppend[i][EVENT_MASK], eventsToAppend[i][EVENT_X_INDEX] / SIZE_FACTOR, eventsToAppend[i][EVENT_Y_INDEX] / SIZE_FACTOR);
        }
        else if (eventsToAppend[i][EVENT_VALID_INDEX] == VALID_AT_NEXT_APPEND) // make it valid
        {
            //NSLog(@"com.zjx.springboard:  finger: %d to become valid. type: %d. x: %d. y: %d", i, eventsToAppend[i][EVENT_TYPE_INDEX], eventsToAppend[i][EVENT_X_INDEX], eventsToAppend[i][EVENT_Y_INDEX]);
            eventsToAppend[i][EVENT_VALID_INDEX] = VALID;
        }
    }

    IOHIDEventSetIntegerValue(parent, 0xb0007, 0x23);
    //IOHIDEventSetIntegerValue(parent, 0xb0008, 0x1);
    //IOHIDEventSetIntegerValue(parent, 0xb0009, 0x1);
    IOHIDEventSetIntegerValue(parent, kIOHIDEventFieldDigitizerEventMask, p_eventMask);
    IOHIDEventSetFloatValue(parent, kIOHIDEventFieldDigitizerX, event_x);
    IOHIDEventSetFloatValue(parent, kIOHIDEventFieldDigitizerY, event_y);
    IOHIDEventSetIntegerValue(parent, kIOHIDEventFieldDigitizerRange, event_range);
    IOHIDEventSetIntegerValue(parent, kIOHIDEventFieldDigitizerTouch, event_touch);

    postIOHIDEvent(parent);
    CFRelease(parent);
}

/**
Perform keyboard events with data received from socket
*/
void performKeyboardEventFromRawData(UInt8 *eventData) {
    // 创建Home键事件, isDown为true是按下，否则为抬起
    bool isDown = getKeyboardIsDownFromRawDataArray(eventData);
    NSLog(@"### com.zjx.springboard: Home button %d", isDown);
    IOHIDEventRef homeButtonEvent = IOHIDEventCreateKeyboardEvent(
        kCFAllocatorDefault,
        mach_absolute_time(),
        0x0C, // Usage Page: Consumer
        0x40, // Usage: Menu/Home
        isDown,
        0
    );

    postIOHIDEvent(homeButtonEvent);
    CFRelease(homeButtonEvent);
}
