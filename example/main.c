#include "hydraquill.h"
#include "handy.h"
#include "sha2.h"
#include "zstd.h"

#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h> 

// platform-specific includes

#if defined(HYDRAQUILL_PLATFORM_LINUX)

#include <unistd.h>
#define O_BINARY 0

#elif defined(HYDRAQUILL_PLATFORM_MINGW)

#include <unistd.h>

#elif defined(HYDRAQUILL_PLATFORM_MSVC)

#include <io.h>       // open, close, read, write, lseek
#include <stdio.h>    // SEEK_SET
#include <basetsd.h>  // SSIZE_T
#include <sys/stat.h> // _S_IREAD, _S_IWRITE

#define ssize_t SSIZE_T
#define S_IRUSR _S_IREAD
#define S_IWUSR _S_IWRITE
#define S_IRGRP 0
#define S_IROTH 0

#ifdef min
#undef min
#endif

#ifdef max
#undef max
#endif

#elif defined(HYDRAQUILL_PLATFORM_MACOS)

#include <unistd.h>
#define O_BINARY 0

#endif

// use safe min and max for the specific type cifra needs

inline size_t min(size_t x, size_t y)
{
	if (x > y)
	{
		return y;
	}

	return x;
}

inline size_t max(size_t x, size_t y)
{
	if (x > y)
	{
		return x;
	}

	return y;
}

// sha256 processing callback
enum hydraquill_error sha256(
	void* context,
	int font_file,
	char* font_name,
	uint8_t* font_hash,
	uint32_t font_size)
{
	int err;
	uint8_t buf[64];
	uint8_t checksum[32] = {0};
	cf_sha256_context ctx = {0};

	// hash
	cf_sha256_init(&ctx);

	do
	{
		err = read(font_file, buf, 64);

		cf_sha256_update(&ctx, buf, err);
	}
	while (err == 64);

	cf_sha256_digest_final(&ctx, checksum);

	// check
	err = memcmp(checksum, font_hash, 32);

	if (err != 0)
	{
		return HYDRAQUILL_ERROR_SHA256;
	}

	return HYDRAQUILL_ERROR_OK;
}

// zstd decoding callback (file)
enum hydraquill_error zstd_decode_file(int output_file, int input_file)
{
	ZSTD_DStream* stream = ZSTD_createDStream();
	ZSTD_initDStream(stream);

	size_t out_buf_size = ZSTD_DStreamOutSize();
	void* out_buf = malloc(out_buf_size);

	if (out_buf == NULL)
	{
		return HYDRAQUILL_ERROR_ALLOC;
	}

	size_t in_buf_size = ZSTD_DStreamInSize();
	void* in_buf = malloc(in_buf_size);

	if (in_buf == NULL)
	{
		free(out_buf);
		return HYDRAQUILL_ERROR_ALLOC;
	}

	size_t read_size;
	size_t write_size;
	ZSTD_inBuffer in = {0};
	ZSTD_outBuffer out = {0};

	do
	{
		read_size = read(input_file, in_buf, in_buf_size);
		in.src = in_buf;
		in.size = read_size;
		in.pos = 0;

		while (in.pos < in.size)
		{
			out.dst = out_buf;
			out.size = out_buf_size;
			out.pos = 0;

			ZSTD_decompressStream(stream, &out, &in);
			write_size = write(output_file, out_buf, out.pos);

			if (write_size < out.pos)
			{
				ZSTD_freeDStream(stream);
				free(out_buf);
				free(in_buf);
				return HYDRAQUILL_ERROR_WRITE;
			}
		}
	}
	while (in.pos > 0);

	ZSTD_freeDStream(stream);
	free(out_buf);
	free(in_buf);

	return HYDRAQUILL_ERROR_OK;
}

// example
int main(void)
{
	enum hydraquill_error err;
	char* error_msg[HYDRAQUILL_ERROR_SIZE];

	hydraquill_init_errors(error_msg);

	// unpack the file blob
	err = hydraquill_unpack_file(
		zstd_decode_file,
		"./test/",
		"./noto.bin.zst");

	if (err != HYDRAQUILL_ERROR_OK)
	{
		printf("%s\n", error_msg[err]);
		return 1;
	}

	// check the unpacked font files
	err = hydraquill_process_fonts(
		sha256,
		"./test/",
		NULL);

	if (err != HYDRAQUILL_ERROR_OK)
	{
		printf("%s\n", error_msg[err]);
		return 1;
	}

	return 0;
}
