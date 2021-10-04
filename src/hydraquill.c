#include "hydraquill.h"

#include <fcntl.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h> 

// platform-specific includes

#if defined(HYDRAQUILL_PLATFORM_LINUX)

#include <endian.h>
#include <unistd.h>
#define O_BINARY 0

#elif defined(HYDRAQUILL_PLATFORM_MINGW)

#include "endian_mingw.h"
#include <unistd.h>

#elif defined(HYDRAQUILL_PLATFORM_MSVC)

#include "endian_msvc.h"
#include <io.h>       // open, close, read, write, lseek
#include <stdio.h>    // SEEK_SET
#include <basetsd.h>  // SSIZE_T
#include <sys/stat.h> // _S_IREAD, _S_IWRITE

#define ssize_t SSIZE_T
#define S_IRUSR _S_IREAD
#define S_IWUSR _S_IWRITE
#define S_IRGRP 0
#define S_IROTH 0

#elif defined(HYDRAQUILL_PLATFORM_MACOS)

#include "endian_macos.h"
#include <unistd.h>
#define O_BINARY 0

#endif

// default file names

#ifndef HYDRAQUILL_REGISTRY_NAME
#define HYDRAQUILL_REGISTRY_NAME "reg.bin"
#endif

#ifndef HYDRAQUILL_TMP_BLOB_NAME
#define HYDRAQUILL_TMP_BLOB_NAME "blob.bin"
#endif

// maximum file name length

#if defined(NAME_MAX)
#define HYDRAQUILL_NAME_MAX NAME_MAX
#elif defined(_POSIX_PATH_MAX)
#define HYDRAQUILL_NAME_MAX _POSIX_PATH_MAX
#else
#define HYDRAQUILL_NAME_MAX 1024
#endif

// local

struct reg_line
{
	char font_name[HYDRAQUILL_NAME_MAX + 1];
	uint8_t font_hash[32];
	uint32_t font_size;
	struct reg_line* next;
};

static enum hydraquill_error build_path(
	char** out,
	const char* path,
	const char* name)
{
	size_t path_len = strlen(path);
	size_t out_len;

	if ((path_len > 0) && (path[path_len - 1] != '/'))
	{
		out_len = path_len + strlen(name) + 1;
		*out = malloc(out_len + 1);

		if (*out == NULL)
		{
			return HYDRAQUILL_ERROR_ALLOC;
		}

		strcpy(*out, path);
		// overwrite the previous NUL
		(*out)[path_len] = '/';
		strcpy(*out + path_len + 1, name);
	}
	else
	{
		out_len = path_len + strlen(name);
		*out = malloc(out_len + 1);

		if (*out == NULL)
		{
			return HYDRAQUILL_ERROR_ALLOC;
		}

		strcpy(*out, path);
		// overwrite the previous NUL
		strcpy(*out + path_len, name);
	}

	return HYDRAQUILL_ERROR_OK;
}

static enum hydraquill_error get_font_info(
	int reg,
	char* font_name,
	uint8_t* font_hash,
	uint32_t* font_size)
{
	int i;
	char last;
	ssize_t elements;
	uint32_t font_size_host_endianness;

	// save the font name
	i = 0;

	do
	{
		elements = read(reg, font_name + i, 1);

		if (elements < 1)
		{
			return HYDRAQUILL_ERROR_READ;
		}

		last = font_name[i];
		++i;
	}
	while ((last != '\0') && (i < HYDRAQUILL_NAME_MAX));

	// forged registry
	if ((last != '\0') && (i >= HYDRAQUILL_NAME_MAX))
	{
		return HYDRAQUILL_ERROR_FONT_NAME_TOO_LONG;
	}

	// end-of-registry marker
	if (i == 1)
	{
		return HYDRAQUILL_ERROR_END_OF_REGISTRY;
	}

	// skip the font size
	elements = read(reg, &font_size_host_endianness, 4);

	if (elements < 1)
	{
		return HYDRAQUILL_ERROR_READ;
	}

	*font_size = be32toh(font_size_host_endianness);

	// save the font hash
	elements = read(reg, font_hash, 32);

	if (elements < 1)
	{
		return HYDRAQUILL_ERROR_READ;
	}

	return HYDRAQUILL_ERROR_OK;
}

static void reg_list_free(struct reg_line* reg)
{
	struct reg_line* next;

	while (reg != NULL)
	{
		next = reg->next;
		free(reg);
		reg = next;
	}
}

