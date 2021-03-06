/*
 * Copyright (c) 2011, 2016, Oracle and/or its affiliates. All rights reserved.
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

#import "JavaAccessibilityAction.h"
#import "JavaAccessibilityUtilities.h"

#import "ThreadUtilities.h"

NSMutableDictionary *sActions = nil;
NSMutableDictionary *sActionSelectores = nil;
NSMutableArray *sAllActionSelectores = nil;
void initializeActions();

@implementation JavaAxAction

- (id)initWithEnv:(JNIEnv *)env withAccessibleAction:(jobject)accessibleAction withIndex:(jint)index withComponent:(jobject)component
{
    if (sActions == nil) {
        initializeActions();
    }
    self = [super init];
    if (self) {
        fAccessibleAction = JNFNewWeakGlobalRef(env, accessibleAction);
        fIndex = index;
        fComponent = JNFNewWeakGlobalRef(env, component);
    }
    return self;
}

- (void)dealloc
{
    JNIEnv *env = [ThreadUtilities getJNIEnvUncached];

    JNFDeleteWeakGlobalRef(env, fAccessibleAction);
    fAccessibleAction = NULL;

    JNFDeleteWeakGlobalRef(env, fComponent);
    fComponent = NULL;

    [super dealloc];
}

- (NSString *)getDescription
{
    static JNF_STATIC_MEMBER_CACHE(jm_getAccessibleActionDescription, sjc_CAccessibility, "getAccessibleActionDescription", "(Ljavax/accessibility/AccessibleAction;ILjava/awt/Component;)Ljava/lang/String;");

    JNIEnv* env = [ThreadUtilities getJNIEnv];

    jobject fCompLocal = (*env)->NewLocalRef(env, fComponent);
    if ((*env)->IsSameObject(env, fCompLocal, NULL)) {
        return nil;
    }
    NSString *str = nil;
    jstring jstr = JNFCallStaticObjectMethod( env,
                                              jm_getAccessibleActionDescription,
                                              fAccessibleAction,
                                              fIndex,
                                              fCompLocal );
    if (jstr != NULL) {
        str = JNFJavaToNSString(env, jstr); // AWT_THREADING Safe (AWTRunLoopMode)
        (*env)->DeleteLocalRef(env, jstr);
    }
    (*env)->DeleteLocalRef(env, fCompLocal);
    return str;
}

- (void)perform
{
    static JNF_STATIC_MEMBER_CACHE(jm_doAccessibleAction, sjc_CAccessibility, "doAccessibleAction", "(Ljavax/accessibility/AccessibleAction;ILjava/awt/Component;)V");

    JNIEnv* env = [ThreadUtilities getJNIEnv];

    JNFCallStaticVoidMethod(env, jm_doAccessibleAction, fAccessibleAction, fIndex, fComponent); // AWT_THREADING Safe (AWTRunLoopMode)
}

@end


@implementation TabGroupAction

- (id)initWithEnv:(JNIEnv *)env withTabGroup:(jobject)tabGroup withIndex:(jint)index withComponent:(jobject)component
{
    self = [super init];
    if (self) {
        fTabGroup = JNFNewWeakGlobalRef(env, tabGroup);
        fIndex = index;
        fComponent = JNFNewWeakGlobalRef(env, component);
    }
    return self;
}

- (void)dealloc
{
    JNIEnv *env = [ThreadUtilities getJNIEnvUncached];

    JNFDeleteWeakGlobalRef(env, fTabGroup);
    fTabGroup = NULL;

    JNFDeleteWeakGlobalRef(env, fComponent);
    fComponent = NULL;

    [super dealloc];
}

- (NSString *)getDescription
{
    return @"click";
}

- (void)perform
{
    JNIEnv* env = [ThreadUtilities getJNIEnv];

    setAxContextSelection(env, fTabGroup, fIndex, fComponent);
}

@end

void initializeActions() {
    int actionsCount = 5;

    sActions = [[NSMutableDictionary alloc] initWithCapacity:actionsCount];

    [sActions setObject:NSAccessibilityPressAction forKey:@"click"];
    [sActions setObject:NSAccessibilityIncrementAction forKey:@"increment"];
    [sActions setObject:NSAccessibilityDecrementAction forKey:@"decrement"];
    [sActions setObject:NSAccessibilityShowMenuAction forKey:@"toggle popup"];
    [sActions setObject:NSAccessibilityPressAction forKey:@"toggleexpand"];
    
    sActionSelectores = [[NSMutableDictionary alloc] initWithCapacity:actionsCount];

    [sActionSelectores setObject:NSStringFromSelector(@selector(accessibilityPerformPress)) forKey:NSAccessibilityPressAction];
    [sActionSelectores setObject:NSStringFromSelector(@selector(accessibilityPerformShowMenu)) forKey:NSAccessibilityShowMenuAction];
    [sActionSelectores setObject:NSStringFromSelector(@selector(accessibilityPerformDecrement)) forKey:NSAccessibilityDecrementAction];
    [sActionSelectores setObject:NSStringFromSelector(@selector(accessibilityPerformIncrement)) forKey:NSAccessibilityIncrementAction];
    [sActionSelectores setObject:NSStringFromSelector(@selector(accessibilityPerformPick)) forKey:NSAccessibilityPickAction];

    sAllActionSelectores = [[NSMutableArray alloc] initWithCapacity:actionsCount];

    [sAllActionSelectores addObject:NSStringFromSelector(@selector(accessibilityPerformPick))];
    [sAllActionSelectores addObject:NSStringFromSelector(@selector(accessibilityPerformIncrement))];
    [sAllActionSelectores addObject:NSStringFromSelector(@selector(accessibilityPerformDecrement))];
    [sAllActionSelectores addObject:NSStringFromSelector(@selector(accessibilityPerformShowMenu))];
    [sAllActionSelectores addObject:NSStringFromSelector(@selector(accessibilityPerformPress))];
}
