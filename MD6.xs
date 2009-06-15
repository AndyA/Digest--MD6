/* 
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 * 
 *  Copyright 1998-2000 Gisle Aas.
 *  Copyright 1995-1996 Neil Winton.
 *  Copyright 1991-1992 RSA Data Security, Inc.
 *
 * This code is derived from Neil Winton's MD6-1.7 Perl module, which in
 * turn is derived from the reference implementation in RFC 1321 which
 * comes with this message:
 *
 * Copyright (C) 1991-2, RSA Data Security, Inc. Created 1991. All
 * rights reserved.
 *
 * License to copy and use this software is granted provided that it
 * is identified as the "RSA Data Security, Inc. MD6 Message-Digest
 * Algorithm" in all material mentioning or referencing this software
 * or this function.
 *
 * License is also granted to make and use derivative works provided
 * that such works are identified as "derived from the RSA Data
 * Security, Inc. MD6 Message-Digest Algorithm" in all material
 * mentioning or referencing the derived work.
 *
 * RSA Data Security, Inc. makes no representations concerning either
 * the merchantability of this software or the suitability of this
 * software for any particular purpose. It is provided "as is"
 * without express or implied warranty of any kind.
 *
 * These notices must be retained in any copies of any part of this
 * documentation and/or software.
 */

#ifdef __cplusplus
extern "C" {
#endif
#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif
#include "src/md6.h"
#ifdef G_WARN_ON
#define DOWARN (PL_dowarn & G_WARN_ON)
#else
#define DOWARN PL_dowarn
#endif
#ifndef dTHX
#define pTHX_
#define aTHX_
#endif
#ifndef INT2PTR
#define INT2PTR(any,d)	(any)(d)
#endif
static void
MD6Init( md6_state * ctx ) {
  md6_init( ctx, 256 );
}

static void
MD6Update( md6_state * ctx, const U8 * buf, STRLEN len ) {
  md6_update( ctx, buf, len * 8 );
}

static void
MD6Final( U8 * digest, md6_state * ctx ) {
  md6_final( ctx, digest );
}

static md6_state *
get_md6_ctx( pTHX_ SV * sv ) {
  if ( SvROK( sv ) ) {
    sv = SvRV( sv );
    if ( SvIOK( sv ) ) {
      md6_state *ctx = INT2PTR( md6_state *, SvIV( sv ) );
      /* check signature */
      if ( ctx ) {
        return ctx;
      }
    }
  }
  croak( "Not a reference to a Digest::MD6 object" );
  return ( md6_state * ) 0;     /* some compilers insist on a return value */
}

static char *
hex_16( const unsigned char *from, char *to ) {
  static const char hexdigits[] = "0123456789abcdef";
  const unsigned char *end = from + 16;
  char *d = to;

  while ( from < end ) {
    *d++ = hexdigits[( *from >> 4 )];
    *d++ = hexdigits[( *from & 0x0F )];
    from++;
  }
  *d = '\0';
  return to;
}

static char *
base64_16( const unsigned char *from, char *to ) {
  static const char base64[] =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  const unsigned char *end = from + 16;
  unsigned char c1, c2, c3;
  char *d = to;

  while ( 1 ) {
    c1 = *from++;
    *d++ = base64[c1 >> 2];
    if ( from == end ) {
      *d++ = base64[( c1 & 0x3 ) << 4];
      break;
    }
    c2 = *from++;
    c3 = *from++;
    *d++ = base64[( ( c1 & 0x3 ) << 4 ) | ( ( c2 & 0xF0 ) >> 4 )];
    *d++ = base64[( ( c2 & 0xF ) << 2 ) | ( ( c3 & 0xC0 ) >> 6 )];
    *d++ = base64[c3 & 0x3F];
  }
  *d = '\0';
  return to;
}

/* Formats */
#define F_BIN 0
#define F_HEX 1
#define F_B64 2

static SV *
make_mortal_sv( pTHX_ const unsigned char *src, int type ) {
  STRLEN len;
  char result[33];
  char *ret;

  switch ( type ) {
  case F_BIN:
    ret = ( char * ) src;
    len = 16;
    break;
  case F_HEX:
    ret = hex_16( src, result );
    len = 32;
    break;
  case F_B64:
    ret = base64_16( src, result );
    len = 22;
    break;
  default:
    croak( "Bad convertion type (%d)", type );
    break;
  }
  return sv_2mortal( newSVpv( ret, len ) );
}

/********************************************************************/

/* *INDENT-OFF* */

typedef PerlIO* InputStream;

MODULE = Digest::MD6		PACKAGE = Digest::MD6

PROTOTYPES: DISABLE

void
new(xclass)
	SV* xclass
  PREINIT:
    md6_state* context;
  PPCODE:
    if (!SvROK(xclass)) {
      STRLEN my_na;
      char *sclass = SvPV(xclass, my_na);
      New(55, context, 1, md6_state);
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), sclass, (void*)context);
      SvREADONLY_on(SvRV(ST(0)));
    } else {
      context = get_md6_ctx(aTHX_ xclass);
    }
    MD6Init(context);
    XSRETURN(1);

