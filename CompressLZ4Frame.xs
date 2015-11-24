#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "lz4frame.h"

MODULE = Compress::LZ4Frame PACKAGE = Compress::LZ4Frame
PROTOTYPES: ENABLE

SV *
compress(sv, level = 0)
    SV * sv
    int level
    ALIAS:
        compress_checksum = 1
    PREINIT:
        LZ4F_preferences_t prefs = { 0 };
        char * src, * dest;
        size_t src_len, dest_len;
    CODE:
        SvGETMAGIC(sv);
        if (SvROK(sv) && !SvAMAGIC(sv)) {
            sv = SvRV(sv);
            SvGETMAGIC(sv);
        }
        if (!SvOK(sv))
            XSRETURN_NO;

        src = SvPVbyte(sv, src_len);
        
        prefs.frameInfo.contentChecksumFlag = (ix == 1 ? LZ4F_contentChecksumEnabled : LZ4F_noContentChecksum);
        prefs.frameInfo.contentSize = (unsigned long long)src_len;
        prefs.compressionLevel = level;
        prefs.autoFlush = 1u;

        dest_len = LZ4F_compressFrameBound(src_len, &prefs);
        RETVAL = newSV(dest_len);
        dest = SvPVX(RETVAL);
        if (!dest)
        {
            warn("Could not allocate enough memory (%zu Bytes)", dest_len);
            XSRETURN_UNDEF;
        }

        dest_len = LZ4F_compressFrame(dest, dest_len, src, src_len, &prefs);
        if (LZ4F_isError(dest_len))
        {
            warn("Error during compression: %s", LZ4F_getErrorName(dest_len));
            SvREFCNT_dec(RETVAL);
            XSRETURN_UNDEF;
        }

        SvCUR_set(RETVAL, dest_len);
        SvPOK_on(RETVAL);
    OUTPUT:
        RETVAL