static enum hydraquill_error hydraquill_unpack(
	char* tmp_path,
	const char* font_dir,
	int output_file)
{
	enum hydraquill_error err;

	// rewind tmp blob
	off_t offset = lseek(output_file, 0, SEEK_SET);

	if (offset != 0)
	{
		close(output_file);
		free(tmp_path);
		return HYDRAQUILL_ERROR_REWIND_TMP_FILE;
	}

	// save reg info
	struct reg_line* reg_beg = NULL;
	struct reg_line** reg_end = &reg_beg; // infer false positive
	struct reg_line** reg = &reg_beg;

	do
	{
		*reg = malloc(sizeof (struct reg_line));

		if (*reg == NULL)
		{
			close(output_file);
			free(tmp_path);
			reg_list_free(reg_beg);
			return HYDRAQUILL_ERROR_ALLOC;
		}

		err = get_font_info(
			output_file,
			(*reg)->font_name,
			(*reg)->font_hash,
			&((*reg)->font_size));

		reg_end = reg;
		reg = &((*reg)->next);
	}
	while (err == HYDRAQUILL_ERROR_OK);

	// post-loop cleanup
	free(*reg_end);
	*reg_end = NULL;

	if (err != HYDRAQUILL_ERROR_END_OF_REGISTRY)
	{
		close(output_file);
		free(tmp_path);
		reg_list_free(reg_beg);
		return err;
	}

	// build the registry path
	char* reg_path;

	err = build_path(&reg_path, font_dir, HYDRAQUILL_REGISTRY_NAME);

	if (err != HYDRAQUILL_ERROR_OK)
	{
		close(output_file);
		free(tmp_path);
		reg_list_free(reg_beg);
		return err;
	}

	// open the registry file
	int reg_file = open(
		reg_path,
		O_WRONLY | O_CREAT | O_BINARY,
		S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);

	if (reg_file < 0)
	{
		close(output_file);
		free(reg_path);
		free(tmp_path);
		reg_list_free(reg_beg);
		return HYDRAQUILL_ERROR_OPEN;
	}

	// split (no need to rewind the output blob after reading the registry)
	// re-write a separate registry (using the information in our list)
	int font_file;
	char* font_path;
	uint32_t font_size_be;
	struct reg_line* reg_tmp;

	int font_buf[1024];
	ssize_t expected;
	ssize_t size;

	size_t max;
	size_t i;

	while (reg_beg != NULL)
	{
		size = write(
			reg_file,
			reg_beg->font_name,
			strlen(reg_beg->font_name) + 1);

		expected = strlen(reg_beg->font_name) + 1;

		if (size < expected)
		{
			close(output_file);
			close(reg_file);
			free(reg_path);
			free(tmp_path);
			reg_list_free(reg_beg);
			return HYDRAQUILL_ERROR_WRITE;
		}

		font_size_be = htobe32(reg_beg->font_size);
		size = write(reg_file, &font_size_be, 4);

		if (size < 1)
		{
			close(output_file);
			close(reg_file);
			free(reg_path);
			free(tmp_path);
			reg_list_free(reg_beg);
			return HYDRAQUILL_ERROR_WRITE;
		}

		size = write(reg_file, reg_beg->font_hash, 32);

		if (size < 32)
		{
			close(output_file);
			close(reg_file);
			free(reg_path);
			free(tmp_path);
			reg_list_free(reg_beg);
			return HYDRAQUILL_ERROR_WRITE;
		}

		// build font path
		max = reg_beg->font_size / ((sizeof (int)) * 1024);
		err = build_path(&font_path, font_dir, reg_beg->font_name);

		if (err != HYDRAQUILL_ERROR_OK)
		{
			close(output_file);
			close(reg_file);
			free(reg_path);
			free(tmp_path);
			reg_list_free(reg_beg);
			return err;
		}

		// open the font
		font_file = open(
			font_path,
			O_WRONLY | O_CREAT | O_BINARY,
			S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);

		if (reg_file < 0)
		{
			close(output_file);
			free(font_path);
			close(reg_file);
			free(reg_path);
			free(tmp_path);
			reg_list_free(reg_beg);
			return HYDRAQUILL_ERROR_OPEN;
		}

		// write the font
		i = 0;
		expected = (sizeof (int)) * 1024;

		while (i < max)
		{
			size = read(output_file, font_buf, (sizeof (int)) * 1024);

			if (size < expected)
			{
				close(output_file);
				close(font_file);
				free(font_path);
				close(reg_file);
				free(reg_path);
				free(tmp_path);
				reg_list_free(reg_beg);
				return HYDRAQUILL_ERROR_READ;
			}

			size = write(font_file, font_buf, (sizeof (int)) * 1024);

			if (size < expected)
			{
				close(output_file);
				close(font_file);
				free(font_path);
				close(reg_file);
				free(reg_path);
				free(tmp_path);
				reg_list_free(reg_beg);
				return HYDRAQUILL_ERROR_WRITE;
			}

			++i;
		}

		ssize_t remnant = reg_beg->font_size % ((sizeof (int)) * 1024);

		if (remnant != 0)
		{
			size = read(output_file, font_buf, remnant);

			if (size < remnant)
			{
				close(output_file);
				close(font_file);
				free(font_path);
				close(reg_file);
				free(reg_path);
				free(tmp_path);
				reg_list_free(reg_beg);
				return HYDRAQUILL_ERROR_READ;
			}

			size = write(font_file, font_buf, remnant);

			if (size < remnant)
			{
				close(output_file);
				close(font_file);
				free(font_path);
				close(reg_file);
				free(reg_path);
				free(tmp_path);
				reg_list_free(reg_beg);
				return HYDRAQUILL_ERROR_WRITE;
			}
		}

		reg_tmp = reg_beg;
		reg_beg = reg_beg->next;
		free(reg_tmp);

		close(font_file);
		free(font_path);
	}

	font_size_be = 0;
	size = write(reg_file, &font_size_be, 1);

	close(output_file);
	close(reg_file);
	free(reg_path);
	reg_list_free(reg_beg);

	if (size != 1)
	{
		free(tmp_path);
		return HYDRAQUILL_ERROR_WRITE;
	}

	int err_unlink = unlink(tmp_path);

	free(tmp_path);

	if (err_unlink != 0)
	{
		return HYDRAQUILL_ERROR_UNLINK;
	}

	return HYDRAQUILL_ERROR_OK;
}

