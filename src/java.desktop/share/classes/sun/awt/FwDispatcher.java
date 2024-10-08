/*
 * Copyright (c) 2013, Oracle and/or its affiliates. All rights reserved.
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

package sun.awt;

import java.awt.*;

/**
 * An interface for the EventQueue delegate.
 * This class is added to support JavaFX/AWT interop single threaded mode
 * The delegate should be set in EventQueue by {@link EventQueue#setFwDispatcher(FwDispatcher)}
 * If the delegate is not null, than it handles supported methods instead of the
 * event queue. If it is null than the behaviour of an event queue does not change.
 * <p>
 * This class is also used to implement AWT event dispatching on native 'main' thread.
 *
 * @see EventQueue
 *
 * @author Petr Pchelko
 *
 * @since 1.8
 */
public interface FwDispatcher {
    /**
     * Delegates the {@link EventQueue#isDispatchThread()} method
     */
    boolean isDispatchThread();

    /**
     * Forwards a runnable to the delegate, which executes it on an appropriate thread.
     * @param r a runnable calling {@link EventQueue#dispatchEventImpl(java.awt.AWTEvent, Object)}
     */
    void scheduleDispatch(Runnable r);

    /**
     * Delegates the {@link java.awt.EventQueue#createSecondaryLoop()} method
     */
    SecondaryLoop createSecondaryLoop();

    default boolean startDefaultDispatchThread() {
        return true;
    }

    default void scheduleNativeEvent(EventQueue eventQueue) {}

    default void waitForNativeEvent() {}
}
