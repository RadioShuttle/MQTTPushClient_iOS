/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#ifndef Trace_h
#define Trace_h

#ifdef DEBUG
# define TRACE(format, ...)	NSLog(format, ## __VA_ARGS__)
#else
# define TRACE(format, ...)	do {} while (0)
#endif


#endif /* Trace_h */
