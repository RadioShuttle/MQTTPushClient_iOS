/*
 * This is an unpublished work copyright (c) 2011 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "NSString+HELUtils.h"

@implementation NSString (HELUtils)

static const char hexdigits[] = "0123456789abcdef";

/*
 * Convert <srclen> bytes at <src> to a hex string.
 * The hex string is allocated and zero-terminated.
 * Returns the hex string.
 */
static char *encodeHex(const char *src, int srclen)
{
	char *dst, *d;
	int i;
	unsigned char c;
	
	dst = d = malloc(2*srclen + 1);
	for (i = 0; i < srclen; i++) {
		c = *src++;
		*d++ = hexdigits[c >> 4];
		*d++ = hexdigits[c & 0x0F];
	}
	*d = 0;
	return dst;
}

// Utility function for decodeHex().
static int tobin(int c)
{
	if (islower(c))
		c = toupper(c);
	if (isxdigit(c))
		return c >= 'A' ? c - 'A' + 0xa : c - '0';
	else
		return -1;
}

/*
 * Decode the hex string at <src> which must be zero-terminated.
 * If <src> contains characters that cannot be interpreted as hexadecimal
 * bytes, the conversion stops at that point.
 * The result is written to a allocated and zero-terminated buffer.
 * The number of bytes written to the result buffer is stored into <dstlen>.
 * Returns the decoded buffer.
 */
static char *decodeHex(const char *src, int *dstlen)
{
	char *dst, *d;
	int i, srclen;
	int c1, c2;
	
	srclen = (int)strlen(src);
	dst = d = malloc(srclen/2 + 1);
	for (i = 0; i < srclen/2; i++) {
		if ((c1 = tobin(*src++)) == -1)
			break;
		if ((c2 = tobin(*src++)) == -1)
			break;
		*d++ = (c1 << 4) + c2;
	}
	*d = 0;
	if (dstlen != NULL)
		*dstlen = (int)(d - dst);
	return dst;
}


- (NSString *)toHex
{
	const char *s = self.UTF8String;
	int len = (int)strlen(s);
	char *d = encodeHex(s, len);
	NSString *r = @(d);
	free(d);
	return r;
}

+ (NSString *)hexFromData:(NSData *)sdata
{
	const char *s = sdata.bytes;
	int len = (int)sdata.length;
	char *d = encodeHex(s, len);
	NSString *r = @(d);
	free(d);
	return r;
}

- (NSString *)fromHex
{
	const char *s = self.UTF8String;
	char *d = decodeHex(s, NULL);
	NSString *r = @(d);
	free(d);
	return r;
}

- (NSData *)dataFromHex
{
	const char *s = self.UTF8String;
	int dlen;
	char *d = decodeHex(s, &dlen);
	NSData *r = [NSData dataWithBytes:d length:dlen];
	free(d);
	return r;
}

- (NSString *)dequoteHelios
{
	const char *s = self.UTF8String;
	char *dst, *d;
	int c, c1, c2;

	if (strchr(s, '^') == NULL)
		return self;
	dst = d = malloc(strlen(s) + 1);
	while ((c = *s++) != 0) {
		if (c == '^' && (c1 = tobin(s[0])) != -1 && (c2 = tobin(s[1])) != -1) {
			s += 2;
			c = (c1 << 4) + c2;
		}
		*d++ = c;
	}
	*d = 0;
	NSString *r = @(dst);
	free(dst);
	return r;
}

- (NSString *)enquoteHelios
{
	static const char *specialChars = "/\\^*?<>|:\"";
	const char *s = self.UTF8String;
	char *dst, *d;
	unsigned char c;
	
	if (strpbrk(s, specialChars) == NULL)
		return self;
	dst = d = malloc(3*strlen(s) + 1);
	while ((c = *s++) != 0) {
		if (strchr(specialChars, c) == NULL) {
			*d++ = c;
		} else {
			*d++ = '^';
			*d++ = hexdigits[c >> 4];
			*d++ = hexdigits[c & 0xf];
		}
	}
	*d = 0;
	NSString *r = @(dst);
	free(dst);
	return r;
}

/*
 * Replace the characters & < > ' "
 * by their corresponding entities.
 */
- (NSString *)xmlEscape
{
	NSString *escaped = [[[[[self stringByReplacingOccurrencesOfString: @"&" withString: @"&amp;"]
				stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"]
			       stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"]
			      stringByReplacingOccurrencesOfString:@"'" withString:@"&apos;"]
			     stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
	return escaped;
}

/*
 * Replace all invalid URL characters by their corresponding percent escape.
 *
 * The NSString method stringByAddingPercentEscapesUsingEncoding does not escape
 * all invalid characters, the following is a workaround.
 */
-(NSString *)urlEscape
{
	static dispatch_once_t onceToken;
	static NSMutableCharacterSet *charset;
	dispatch_once(&onceToken, ^{
		charset = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
		[charset removeCharactersInString:@"!$&'()*+,/:;=?@"];
	});
	return  [self stringByAddingPercentEncodingWithAllowedCharacters:charset];
}

- (NSString *)helNormalizePath
{
	/*
	 * Normalize path by removing
	 * - leading and trailing and repeated path separators,
	 * - all "." path componentes.
	 *
	 *	"a//b", "/a/b", "a/b/", "a/./b"
	 *
	 * will all result in the same path "a/b".
	 *
	 * We cannot use stringByStandardizingPath, because that expands also
	 * a leading tilde (~) to the user's home directory.
	 */
	NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(NSString *comp, NSDictionary *bindings) {
		return ![comp isEqualToString:@"."] && ![comp isEqualToString:@"/"];
	}];
	NSArray *tmp = [self.pathComponents filteredArrayUsingPredicate:pred];
	if (tmp.count == 0)
		return nil;	// Invalid path
	return [NSString pathWithComponents:tmp];
}

@end