// exported

void hydraquill_init_errors(char** msg)
{
	msg[HYDRAQUILL_ERROR_OK] =
		"no error";
	msg[HYDRAQUILL_ERROR_ALLOC] =
		"failed memory allocation";
	msg[HYDRAQUILL_ERROR_OPEN] =
		"could not open file";
	msg[HYDRAQUILL_ERROR_READ] =
		"could not read file";
	msg[HYDRAQUILL_ERROR_WRITE] =
		"could not write file";
	msg[HYDRAQUILL_ERROR_FONT_NAME_TOO_LONG] =
		"font name too long for the current operating system";
	msg[HYDRAQUILL_ERROR_REWIND_TMP_FILE] =
		"could not rewind the temporary file";
	msg[HYDRAQUILL_ERROR_END_OF_REGISTRY] =
		"reached the end of the registry";
	msg[HYDRAQUILL_ERROR_UNLINK] =
		"could not unlink the temporary file";
	msg[HYDRAQUILL_ERROR_SHA256] =
		"could not hash the font file";
}

enum hydraquill_error hydraquill_unpack_file(
	enum hydraquill_error (*zstd_decode)(
		int output_file,
		int input_file),
	const char* font_dir,
	int input_file)
{
	enum hydraquill_error err;
	char* tmp_path;

	// build tmp blob path
	err = build_path(&tmp_path, font_dir, HYDRAQUILL_TMP_BLOB_NAME);

	if (err != HYDRAQUILL_ERROR_OK)
	{
		return err;
	}

	// open the tmp file
	int output_file = open(
		tmp_path,
		O_RDWR | O_CREAT | O_BINARY,
		S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);

	if (output_file < 0)
	{
		free(tmp_path);
		return HYDRAQUILL_ERROR_OPEN;
	}

	// decode
	err = zstd_decode(output_file, input_file);

	if (err != HYDRAQUILL_ERROR_OK)
	{
		close(output_file);
		free(tmp_path);
		return err;
	}

	return hydraquill_unpack(tmp_path, font_dir, output_file); // infer false positive
}

enum hydraquill_error hydraquill_process_fonts(
	enum hydraquill_error (*font_callback)(
		void* context,
		int font_file,
		char* font_name,
		uint8_t* font_hash,
		uint32_t font_size),
	const char* font_dir,
	void* context)
{
	enum hydraquill_error err;

	// build the registry path
	char* reg_path;

	err = build_path(&reg_path, font_dir, HYDRAQUILL_REGISTRY_NAME);

	if (err != HYDRAQUILL_ERROR_OK)
	{
		return err;
	}

	// open the registry file
	int reg_file = open(reg_path, O_RDONLY | O_BINARY);

	if (reg_file < 0)
	{
		free(reg_path);
		return HYDRAQUILL_ERROR_OPEN;
	}

	// check all the fonts
	char font_name[HYDRAQUILL_NAME_MAX + 1] = {0};
	uint8_t font_hash[32] = {0};
	uint32_t font_size = 0;

	int font_file;
	char* font_path;
	enum hydraquill_error init_valid;

	do
	{
		// get info
		err = get_font_info(reg_file, font_name, font_hash, &font_size);

		if (err != HYDRAQUILL_ERROR_OK)
		{
			close(reg_file);
			free(reg_path);

			if (err == HYDRAQUILL_ERROR_END_OF_REGISTRY)
			{
				return HYDRAQUILL_ERROR_OK;
			}

			return err;
		}

		// build font path
		err = build_path(&font_path, font_dir, font_name);

		if (err != HYDRAQUILL_ERROR_OK)
		{
			close(reg_file);
			free(reg_path);
			return err;
		}

		// open the font
		font_file = open(font_path, O_RDONLY | O_BINARY);

		if (font_file < 0)
		{
			close(reg_file);
			free(font_path);
			free(reg_path);
			return HYDRAQUILL_ERROR_OPEN;
		}

		// check the hash
		init_valid =
			font_callback(
				context,
				font_file,
				font_name,
				font_hash,
				font_size);

		close(font_file);
		free(font_path);
	}
	while (init_valid == HYDRAQUILL_ERROR_OK);

	close(reg_file);
	free(reg_path);
	return init_valid;
}
