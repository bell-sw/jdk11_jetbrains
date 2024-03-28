/*
 * Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved.
 * Copyright (c) 2021, JetBrains s.r.o.. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */

#import "TableRowAccessibility.h"
#import "JavaAccessibilityAction.h"
#import "JavaAccessibilityUtilities.h"
#import "TableAccessibility.h"
#import "CellAccessibility.h"
#import "ThreadUtilities.h"
#import "JNIUtilities.h"
#import "sun_lwawt_macosx_CAccessibility.h"

static jclass sjc_CAccessibility = NULL;

@implementation TableRowAccessibility

// NSAccessibilityElement protocol methods

- (NSAccessibilityRole)accessibilityRole
{
    return NSAccessibilityRowRole;
}

- (NSAccessibilitySubrole)accessibilitySubrole
{
    return NSAccessibilityTableRowSubrole;
}

- (NSArray *)accessibilityChildren
{
    NSMutableArray *children = [super accessibilityChildren];
    if (children == nil) {
        JNIEnv *env = [ThreadUtilities getJNIEnv];
        CommonComponentAccessibility *parent = [self accessibilityParent];
        if (parent->fAccessible == NULL) return nil;

        GET_CACCESSIBILITY_CLASS_RETURN(nil);
        DECLARE_STATIC_METHOD_RETURN(jm_getTableRowChildrenAndRoles, sjc_CAccessibility, "getTableRowChildrenAndRoles",\
            "(Ljavax/accessibility/Accessible;Ljava/awt/Component;IZI)[Ljava/lang/Object;", nil);

        jobjectArray jchildrenAndRoles = (jobjectArray)(*env)->CallStaticObjectMethod(
                env, sjc_CAccessibility, jm_getTableRowChildrenAndRoles, parent->fAccessible, parent->fComponent,
                sun_lwawt_macosx_CAccessibility_JAVA_AX_ALL_CHILDREN, NO, [self rowNumberInTable]);
        CHECK_EXCEPTION();

        if (jchildrenAndRoles == NULL) return nil;

        jsize arrayLen = (*env)->GetArrayLength(env, jchildrenAndRoles);
        children = [NSMutableArray arrayWithCapacity:arrayLen / 2];
        int childIndex = [self rowNumberInTable] * [(TableAccessibility *)parent accessibilityColumnCount];

        for (NSInteger i = 0; i < arrayLen; i += 2) {
            jobject /* Accessible */ jchild = (*env)->GetObjectArrayElement(env, jchildrenAndRoles, i);
            jobject /* String */ jchildJavaRole = (*env)->GetObjectArrayElement(env, jchildrenAndRoles, i+1);

            NSString *childJavaRole = nil;
            if (jchildJavaRole != NULL) {
                DECLARE_CLASS_RETURN(sjc_AccessibleRole, "javax/accessibility/AccessibleRole", nil);
                DECLARE_FIELD_RETURN(sjf_key, sjc_AccessibleRole, "key", "Ljava/lang/String;", nil);
                jobject jkey = (*env)->GetObjectField(env, jchildJavaRole, sjf_key);
                CHECK_EXCEPTION();
                childJavaRole = JavaStringToNSString(env, jkey);
                (*env)->DeleteLocalRef(env, jkey);
            }

            CellAccessibility *child = (CellAccessibility *)
                [CommonComponentAccessibility createWithParent:self
                                                     withClass:[CellAccessibility class]
                                                    accessible:jchild
                                                          role:childJavaRole
                                                         index:childIndex
                                                       withEnv:env
                                                      withView:self->fView];
            [children addObject:child];

            (*env)->DeleteLocalRef(env, jchild);
            (*env)->DeleteLocalRef(env, jchildJavaRole);

            childIndex++;
        }
        (*env)->DeleteLocalRef(env, jchildrenAndRoles);
    }
    return children;
}

- (NSUInteger)rowNumberInTable {
    return self->fIndex;
}

- (NSInteger)accessibilityIndex
{
    return self->fIndex;
}

- (NSString *)accessibilityLabel
{
    NSString *accessibilityName = @"";
    NSArray *children = [self accessibilityChildren];
        for (id cell in children) {
            if ([accessibilityName isEqualToString:@""]) {
                accessibilityName = [cell accessibilityLabel];
            } else {
                NSString *label = [cell accessibilityLabel];
                if (label == nil) {
                    id val = [cell accessibilityValue];
                    if (val != nil) {
                        label = [NSString stringWithFormat:@"%@", val];
                    }
                }
                accessibilityName = [accessibilityName stringByAppendingFormat:@", %@", label];
            }
        }
        return accessibilityName;
}

- (id)accessibilityParent
{
    return [super accessibilityParent];
}

- (NSRect)accessibilityFrame
{
        int height = [[[self accessibilityChildren] objectAtIndex:0] accessibilityFrame].size.height;
        int width = 0;
        NSPoint point = [[[self accessibilityChildren] objectAtIndex:0] accessibilityFrame].origin;
        for (id cell in [self accessibilityChildren]) {
            width += [cell accessibilityFrame].size.width;
        }
        return NSMakeRect(point.x, point.y, width, height);
}

- (BOOL)isLocationOnScreenValid {
    return [[[self accessibilityChildren] objectAtIndex:0] isLocationOnScreenValid];
}

- (BOOL)isAccessibilityOrderedByRow
{
    return YES;
}

@end
