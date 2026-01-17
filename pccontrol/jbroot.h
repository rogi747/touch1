#ifndef JBROOT_H
#define JBROOT_H

#import <Foundation/Foundation.h>

#include <limits.h>
#include <stdio.h>
#include <unistd.h>

static inline int JBRootIsRootless(void) {
    return access("/var/jb/usr", F_OK) == 0;
}

static inline const char *JBRootPathC(const char *path) {
    if (!JBRootIsRootless()) {
        return path;
    }
    static char buffer[PATH_MAX];
    snprintf(buffer, sizeof(buffer), "/var/jb%s", path);
    if (access(buffer, F_OK) == 0) {
        return buffer;
    }
    return path;
}

static inline NSString *JBRootPathOC(NSString *path) {
    if (!JBRootIsRootless()) {
        return path;
    }
    NSString *rootlessPath = [@"/var/jb" stringByAppendingString:path];
    if (access([rootlessPath fileSystemRepresentation], F_OK) == 0) {
        return rootlessPath;
    }
    return path;
}

#define JBROOT_PATH(path) JBRootPathC(path)
#define JBROOT_PATH_OC(path) JBRootPathOC(@path)

#endif
