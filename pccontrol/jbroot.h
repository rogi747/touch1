#ifndef JBROOT_H
#define JBROOT_H

#import <Foundation/Foundation.h>

#include <limits.h>
#include <stdio.h>
#include <unistd.h>

static inline int JBRootIsRootless(void) {
    return access("/var/jb", F_OK) == 0;
}

static inline const char *JBRootPathC(const char *path) {
    if (!JBRootIsRootless()) {
        return path;
    }
    static char buffer[PATH_MAX];
    snprintf(buffer, sizeof(buffer), "/var/jb%s", path);
    return buffer;
}

static inline NSString *JBRootPathOC(NSString *path) {
    if (!JBRootIsRootless()) {
        return path;
    }
    return [@"/var/jb" stringByAppendingString:path];
}

#define JBROOT_PATH(path) JBRootPathC(path)
#define JBROOT_PATH_OC(path) JBRootPathOC(@path)

#endif
