#include "hydraquill.h"
#include "handy.h"
#include "sha2.h"
#include "zstd.h"

#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h> 
#include <unistd.h>

#ifndef O_BINARY
#define O_BINARY 0
#endif

extern unsigned char noto_beg;
extern unsigned char noto_end;
extern unsigned char noto_len;

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

enum hydraquill_error sha256(uint8_t* checksum, int font_file)
{
	int err;
	uint8_t buf[64];
	uint8_t hash[32] = {0};
	cf_sha256_context ctx = {0};

	// hash
	cf_sha256_init(&ctx);

	do
	{
		err = read(font_file, buf, 64);

		cf_sha256_update(&ctx, buf, err);
	}
	while (err == 64);

	cf_sha256_digest_final(&ctx, hash);

	// check
	err = memcmp(hash, checksum, 32);

	if (err != 0)
	{
		return HYDRAQUILL_ERROR_SHA256;
	}

	return HYDRAQUILL_ERROR_OK;
}

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

enum hydraquill_error zstd_decode_buffer(
	int output_file,
	void* input_buffer,
	size_t size_buffer)
{
	uint8_t* blob = input_buffer;
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
		return HYDRAQUILL_ERROR_ALLOC;
	}

	size_t read_size;
	size_t write_size;
	size_t buf_cur = 0;
	ZSTD_inBuffer in = {0};
	ZSTD_outBuffer out = {0};

	do
	{
		read_size = size_buffer - buf_cur;

		if (read_size > in_buf_size)
		{
			read_size = in_buf_size;
		}

		memcpy(in_buf, blob + buf_cur, read_size);
		buf_cur += read_size;

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

int main(void)
{
	enum hydraquill_error err;
	char* error_msg[HYDRAQUILL_ERROR_SIZE];

	hydraquill_init_errors(error_msg);

	// unpack the file blob
	int input_file = open("./noto.bin.zst", O_RDONLY | O_BINARY);

	if (input_file < 0)
	{
		printf("could not open the zst archive file\n");
		return 1;
	}

	err =
		hydraquill_unpack_file(
			zstd_decode_file,
			"./test/",
			input_file);

	close(input_file);

	if (err != HYDRAQUILL_ERROR_OK)
	{
		printf("%s\n", error_msg[err]);
		return 1;
	}

	// check the unpacked font files
	err = hydraquill_check_fonts(
		sha256,
		"./test/");

	if (err != HYDRAQUILL_ERROR_OK)
	{
		printf("%s\n", error_msg[err]);
		return 1;
	}

	// unpack the embedded blob
	err =
		hydraquill_unpack_buffer(
			zstd_decode_buffer,
			"./test/",
			&noto_beg,
			(size_t) &noto_len);

	if (err != HYDRAQUILL_ERROR_OK)
	{
		printf("%s\n", error_msg[err]);
		return 1;
	}

	// check the unpacked font files
	err = hydraquill_check_fonts(
		sha256,
		"./test/");

	if (err != HYDRAQUILL_ERROR_OK)
	{
		printf("%s\n", error_msg[err]);
		return 1;
	}

	return 0;
}