void
clone(self)
	SV* self
  PREINIT:
    md6_state* cont = get_md6_ctx(aTHX_ self);
    const char *myname = sv_reftype(SvRV(self),TRUE);
    md6_state* context;
  PPCODE:
    New(55, context, 1, md6_state);
    ST(0) = sv_newmortal();
    sv_setref_pv(ST(0), myname , (void*)context);
    SvREADONLY_on(SvRV(ST(0)));
    memcpy(context,cont,sizeof(md6_state));
    XSRETURN(1);

void
DESTROY(context)
	md6_state* context
  CODE:
    Safefree(context);

void
add(self, ...)
	SV* self
  PREINIT:
    md6_state* context = get_md6_ctx(aTHX_ self);
    int i;
    unsigned char *data;
    STRLEN len;
  PPCODE:
    for (i = 1; i < items; i++) {
      data = (unsigned char *)(SvPV(ST(i), len));
      MD6Update(context, data, len);
    }
    XSRETURN(1);  /* self */

void
addfile(self, fh)
	SV* self
	InputStream fh
  PREINIT:
    md6_state* context = get_md6_ctx(aTHX_ self);
    /* TODO is the correct? */
    STRLEN fill = context->bits_processed / 8;
#ifdef USE_HEAP_INSTEAD_OF_STACK
    unsigned char* buffer;
#else
    unsigned char buffer[4096];
#endif
    int  n;
  CODE:
    if (fh) {
#ifdef USE_HEAP_INSTEAD_OF_STACK
      New(0, buffer, 4096, unsigned char);
      assert(buffer);
#endif
      if (fill) {
        /* The MD6Update() function is faster if it can work with
          * complete blocks.  This will fill up any buffered block
          * first.
          */
        STRLEN missing = 64 - fill;
        if ( (n = PerlIO_read(fh, buffer, missing)) > 0)
          MD6Update(context, buffer, n);
        else
          XSRETURN(1);  /* self */
      }

      /* Process blocks until EOF or error */
      while ( (n = PerlIO_read(fh, buffer, sizeof(buffer))) > 0) {
        MD6Update(context, buffer, n);
      }
#ifdef USE_HEAP_INSTEAD_OF_STACK
      Safefree(buffer);
#endif
      if (PerlIO_error(fh)) {
        croak("Reading from filehandle failed");
      }
    }
    else {
        croak("No filehandle passed");
    }
    XSRETURN(1);  /* self */

void
digest(context)
	md6_state* context
  ALIAS:
    Digest::MD6::digest    = F_BIN
    Digest::MD6::hexdigest = F_HEX
    Digest::MD6::b64digest = F_B64
  PREINIT:
    unsigned char digeststr[16];
  PPCODE:
    MD6Final(digeststr, context);
    MD6Init(context);  /* In case it is reused */
    ST(0) = make_mortal_sv(aTHX_ digeststr, ix);
    XSRETURN(1);

void
md6(...)
  ALIAS:
    Digest::MD6::md6        = F_BIN
    Digest::MD6::md6_hex    = F_HEX
    Digest::MD6::md6_base64 = F_B64
  PREINIT:
    md6_state ctx;
    int i;
    unsigned char *data;
    STRLEN len;
    unsigned char digeststr[16];
  PPCODE:
    MD6Init(&ctx);

    if (DOWARN) {
      char *msg = 0;
      if (items == 1) {
        if (SvROK(ST(0))) {
          SV* sv = SvRV(ST(0));
          if (SvOBJECT(sv) && strEQ(HvNAME(SvSTASH(sv)), "Digest::MD6"))
            msg = "probably called as method";
          else
            msg = "called with reference argument";
        }
      }
      else if (items > 1) {
        data = (unsigned char *)SvPV(ST(0), len);
        if (len == 11 && memEQ("Digest::MD6", data, 11)) {
          msg = "probably called as class method";
        }
        else if (SvROK(ST(0))) {
          SV* sv = SvRV(ST(0));
          if (SvOBJECT(sv) && strEQ(HvNAME(SvSTASH(sv)), "Digest::MD6"))
            msg = "probably called as method";
        }
      }
      if (msg) {
        const char *f = (ix == F_BIN) ? "md6" :
                  (ix == F_HEX) ? "md6_hex" : "md6_base64";
        warn("&Digest::MD6::%s function %s", f, msg);
      }
    }

    for (i = 0; i < items; i++) {
      data = (unsigned char *)(SvPV(ST(i), len));
      MD6Update(&ctx, data, len);
    }
    MD6Final(digeststr, &ctx);
    ST(0) = make_mortal_sv(aTHX_ digeststr, ix);
    XSRETURN(1);

