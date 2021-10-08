#ifndef H_HYDRAQUILL
#define H_HYDRAQUILL

#include <stdint.h>
#include <stddef.h>

enum hydraquill_error
{
	HYDRAQUILL_ERROR_OK = 0,

	HYDRAQUILL_ERROR_ALLOC,
	HYDRAQUILL_ERROR_OPEN,
	HYDRAQUILL_ERROR_READ,
	HYDRAQUILL_ERROR_WRITE,
	HYDRAQUILL_ERROR_FONT_NAME_TOO_LONG,
	HYDRAQUILL_ERROR_REWIND_TMP_FILE,
	HYDRAQUILL_ERROR_END_OF_REGISTRY,
	HYDRAQUILL_ERROR_UNLINK,

	HYDRAQUILL_ERROR_SHA256,

	HYDRAQUILL_ERROR_SIZE,
};

void hydraquill_init_errors(char** msg);

enum hydraquill_error hydraquill_unpack_file(
	enum hydraquill_error (*zstd_decode)(
		int output_file,
		int input_file),
	const char* font_dir,
	const char* blob_path);

enum hydraquill_error hydraquill_process_fonts(
	enum hydraquill_error (*font_callback)(
		void* context,
		int font_file,
		char* font_name,
		uint8_t* font_hash,
		uint32_t font_size),
	const char* font_dir,
	void* context);

#endif
