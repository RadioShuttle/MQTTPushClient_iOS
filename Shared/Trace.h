/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#ifndef Trace_h
#define Trace_h

#ifdef DEBUG
# define TRACE(format, ...)	NSLog(format, ## __VA_ARGS__)
#else
# define TRACE(format, ...)	do {} while (0)
#endif


#endif /* Trace_h */
