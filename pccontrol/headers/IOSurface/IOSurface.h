

#ifndef _IOSURFACE_H
#define _IOSURFACE_H 1

#include <Availability2.h>

#include <sys/cdefs.h>
#include <CoreFoundation/CFBase.h>

/*
Cannot find "IOSurfaceAPI.h"? Since it is not free or open source, the file is
not put here. Nevertheless, if you're using Mac OS X 10.6, you can get a copy
from
IOMobileFramebuffer
	/System/Library/Frameworks/IOSurface.framework/Headers/IOSurfaceAPI.h

*/
#include "IOSurfaceAPI.h"
#include "IOSurfaceAccelerator.h"
#include "IOMobileFramebuffer.h"

#if __cplusplus
extern "C" {
#endif

void IOSurfaceFlushProcessorCaches(IOSurfaceRef surface);

#if __cplusplus
}
#endif

#endif
