// Copyright 2000-2020 JetBrains s.r.o. Use of this source code is governed by the Apache 2.0 license that can be found in the LICENSE file.

#include "jni.h"
#import "JavaTableRowAccessibility.h"
#import "JavaAccessibilityAction.h"
#import "JavaAccessibilityUtilities.h"
#import "JavaTableAccessibility.h"
#import "JavaCellAccessibility.h"
#import "ThreadUtilities.h"
#import "JNIUtilities.h"

// GET* macros defined in JavaAccessibilityUtilities.h, so they can be shared.
static jclass sjc_CAccessibility = NULL;

static jmethodID jm_getChildrenAndRoles = NULL;
#define GET_CHILDRENANDROLES_METHOD_RETURN(ret) \
    GET_CACCESSIBILITY_CLASS_RETURN(ret); \
    GET_STATIC_METHOD_RETURN(jm_getChildrenAndRoles, sjc_CAccessibility, "getChildrenAndRoles",\
                      "(Ljavax/accessibility/Accessible;Ljava/awt/Component;IZ)[Ljava/lang/Object;", ret);


@implementation JavaTableRowAccessibility

// NSAccessibilityElement protocol methods

- (NSAccessibilityRole)accessibilityRole {
    return NSAccessibilityRowRole;
}

- (NSAccessibilitySubrole)accessibilitySubrole {
    return NSAccessibilityTableRowSubrole;
}

- (NSArray *)accessibilityChildren {
    NSArray *children = [super accessibilityChildren];
    if (children == NULL) {
        JNIEnv *env = [ThreadUtilities getJNIEnv];
        JavaComponentAccessibility *parent = [self accessibilityParent];
        if (parent->fAccessible == NULL) return nil;
        GET_CHILDRENANDROLES_METHOD_RETURN(nil);
        jobjectArray jchildrenAndRoles = (jobjectArray)(*env)->CallStaticObjectMethod(env, sjc_CAccessibility, jm_getChildrenAndRoles, parent->fAccessible, parent->fComponent, JAVA_AX_ALL_CHILDREN, NO);
        CHECK_EXCEPTION();
        if (jchildrenAndRoles == NULL) return nil;

        jsize arrayLen = (*env)->GetArrayLength(env, jchildrenAndRoles);
        NSMutableArray *childrenCells = [NSMutableArray arrayWithCapacity:arrayLen/2];

        NSUInteger childIndex = [self rowNumberInTable] * [(JavaTableAccessibility *)parent accessibleColCount];
        NSInteger i = childIndex * 2;
        NSInteger n = ([self rowNumberInTable] + 1) * [(JavaTableAccessibility *)parent accessibleColCount] * 2;
        for(i; i < n; i+=2)
        {
            jobject /* Accessible */ jchild = (*env)->GetObjectArrayElement(env, jchildrenAndRoles, i);
            jobject /* String */ jchildJavaRole = (*env)->GetObjectArrayElement(env, jchildrenAndRoles, i+1);

            NSString *childJavaRole = nil;
            if (jchildJavaRole != NULL) {
                DECLARE_CLASS_RETURN(sjc_AccessibleRole, "javax/accessibility/AccessibleRole", nil);
                DECLARE_FIELD_RETURN(sjf_key, sjc_AccessibleRole, "key", "Ljava/lang/String;", nil);
                jobject jkey = (*env)->GetObjectField(env, jchildJavaRole, sjf_key);
                childJavaRole = JavaStringToNSString(env, jkey);
                (*env)->DeleteLocalRef(env, jkey);
            }

            JavaCellAccessibility *child = [[JavaCellAccessibility alloc] initWithParent:self
                                                                                 withEnv:env
                                                                          withAccessible:jchild
                                                                               withIndex:childIndex
                                                                                withView:self->fView
                                                                            withJavaRole:childJavaRole];
            [childrenCells addObject:[[child retain] autorelease]];

            (*env)->DeleteLocalRef(env, jchild);
            (*env)->DeleteLocalRef(env, jchildJavaRole);

            childIndex++;
        }
        (*env)->DeleteLocalRef(env, jchildrenAndRoles);
        return childrenCells;
    } else {
        return children;
    }
}

- (NSInteger)accessibilityIndex {
    return fIndex;
}

- (NSString *)accessibilityLabel {
    NSString *accessibilityName = @"";
        for (id cell in [self accessibilityChildren]) {
            if ([accessibilityName isEqualToString:@""]) {
                accessibilityName = [cell accessibilityLabel];
            } else {
                accessibilityName = [accessibilityName stringByAppendingFormat:@", %@", [cell accessibilityLabel]];
            }
        }
        return accessibilityName;
}

- (id)accessibilityParent
{
    return [super accessibilityParent];
}

- (NSUInteger)rowNumberInTable {
        return self->fIndex;
}

- (NSRect)accessibilityFrame {
        int height = [[[self accessibilityChildren] objectAtIndex:0] accessibilityFrame].size.height;
        int width = 0;
        NSPoint point = [[[self accessibilityChildren] objectAtIndex:0] accessibilityFrame].origin;
        for (id cell in [self accessibilityChildren]) {
            width += [cell accessibilityFrame].size.width;
        }
        return NSMakeRect(point.x, point.y, width, height);
}

@end

