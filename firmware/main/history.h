/* eziach - electrical accordion
 *
 * Copyright (C) 2026  Benno Heigl
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, see
 * <https://www.gnu.org/licenses/>.
 */

// What happened, for bring-up without a computer attached: every ESP-IDF log line also
// goes into a 4 KB ring in RAM that a restart does not clear (only power does), shown by
// the console's `history`; at start the reason of the last reset is logged. A crash leaves
// a core dump in its flash partition (`coredump`), summed up by `crash`.

#ifndef HISTORY_H
#define HISTORY_H

// first thing in app_main: the ring, the log hook, the last reset's reason, a stored crash
void history_init(void);

// the ring's lines, oldest first, to stdout
void history_print(void);

// the stored crash: task, address, reason and backtrace (or that there is none); erase it
void history_crash_print(void);
void history_crash_erase(void);

#endif
