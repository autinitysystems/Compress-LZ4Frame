#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "lz4frame.h"

SV * decompress_single_frame(pTHX_ char * src, size_t src_len, size_t * bytes_processed)
{
    size_t result, bytes_read, dest_len;
    LZ4F_decompressionContext_t ctx;
    LZ4F_frameInfo_t info;
    SV * decompressed = NULL;
    char * dest = NULL;

    *bytes_processed = 0u;

    result = LZ4F_createDecompressionContext(&ctx, LZ4F_VERSION);
    if (LZ4F_isError(result)) {
        warn("Could not create decompression context: %s", LZ4F_getErrorName(result));
        return NULL;
    }

    bytes_read = src_len;
    result = LZ4F_getFrameInfo(ctx, &info, src, &bytes_read);
    if (LZ4F_isError(result)) {
        warn("Could not read frame info: %s", LZ4F_getErrorName(result));
        LZ4F_freeDecompressionContext(ctx);
        return NULL;
    }
    *bytes_processed += bytes_read;

    dest_len = (size_t)info.contentSize;
    decompressed = newSV(dest_len);
    dest = SvPVX(decompressed);
    if (!dest) {
        warn("Could not allocate enough memory (%zu Bytes)", dest_len);
        LZ4F_freeDecompressionContext(ctx);
        SvREFCNT_dec(decompressed);
        return NULL;
    }

    result = LZ4F_decompress(ctx, dest, &dest_len, src + bytes_read, &src_len, NULL);
    LZ4F_freeDecompressionContext(ctx);
    if (LZ4F_isError(result)) {
        warn("Error during decompression: %s", LZ4F_getErrorName(result));
        SvREFCNT_dec(decompressed);
        return NULL;
    }
    *bytes_processed += src_len;

    SvCUR_set(decompressed, dest_len);
    SvPOK_on(decompressed);

    return decompressed;
}

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
        if (!src_len)
            XSRETURN_NO;

        prefs.frameInfo.contentChecksumFlag = (ix == 1 ? LZ4F_contentChecksumEnabled : LZ4F_noContentChecksum);
        prefs.frameInfo.contentSize = (unsigned long long)src_len;
        prefs.compressionLevel = level;
        prefs.autoFlush = 1u;

        dest_len = LZ4F_compressFrameBound(src_len, &prefs);
        RETVAL = newSV(dest_len);
        dest = SvPVX(RETVAL);
        if (!dest) {
            warn("Could not allocate enough memory (%zu Bytes)", dest_len);
            SvREFCNT_dec(RETVAL);
            XSRETURN_UNDEF;
        }

        dest_len = LZ4F_compressFrame(dest, dest_len, src, src_len, &prefs);
        if (LZ4F_isError(dest_len)) {
            warn("Error during compression: %s", LZ4F_getErrorName(dest_len));
            SvREFCNT_dec(RETVAL);
            XSRETURN_UNDEF;
        }

        SvCUR_set(RETVAL, dest_len);
        SvPOK_on(RETVAL);
    OUTPUT:
        RETVAL

SV *
decompress(sv)
    SV * sv
    PREINIT:
        char * src;
        size_t src_len, bytes_read;
        SV * current = (SV*)1; /* simply not NULL */
    CODE:
        SvGETMAGIC(sv);
        if (SvROK(sv) && !SvAMAGIC(sv)) {
            sv = SvRV(sv);
            SvGETMAGIC(sv);
        }
        if (!SvOK(sv))
            XSRETURN_NO;

        src = SvPVbyte(sv, src_len);
        if (!src_len)
            XSRETURN_NO;

        RETVAL = decompress_single_frame(aTHX_ src, src_len, &bytes_read);
        if (RETVAL == NULL)
            XSRETURN_UNDEF;
        src += bytes_read;
        src_len = src_len >= bytes_read ? src_len - bytes_read : 0u;
        while (src_len && (current = decompress_single_frame(aTHX_ src, src_len, &bytes_read)) && (bytes_read > 0))
        {
            sv_catsv(RETVAL, current);
            SvREFCNT_dec(current);
            src += bytes_read;
            src_len = src_len >= bytes_read ? src_len - bytes_read : 0u;
        }
        if (current == NULL)
        {
            SvREFCNT_dec(RETVAL);
            XSRETURN_UNDEF;
        }

    OUTPUT:
        RETVAL

int
looks_like_lz4frame(sv)
    SV * sv
    PREINIT:
        LZ4F_decompressionContext_t ctx;
        LZ4F_frameInfo_t info;
        char * src;
        size_t src_len;
        size_t result;
    CODE:
        SvGETMAGIC(sv);
        if (SvROK(sv) && !SvAMAGIC(sv)) {
            sv = SvRV(sv);
            SvGETMAGIC(sv);
        }
        if (!SvOK(sv))
            XSRETURN_NO;

        src = SvPVbyte(sv, src_len);
        if (!src_len)
            XSRETURN_NO;

        result = LZ4F_createDecompressionContext(&ctx, LZ4F_VERSION);
        if (LZ4F_isError(result)) {
            warn("Could not create decompression context: %s", LZ4F_getErrorName(result));
            XSRETURN_UNDEF;
        }

        result = LZ4F_getFrameInfo(ctx, &info, src, &src_len);
        if (LZ4F_isError(result)) {
            /*
             * No warning: we actually just wanted to check if this is valid LZ4 Frame data
             * warn("Could not read frame info: %s", LZ4F_getErrorName(result));
             */
            LZ4F_freeDecompressionContext(ctx);
            XSRETURN_NO;
        }

        LZ4F_freeDecompressionContext(ctx);
        XSRETURN_YES;

