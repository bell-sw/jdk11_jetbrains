// Copyright 2000-2020 JetBrains s.r.o. Use of this source code is governed by the Apache 2.0 license that can be found in the LICENSE file.

#import "JavaListAccessibility.h"
#import "JavaAccessibilityUtilities.h"
#import "ThreadUtilities.h"

@implementation JavaListAccessibility

- (NSString *)getPlatformAxElementClassName
{
    return @"PlatformAxList";
}

@end

@implementation PlatformAxList

- (nullable NSArray<id<NSAccessibilityRow>> *)accessibilityRows {
    return [self accessibilityChildren];
}

- (nullable NSArray<id<NSAccessibilityRow>> *)accessibilitySelectedRows {
    return [self accessibilitySelectedChildren];
}

- (NSString *)accessibilityLabel
{
    return [super accessibilityLabel] == NULL ? @"list" : [super accessibilityLabel];
}

// to avoid warning (why?): method in protocol 'NSAccessibilityElement' not implemented

- (NSRect)accessibilityFrame
{
    return [super accessibilityFrame];
}

// to avoid warning (why?): method in protocol 'NSAccessibilityElement' not implemented

- (id)accessibilityParent
{
    return [super accessibilityParent];
}

@end

